# MotorGuard Mobile

Application mobile Flutter pour la solution IoT MotorGuard.

## Prérequis

- Flutter SDK (version 3.0.0 ou supérieure)
- Android SDK (pour build Android)
- Un téléphone Android ou un émulateur

## Installation

1. Installer les dépendances :

```bash
cd mobile
flutter pub get
```

2. Vérifier la configuration :

```bash
flutter doctor
```

## Lancement en mode debug

```bash
flutter run
```

L'application se lancera sur un appareil connecté ou un émulateur.

## Build APK release

Pour générer un APK prêt pour la production :

```bash
flutter build apk --release
```

L'APK sera généré dans :

```
build/app/outputs/flutter-apk/app-release.apk
```

### Installation de l'APK

1. Transférer l'APK sur le téléphone Android
2. Ouvrir le fichier APK
3. Autoriser l'installation depuis des sources inconnues si demandé
4. Installer

Ou via ADB :

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Structure du projet

```
lib/
├── main.dart                 # Point d'entrée
├── models/                   # Modèles de données
├── database/                 # Base SQLite
├── repositories/             # Accès aux données
├── providers/                # State management
└── screens/                  # Écrans UI
```

## Configuration

### Connexion ESP32

L'application doit être configurée pour se connecter à l'ESP32 :

1. Aller dans **Paramètres** → **Configuration IoT / Réseau**
2. Configurer :
   - SSID ESP32 (défaut: MotorGuard_AP)
   - Mot de passe ESP32 (défaut: motorguard123)
   - URL base ESP32 (défaut: http://192.168.4.1)
   - Intervalle de rafraîchissement (défaut: 2000 ms)

### Compte par défaut

- **Email** : `admin@motorguard.local`
- **Mot de passe** : `admin123`

## Fonctionnalités

- ✅ Authentification (ADMIN / TECHNICIAN)
- ✅ Gestion multi-moteurs
- ✅ Surveillance temps réel
- ✅ Contrôle moteur (START / STOP)
- ✅ Historique de télémétrie
- ✅ Statistiques d'utilisation
- ✅ Configuration de sécurité
- ✅ Gestion des utilisateurs (ADMIN)
- ✅ Tâches de maintenance (à compléter)
- ✅ Mode autonome (ESP32 direct)

## Dépendances principales

- `provider` : State management
- `sqflite` : Base de données SQLite locale
- `http` : Communication HTTP avec ESP32
- `shared_preferences` : Stockage de configuration
- `google_fonts` : Typographie
- `fl_chart` : Graphiques (pour statistiques)

## Mode de fonctionnement

### Mode autonome (par défaut)

L'application fonctionne en mode autonome :

- Communication directe avec l'ESP32 via Wi-Fi AP
- Stockage local SQLite
- Aucun serveur requis

### Mode serveur (expérimental)

Pour usage futur avec backend FastAPI :

- Communication via API REST
- Synchronisation avec serveur
- Multi-utilisateurs centralisé

## Dépannage

### Erreur de build

```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Problème de connexion ESP32

1. Vérifier que le téléphone est connecté au Wi-Fi de l'ESP32
2. Vérifier l'URL base ESP32 dans les paramètres
3. Tester la connexion depuis l'app

### Base de données corrompue

L'application recrée automatiquement la base au démarrage si nécessaire.

## Documentation

- Guide utilisateur : `../docs/user_guide_mobile.md`
- Architecture : `../docs/architecture.md`
- Endpoints ESP32 : `../docs/endpoints_for_esp32.md`

## Licence

Propriétaire - Hackathon MotorGuard
