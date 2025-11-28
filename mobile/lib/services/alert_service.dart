import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../core/constants/app_constants.dart';

/// Service pour gérer les alertes sonores et vibratoires
class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  bool _isPlaying = false;
  DateTime? _lastAlertTime;
  static const Duration _alertCooldown = AppConstants.alertCooldown;

  /// Joue un bip d'alerte
  Future<void> playAlertSound() async {
    // Éviter de jouer trop souvent
    if (_lastAlertTime != null &&
        DateTime.now().difference(_lastAlertTime!) < _alertCooldown) {
      return;
    }

    if (_isPlaying) return;

    try {
      _isPlaying = true;
      _lastAlertTime = DateTime.now();

      // Utiliser le son système d'alerte
      await SystemSound.play(SystemSoundType.alert);

      // Vibrer (utilise HapticFeedback natif de Flutter)
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          HapticFeedback.mediumImpact();
        } catch (_) {
          // Ignorer les erreurs de vibration
        }
      }
    } catch (e) {
      // En cas d'erreur, essayer une vibration simple
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          HapticFeedback.lightImpact();
        } catch (_) {
          // Ignorer les erreurs de vibration
        }
      }
    } finally {
      _isPlaying = false;
    }
  }

  /// Joue plusieurs bips d'alerte (pour alertes critiques)
  Future<void> playCriticalAlert() async {
    for (int i = 0; i < 3; i++) {
      await playAlertSound();
      if (i < 2) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  void dispose() {
    // Pas de ressources à libérer
  }
}
