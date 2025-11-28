import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../repositories/esp32_repository.dart';
import '../core/constants/app_constants.dart';

class ConfigProvider with ChangeNotifier {
  // Clés de stockage
  static const String _keyEsp32Ip = 'esp32_ip';
  static const String _keyEsp32Port = 'esp32_port';
  static const String _keyEsp32BaseUrl = 'esp32_base_url';
  static const String _keyBackendBaseUrl = 'backend_base_url';
  static const String _keyRefreshInterval = 'refresh_interval_ms';
  static const String _keyMode = 'operation_mode';
  static const String _keyAllowSelfSignedCert = 'allow_self_signed_cert';
  static const String _keyMaxTemperature = 'max_temperature';
  static const String _keyMaxVibration = 'max_vibration';
  static const String _keyMinBattery = 'min_battery_percent';
  static const String _keyEmergencyStopDelay = 'emergency_stop_delay';

  // Configuration ESP32
  String _esp32Ip = AppConstants.defaultEsp32Ip;
  int _esp32Port = AppConstants.defaultEsp32Port;
  String _esp32BaseUrl = 'http://${AppConstants.defaultEsp32Ip}';
  String _backendBaseUrl = AppConstants.defaultBackendBaseUrl;
  int _refreshIntervalMs = AppConstants.defaultRefreshIntervalMs;
  String _operationMode = AppConstants.defaultOperationMode;
  bool _allowSelfSignedCert = false;
  bool _isEsp32Connected = false;
  bool _isBackendConnected = false;

  // Configuration des alertes
  double _maxTemperature = AppConstants.defaultMaxTemperature;
  double _maxVibration = AppConstants.defaultMaxVibration;
  double _minBatteryPercent = AppConstants.defaultMinBatteryPercent;
  int _emergencyStopDelaySeconds =
      AppConstants.defaultEmergencyStopDelaySeconds;

  // Getters
  String get esp32Ip => _esp32Ip;
  int get esp32Port => _esp32Port;
  String get esp32BaseUrl => _esp32BaseUrl;
  String get backendBaseUrl => _backendBaseUrl;
  int get refreshIntervalMs => _refreshIntervalMs;
  String get operationMode => _operationMode;
  bool get allowSelfSignedCert => _allowSelfSignedCert;
  bool get isEsp32Connected => _isEsp32Connected;
  bool get isBackendConnected => _isBackendConnected;
  double get maxTemperature => _maxTemperature;
  double get maxVibration => _maxVibration;
  double get minBatteryPercent => _minBatteryPercent;
  int get emergencyStopDelaySeconds => _emergencyStopDelaySeconds;

  ConfigProvider() {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _esp32Ip = prefs.getString(_keyEsp32Ip) ?? AppConstants.defaultEsp32Ip;
    _esp32Port = prefs.getInt(_keyEsp32Port) ?? AppConstants.defaultEsp32Port;
    _esp32BaseUrl =
        prefs.getString(_keyEsp32BaseUrl) ?? 'http://$_esp32Ip:$_esp32Port';
    _backendBaseUrl = prefs.getString(_keyBackendBaseUrl) ??
        AppConstants.defaultBackendBaseUrl;
    _refreshIntervalMs = prefs.getInt(_keyRefreshInterval) ??
        AppConstants.defaultRefreshIntervalMs;
    _operationMode =
        prefs.getString(_keyMode) ?? AppConstants.defaultOperationMode;
    _allowSelfSignedCert = prefs.getBool(_keyAllowSelfSignedCert) ?? false;
    _maxTemperature = prefs.getDouble(_keyMaxTemperature) ??
        AppConstants.defaultMaxTemperature;
    _maxVibration =
        prefs.getDouble(_keyMaxVibration) ?? AppConstants.defaultMaxVibration;
    _minBatteryPercent = prefs.getDouble(_keyMinBattery) ??
        AppConstants.defaultMinBatteryPercent;
    _emergencyStopDelaySeconds = prefs.getInt(_keyEmergencyStopDelay) ??
        AppConstants.defaultEmergencyStopDelaySeconds;
    notifyListeners();
  }

  Future<void> updateEsp32Ip(String ip) async {
    _esp32Ip = ip;
    _esp32BaseUrl = 'http://$_esp32Ip:$_esp32Port';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEsp32Ip, ip);
    await prefs.setString(_keyEsp32BaseUrl, _esp32BaseUrl);
    notifyListeners();
  }

  Future<void> updateEsp32Port(int port) async {
    _esp32Port = port;
    _esp32BaseUrl = 'http://$_esp32Ip:$_esp32Port';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyEsp32Port, port);
    await prefs.setString(_keyEsp32BaseUrl, _esp32BaseUrl);
    notifyListeners();
  }

  Future<void> updateEsp32BaseUrl(String url) async {
    _esp32BaseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEsp32BaseUrl, url);
    // Extraire IP et port de l'URL si possible
    try {
      final uri = Uri.parse(url);
      _esp32Ip = uri.host;
      _esp32Port = uri.port;
      await prefs.setString(_keyEsp32Ip, _esp32Ip);
      await prefs.setInt(_keyEsp32Port, _esp32Port);
    } catch (e) {
      // Ignorer si l'URL n'est pas valide
    }
    notifyListeners();
  }

  Future<void> updateMaxTemperature(double value) async {
    _maxTemperature = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMaxTemperature, value);
    notifyListeners();
  }

  Future<void> updateMaxVibration(double value) async {
    _maxVibration = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMaxVibration, value);
    notifyListeners();
  }

  Future<void> updateMinBatteryPercent(double value) async {
    _minBatteryPercent = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMinBattery, value);
    notifyListeners();
  }

  Future<void> updateEmergencyStopDelay(int seconds) async {
    _emergencyStopDelaySeconds = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyEmergencyStopDelay, seconds);
    notifyListeners();
  }

  Future<void> updateRefreshInterval(int milliseconds) async {
    _refreshIntervalMs = milliseconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRefreshInterval, milliseconds);
    notifyListeners();
  }

  Future<void> updateOperationMode(String mode) async {
    _operationMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMode, mode);
    notifyListeners();
  }

  Future<void> updateBackendBaseUrl(String url) async {
    _backendBaseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBackendBaseUrl, url);
    notifyListeners();
  }

  Future<void> updateAllowSelfSignedCert(bool allow) async {
    _allowSelfSignedCert = allow;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAllowSelfSignedCert, allow);
    notifyListeners();
  }

  Future<bool> testEsp32Connection() async {
    final esp32Repo = Esp32Repository(baseUrl: _esp32BaseUrl);
    final isConnected = await esp32Repo.checkHealth();
    _isEsp32Connected = isConnected;
    notifyListeners();
    return isConnected;
  }

  Future<bool> testBackendConnection() async {
    try {
      final uri = Uri.parse('$_backendBaseUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      _isBackendConnected = response.statusCode == 200;
      notifyListeners();
      return _isBackendConnected;
    } catch (e) {
      _isBackendConnected = false;
      notifyListeners();
      return false;
    }
  }
}
