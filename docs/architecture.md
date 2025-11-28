# Architecture MotorGuard

Documentation de l'architecture globale de la solution IoT MotorGuard.

## Vue d'ensemble

MotorGuard est une solution IoT pour la surveillance et le contrôle de moteurs industriels. Elle se compose de trois composants principaux :

1. **Firmware ESP32** : Capteur/contrôleur embarqué
2. **Application Flutter** : Interface mobile (Android)
3. **Backend FastAPI** (optionnel) : Serveur pour usage cloud/on-premise

## Modes de fonctionnement

### Mode 1 : Autonome (prioritaire pour le hackathon)

```
┌─────────────┐         Wi-Fi AP          ┌─────────────┐
│   ESP32     │◄─────────────────────────►│  Flutter    │
│  (Capteur)  │    (MotorGuard_AP)        │   (App)     │
└─────────────┘                            └─────────────┘
                                                   │
                                                   │ SQLite
                                                   ▼
                                            ┌─────────────┐
                                            │  Base de    │
                                            │  données    │
                                            │   locale    │
                                            └─────────────┘
```

**Caractéristiques** :

- L'ESP32 fonctionne en mode Access Point (AP)
- Le téléphone se connecte directement au Wi-Fi de l'ESP32
- L'application Flutter communique directement avec l'ESP32 via HTTP
- Toutes les données sont stockées localement dans SQLite sur le téléphone
- Aucun serveur externe requis
- Fonctionne 100% hors ligne

**Flux de données** :

1. L'ESP32 expose une API REST simple (`/api/motor/status`, `/api/motor/command`)
2. L'app Flutter interroge périodiquement l'ESP32 pour la télémétrie
3. Les données sont stockées localement en SQLite
4. L'app peut envoyer des commandes (START/STOP) à l'ESP32

### Mode 2 : Serveur (optionnel / pour plus tard)

```
┌─────────────┐         Internet          ┌─────────────┐
│   ESP32     │──────────────────────────►│  FastAPI    │
│  (Capteur)  │                            │  Backend    │
└─────────────┘                            └─────────────┘
                                                   │
                                                   │ SQLite
                                                   ▼
                                            ┌─────────────┐
                                            │  Base de    │
                                            │  données    │
                                            │   serveur   │
                                            └─────────────┘
                                                   ▲
                                                   │ HTTP/REST
                                                   │
                                            ┌─────────────┐
                                            │  Flutter    │
                                            │   (App)     │
                                            └─────────────┘
```

**Caractéristiques** :

- L'ESP32 se connecte à Internet (Wi-Fi ou Ethernet)
- L'ESP32 envoie les données au backend FastAPI
- L'application Flutter se connecte au backend FastAPI
- Les données sont centralisées sur le serveur
- Permet la gestion multi-utilisateurs et multi-sites

**Note** : Ce mode n'est pas utilisé pendant la démo du hackathon.

## Architecture de l'application Flutter

### Structure des dossiers

```
mobile/
├── lib/
│   ├── main.dart                 # Point d'entrée
│   ├── models/                   # Modèles de données
│   │   ├── user.dart
│   │   ├── motor.dart
│   │   ├── telemetry.dart
│   │   ├── maintenance_task.dart
│   │   ├── maintenance_report.dart
│   │   └── safety_config.dart
│   ├── database/                 # Base de données SQLite
│   │   └── database_helper.dart
│   ├── repositories/             # Couche d'accès aux données
│   │   ├── user_repository.dart
│   │   ├── motor_repository.dart
│   │   ├── telemetry_repository.dart
│   │   └── esp32_repository.dart
│   ├── providers/                # State management (Provider)
│   │   ├── auth_provider.dart
│   │   ├── motor_provider.dart
│   │   └── config_provider.dart
│   └── screens/                  # Écrans de l'application
│       ├── login_screen.dart
│       ├── home_screen.dart
│       ├── motors_list_screen.dart
│       ├── motor_detail_screen.dart
│       ├── motor_form_screen.dart
│       ├── motor_start_confirm_screen.dart
│       ├── maintenance_tasks_screen.dart
│       ├── users_management_screen.dart
│       └── settings_screen.dart
└── pubspec.yaml
```

### Flux de données dans Flutter

```
┌──────────────┐
│   Écrans     │
│  (UI Layer)  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Providers   │
│ (State Mgmt) │
└──────┬───────┘
       │
       ├─────────────────┬──────────────────┐
       ▼                 ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Repositories │  │   ESP32      │  │   SQLite     │
│   (Local)    │  │  Repository  │  │   Database   │
└──────────────┘  └──────────────┘  └──────────────┘
```

### Couche Repository

La couche Repository permet de switcher entre :

- **Local Repository** : SQLite + communication directe ESP32 (mode autonome)
- **Remote Repository** : FastAPI backend (mode serveur, à implémenter)

Pour la démo, seul le Local Repository est utilisé.

## Architecture du backend FastAPI

### Structure des dossiers

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                  # Application FastAPI
│   ├── database.py              # Configuration SQLite
│   ├── models.py                # Modèles SQLModel
│   ├── schemas.py               # Schémas Pydantic
│   ├── deps.py                  # Dépendances (auth, etc.)
│   └── routers/                 # Routes API
│       ├── auth.py
│       ├── users.py
│       ├── motors.py
│       ├── telemetry.py
│       ├── maintenance.py
│       ├── safety.py
│       └── iot.py
├── requirements.txt
└── README.md
```

### Modèle de données

```
┌──────────┐
│   User   │
└────┬─────┘
     │
     ├─────────────────┐
     │                 │
     ▼                 ▼
┌──────────┐    ┌──────────────┐
│  Motor   │    │ Maintenance  │
└────┬─────┘    │    Task      │
     │          └──────┬───────┘
     │                 │
     ├─────────────────┤
     │                 │
     ▼                 ▼
┌──────────┐    ┌──────────────┐
│Telemetry │    │ Maintenance  │
└──────────┘    │   Report     │
                └──────────────┘
     │
     ▼
┌──────────────┐
│ SafetyConfig │
└──────────────┘
```

## Communication ESP32 ↔ Flutter

### Protocole

- **Protocole** : HTTP REST
- **Format** : JSON
- **Base URL** : `http://192.168.4.1` (configurable)

### Endpoints ESP32

1. **GET /api/health** : Vérification de santé
2. **GET /api/motor/status** : État actuel du moteur
3. **POST /api/motor/command** : Commande (START/STOP)

Voir `docs/endpoints_for_esp32.md` pour plus de détails.

### Polling de télémétrie

L'application Flutter interroge périodiquement l'ESP32 pour récupérer la télémétrie :

```
Flutter                    ESP32
  │                          │
  │── GET /api/motor/status ─►│
  │                          │
  │◄── JSON (télémétrie) ────│
  │                          │
  │ (Stockage SQLite)        │
  │                          │
  │ (Attente 2s)             │
  │                          │
  │── GET /api/motor/status ─►│
  │                          │
  │◄── JSON (télémétrie) ────│
  │                          │
  ...
```

L'intervalle de polling est configurable (par défaut : 2 secondes).

## Base de données

### SQLite (Flutter)

Base de données locale embarquée dans l'APK :

- `users` : Utilisateurs
- `motors` : Moteurs
- `telemetry` : Historique de télémétrie
- `maintenance_tasks` : Tâches de maintenance
- `maintenance_reports` : Rapports de maintenance
- `safety_configs` : Configurations de sécurité
- `notifications` : Notifications locales

### SQLite (Backend FastAPI)

Même schéma que la base Flutter, stockée dans `motorguard.db`.

## Sécurité

### Mode autonome

- Pas d'authentification réseau (communication locale uniquement)
- Authentification locale dans l'app (email/mot de passe stockés en SQLite)
- Les mots de passe sont stockés en clair (à améliorer en production)

### Mode serveur

- Authentification JWT
- Hashage des mots de passe (bcrypt)
- Gestion des rôles (ADMIN / TECHNICIAN)

## Déploiement

### Application Flutter

1. Build APK : `flutter build apk --release`
2. Installation sur Android via ADB ou transfert de fichier
3. L'APK contient tout (app + base SQLite vide)

### Backend FastAPI

1. Installation des dépendances : `pip install -r requirements.txt`
2. Lancement : `uvicorn app.main:app --reload`
3. La base SQLite est créée automatiquement

### ESP32

1. Flash du firmware (Arduino IDE / ESP-IDF)
2. Configuration du SSID/mot de passe (optionnel)
3. L'ESP32 démarre en mode AP automatiquement

## Évolutions futures

1. **Mode serveur complet** : Implémentation du Remote Repository dans Flutter
2. **Synchronisation** : Sync SQLite local ↔ FastAPI
3. **Notifications push** : Alertes en temps réel
4. **Multi-ESP32** : Gestion de plusieurs capteurs simultanément
5. **Analytics** : Tableaux de bord avancés, prédictions
6. **Sécurité renforcée** : Chiffrement, authentification forte
