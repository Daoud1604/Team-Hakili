import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/motor.dart';
import '../models/telemetry.dart';
import '../repositories/motor_repository.dart';
import '../repositories/telemetry_repository.dart';
import '../repositories/esp32_repository.dart';
import '../repositories/backend_motor_repository.dart';
import '../repositories/backend_telemetry_repository.dart';
import 'config_provider.dart';
import 'auth_provider.dart';
import '../services/alert_service.dart';

class MotorProvider with ChangeNotifier {
  final MotorRepository _motorRepository = MotorRepository();
  final TelemetryRepository _telemetryRepository = TelemetryRepository();
  BackendMotorRepository? _backendMotorRepository;
  BackendTelemetryRepository? _backendTelemetryRepository;

  List<Motor> _motors = [];
  Map<int, Telemetry?> _latestTelemetry = {};
  Timer? _telemetryTimer;
  bool _isPolling = false;
  bool _isConnected = true;
  String? _connectionError;

  List<Motor> get motors => _motors;
  Map<int, Telemetry?> get latestTelemetry => _latestTelemetry;
  bool get isConnected => _isConnected;
  String? get connectionError => _connectionError;

  MotorProvider() {
    loadMotors();
  }

  void _initializeBackendRepositories(
      ConfigProvider configProvider, AuthProvider authProvider) {
    if (configProvider.operationMode == 'server' &&
        authProvider.token != null) {
      _backendMotorRepository = BackendMotorRepository(
        baseUrl: configProvider.backendBaseUrl,
        authToken: authProvider.token,
        allowSelfSignedCert: configProvider.allowSelfSignedCert,
      );
      _backendTelemetryRepository = BackendTelemetryRepository(
        baseUrl: configProvider.backendBaseUrl,
        authToken: authProvider.token,
        allowSelfSignedCert: configProvider.allowSelfSignedCert,
      );
    }
  }

  Future<void> loadMotors(
      {ConfigProvider? configProvider, AuthProvider? authProvider}) async {
    if (configProvider != null && authProvider != null) {
      _initializeBackendRepositories(configProvider, authProvider);
    }

    if (configProvider?.operationMode == 'server' &&
        _backendMotorRepository != null) {
      // Mode serveur : charger depuis le backend
      try {
        _motors = await _backendMotorRepository!.getAllMotors();
      } catch (e) {
        // En cas d'erreur, garder la liste actuelle
      }
    } else {
      // Mode autonome : charger depuis SQLite local
      _motors = await _motorRepository.getAllMotors();
    }
    notifyListeners();
  }

  Future<bool> createMotor(Motor motor,
      {ConfigProvider? configProvider, AuthProvider? authProvider}) async {
    try {
      if (configProvider?.operationMode == 'server' &&
          _backendMotorRepository != null) {
        // Mode serveur
        await _backendMotorRepository!.createMotor(motor);
        await loadMotors(
            configProvider: configProvider, authProvider: authProvider);
        return true;
      } else {
        // Mode autonome
        final id = await _motorRepository.createMotor(motor);
        if (id > 0) {
          await loadMotors(
              configProvider: configProvider, authProvider: authProvider);
          return true;
        }
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMotor(Motor motor,
      {ConfigProvider? configProvider, AuthProvider? authProvider}) async {
    try {
      if (configProvider?.operationMode == 'server' &&
          _backendMotorRepository != null) {
        // Mode serveur
        await _backendMotorRepository!.updateMotor(motor);
        await loadMotors(
            configProvider: configProvider, authProvider: authProvider);
        return true;
      } else {
        // Mode autonome
        await _motorRepository.updateMotor(motor);
        await loadMotors(
            configProvider: configProvider, authProvider: authProvider);
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMotor(int id,
      {ConfigProvider? configProvider, AuthProvider? authProvider}) async {
    try {
      if (configProvider?.operationMode == 'server' &&
          _backendMotorRepository != null) {
        // Mode serveur
        final success = await _backendMotorRepository!.deleteMotor(id);
        if (success) {
          await loadMotors(
              configProvider: configProvider, authProvider: authProvider);
        }
        return success;
      } else {
        // Mode autonome
        await _motorRepository.deleteMotor(id);
        await loadMotors(
            configProvider: configProvider, authProvider: authProvider);
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> startPollingTelemetry(ConfigProvider configProvider,
      {AuthProvider? authProvider}) async {
    if (_isPolling) return;
    _isPolling = true;

    final interval = Duration(
      milliseconds: configProvider.refreshIntervalMs,
    );

    _telemetryTimer = Timer.periodic(interval, (_) async {
      await _fetchAllMotorsTelemetry(configProvider,
          authProvider: authProvider);
    });

    // Première récupération immédiate
    await _fetchAllMotorsTelemetry(configProvider, authProvider: authProvider);
  }

  void stopPollingTelemetry() {
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
    _isPolling = false;
  }

  Future<void> _fetchAllMotorsTelemetry(ConfigProvider configProvider,
      {AuthProvider? authProvider}) async {
    if (configProvider.operationMode == 'server') {
      // Mode serveur : les données viennent du backend (l'ESP32 envoie directement)
      // On récupère juste les dernières valeurs depuis le backend
      if (_backendMotorRepository != null) {
        bool hasSuccess = false;
        for (final motor in _motors) {
          try {
            final status =
                await _backendMotorRepository!.getMotorStatus(motor.id!);
            if (status != null) {
              hasSuccess = true;
              // Mettre à jour le moteur avec les dernières valeurs
              final updatedMotor = motor.copyWith(
                isRunning: status['is_running'] ?? false,
                lastTemperature: status['temperature']?.toDouble(),
                lastVibration: status['vibration']?.toDouble(),
                lastCurrent: status['current']?.toDouble(),
                lastSpeedRpm: status['speed_rpm']?.toDouble(),
                lastBatteryPercent: status['battery_percent']?.toDouble(),
                lastUpdate: status['created_at'] != null
                    ? DateTime.parse(status['created_at'])
                    : null,
              );
              // Mettre à jour dans la liste
              final index = _motors.indexWhere((m) => m.id == motor.id);
              if (index != -1) {
                _motors[index] = updatedMotor;
              }
            }
          } catch (e) {
            // Erreur de connexion - on continue pour les autres moteurs
            if (!hasSuccess) {
              _isConnected = false;
              _connectionError = 'Erreur de connexion au serveur';
            }
          }
        }
        // Si au moins une requête a réussi, on considère la connexion OK
        if (hasSuccess) {
          _isConnected = true;
          _connectionError = null;
        }
        notifyListeners();
      }
    } else {
      // Mode autonome : récupérer depuis l'ESP32 directement
      if (!configProvider.isEsp32Connected) return;

      final esp32Repo = Esp32Repository(baseUrl: configProvider.esp32BaseUrl);

      bool hasSuccess = false;
      for (final motor in _motors) {
        if (motor.esp32Uid == null && motor.code.isEmpty) continue;

        try {
          final status = await esp32Repo.getMotorStatus(
            esp32Uid: motor.esp32Uid,
            motorCode: motor.code,
          );

          if (status != null) {
            hasSuccess = true;
            final telemetry =
                esp32Repo.parseStatusToTelemetry(status, motor.id!);
            if (telemetry != null) {
              // Sauvegarder la télémétrie
              await _telemetryRepository.createTelemetry(telemetry);

              // Mettre à jour le moteur
              final updatedMotor = motor.copyWith(
                isRunning: telemetry.isRunning,
                lastTemperature: telemetry.temperature,
                lastVibration: telemetry.vibration,
                lastCurrent: telemetry.current,
                lastSpeedRpm: telemetry.speedRpm,
                lastBatteryPercent: telemetry.batteryPercent,
                lastUpdate: telemetry.createdAt,
              );
              await _motorRepository.updateMotor(updatedMotor);

              // Mettre à jour le cache
              _latestTelemetry[motor.id!] = telemetry;

              // Vérifier les alertes de sécurité
              _checkSafetyAlerts(telemetry, configProvider);
            }
          }
        } catch (e) {
          // Erreur de connexion ESP32
          if (!hasSuccess) {
            _isConnected = false;
            _connectionError = 'Erreur de connexion à l\'ESP32';
          }
        }
      }
      // Si au moins une requête a réussi, on considère la connexion OK
      if (hasSuccess) {
        _isConnected = true;
        _connectionError = null;
      }
      notifyListeners();

      await loadMotors();
      notifyListeners();
    }
  }

  Future<bool> sendMotorCommand(
    int motorId,
    String action, {
    double? targetSpeedRpm,
    required ConfigProvider configProvider,
    AuthProvider? authProvider,
  }) async {
    final motor = _motors.firstWhere((m) => m.id == motorId);

    if (configProvider.operationMode == 'server' &&
        _backendMotorRepository != null) {
      // Mode serveur : envoyer la commande via le backend
      final success = await _backendMotorRepository!.sendMotorCommand(
        motorId,
        action,
        targetSpeedRpm: targetSpeedRpm,
      );

      if (success) {
        // Recharger les données après la commande
        await _fetchAllMotorsTelemetry(configProvider,
            authProvider: authProvider);
      }

      return success;
    } else {
      // Mode autonome : envoyer directement à l'ESP32
      if (motor.esp32Uid == null && motor.code.isEmpty) return false;

      final esp32Repo = Esp32Repository(baseUrl: configProvider.esp32BaseUrl);

      final success = await esp32Repo.sendMotorCommand(
        action: action,
        targetSpeedRpm: targetSpeedRpm,
        esp32Uid: motor.esp32Uid,
        motorCode: motor.code,
      );

      if (success) {
        // Recharger les données après la commande
        await _fetchAllMotorsTelemetry(configProvider,
            authProvider: authProvider);
      }

      return success;
    }
  }

  /// Vérifie les seuils de sécurité et déclenche les alertes sonores
  void _checkSafetyAlerts(Telemetry telemetry, ConfigProvider configProvider) {
    final alertService = AlertService();
    bool hasAlert = false;

    // Vérifier la température
    if (telemetry.temperature > configProvider.maxTemperature) {
      hasAlert = true;
    }

    // Vérifier la vibration
    if (telemetry.vibration > configProvider.maxVibration) {
      hasAlert = true;
    }

    // Vérifier la batterie
    if (telemetry.batteryPercent != null &&
        telemetry.batteryPercent! < configProvider.minBatteryPercent) {
      hasAlert = true;
    }

    // Déclencher l'alerte sonore si un seuil est dépassé
    if (hasAlert) {
      alertService.playAlertSound();
    }
  }

  @override
  void dispose() {
    stopPollingTelemetry();
    _backendMotorRepository?.dispose();
    _backendTelemetryRepository?.dispose();
    super.dispose();
  }
}
