/// Constantes de l'application MotorGuard
class AppConstants {
  AppConstants._(); // Classe utilitaire, pas d'instanciation

  // Configuration par défaut
  static const String defaultEsp32Ip = '192.168.1.50';
  static const int defaultEsp32Port = 80;
  static const String defaultBackendBaseUrl = 'http://192.168.1.100:8000';
  static const int defaultRefreshIntervalMs = 2000;
  static const String defaultOperationMode = 'autonomous';

  // Seuils de sécurité par défaut
  static const double defaultMaxTemperature = 80.0;
  static const double defaultMaxVibration = 5.0;
  static const double defaultMinBatteryPercent = 20.0;
  static const int defaultEmergencyStopDelaySeconds = 5;

  // Durées
  static const Duration alertCooldown = Duration(seconds: 2);
  static const Duration telemetryPollingInterval = Duration(seconds: 2);
  static const Duration connectionTimeout = Duration(seconds: 5);

  // Limites
  static const int maxPdfTableRows = 100;
  static const int maxPdfChartPoints = 200;
  static const int maxTelemetryHistoryHours = 24;
  static const int defaultTelemetryLimit = 100;

  // Textes de l'application
  static const String appName = 'MotorGuard';
  static const String appVersion = '1.0.0';

  // Rôles utilisateurs
  static const String roleAdmin = 'ADMIN';
  static const String roleTechnician = 'TECHNICIAN';

  // Modes d'opération
  static const String modeAutonomous = 'autonomous';
  static const String modeServer = 'server';

  // Actions moteur
  static const String motorActionStart = 'START';
  static const String motorActionStop = 'STOP';
}
