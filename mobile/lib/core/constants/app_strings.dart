/// Chaînes de caractères de l'application (pour i18n future)
class AppStrings {
  AppStrings._();

  // Navigation
  static const String navHome = 'Accueil';
  static const String navMachines = 'Machines';
  static const String navAlerts = 'Alertes';
  static const String navUsers = 'Utilisateurs';
  static const String navConfig = 'Config';

  // Écrans
  static const String screenLogin = 'Connexion';
  static const String screenDashboard = 'Tableau de bord';
  static const String screenMotorControl = 'Centre de contrôle';
  static const String screenSettings = 'Configuration';
  static const String screenExportPdf = 'Exporter en PDF';

  // Messages
  static const String msgConnectionSuccess = 'Connexion réussie';
  static const String msgConnectionFailed = 'Échec de la connexion';
  static const String msgMotorCreated = 'Machine créée avec succès';
  static const String msgMotorUpdated = 'Machine mise à jour';
  static const String msgSaveError = 'Erreur lors de la sauvegarde';
  static const String msgNoData = 'Aucune donnée disponible';
  static const String msgAdminOnly = 'Accès réservé aux administrateurs';

  // Labels
  static const String labelName = 'Nom';
  static const String labelCode = 'Code';
  static const String labelLocation = 'Localisation';
  static const String labelDescription = 'Description';
  static const String labelEsp32Uid = 'ESP32 UID';
  static const String labelTemperature = 'Température';
  static const String labelVibration = 'Vibration';
  static const String labelCurrent = 'Courant';
  static const String labelSpeed = 'Vitesse';
  static const String labelBattery = 'Batterie';

  // Unités
  static const String unitCelsius = '°C';
  static const String unitMmPerSecond = 'mm/s';
  static const String unitAmpere = 'A';
  static const String unitRpm = 'RPM';
  static const String unitPercent = '%';
}
