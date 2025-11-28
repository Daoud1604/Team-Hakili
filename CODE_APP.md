# Code Application MotorGuard

## 📱 Application Flutter Mobile

### Structure du code

```
mobile/lib/
├── main.dart                    # Point d'entrée de l'application
├── models/                      # Modèles de données
│   ├── motor.dart              # Modèle Moteur
│   ├── telemetry.dart          # Modèle Télémétrie
│   ├── user.dart               # Modèle Utilisateur
│   ├── safety_config.dart      # Configuration de sécurité
│   ├── maintenance_task.dart   # Tâches de maintenance
│   └── maintenance_report.dart # Rapports de maintenance
│
├── screens/                     # Écrans de l'application
│   ├── splash_screen.dart      # Écran de démarrage
│   ├── login_screen.dart       # Écran de connexion
│   ├── home_screen.dart        # Écran d'accueil (navigation)
│   ├── motors_list_screen.dart # Liste des machines
│   ├── motor_detail_screen.dart # Détails et contrôle d'un moteur
│   ├── motor_form_screen.dart  # Formulaire création/édition moteur
│   ├── motor_statistics_screen.dart # Statistiques
│   ├── motor_safety_screen.dart # Configuration sécurité
│   ├── motor_start_confirm_screen.dart # Confirmation démarrage
│   ├── export_pdf_screen.dart  # Export PDF (admin uniquement)
│   ├── notifications_screen.dart # Centre de notifications
│   ├── users_management_screen.dart # Gestion utilisateurs (admin)
│   ├── maintenance_tasks_screen.dart # Tâches de maintenance
│   └── settings_screen.dart    # Configuration
│
├── providers/                   # Gestion d'état (Provider)
│   ├── auth_provider.dart      # Authentification
│   ├── motor_provider.dart     # Gestion des moteurs et télémétrie
│   └── config_provider.dart    # Configuration de l'application
│
├── repositories/                # Accès aux données
│   ├── motor_repository.dart   # Repository local (SQLite)
│   ├── telemetry_repository.dart # Repository télémétrie (SQLite)
│   ├── user_repository.dart    # Repository utilisateurs (SQLite)
│   ├── esp32_repository.dart   # Communication avec ESP32
│   ├── backend_motor_repository.dart # API Backend (FastAPI)
│   ├── backend_telemetry_repository.dart # API Télémétrie
│   └── backend_auth_repository.dart # API Authentification
│
├── services/                    # Services métier
│   ├── alert_service.dart      # Alertes sonores et vibrations
│   ├── network_scanner_service.dart # Scan réseau pour ESP32
│   └── pdf_export_service.dart # Génération de rapports PDF
│
├── widgets/                     # Widgets réutilisables
│   ├── motor_card.dart         # Carte moteur
│   ├── metric_card.dart        # Carte métrique
│   └── rpm_gauge.dart          # Jauge RPM
│
├── shared/widgets/              # Widgets partagés
│   ├── loading_indicator.dart  # Indicateur de chargement
│   ├── empty_state.dart        # État vide
│   ├── error_message.dart      # Message d'erreur
│   └── confirm_dialog.dart     # Dialog de confirmation
│
├── core/                        # Code core
│   ├── constants/
│   │   ├── app_constants.dart  # Constantes de l'application
│   │   └── app_strings.dart    # Chaînes de caractères
│   └── utils/
│       ├── validators.dart     # Validateurs de formulaire
│       └── date_formatters.dart # Formatage de dates
│
├── theme/
│   └── app_theme.dart          # Thème de l'application
│
└── database/
    └── database_helper.dart    # Helper SQLite
```

## 🔧 Backend FastAPI

### Structure du code

```
backend/app/
├── main.py                     # Application FastAPI principale
├── database.py                 # Configuration base de données
├── models.py                   # Modèles SQLModel
├── schemas.py                  # Schémas Pydantic
├── deps.py                     # Dépendances (auth, etc.)
│
└── routers/                    # Routes API
    ├── auth.py                 # Authentification (login, JWT)
    ├── users.py                # Gestion utilisateurs
    ├── motors.py               # CRUD moteurs
    ├── telemetry.py            # Télémétrie
    ├── esp32_devices.py        # Gestion appareils ESP32
    ├── iot.py                  # Endpoints pour ESP32
    ├── safety.py               # Configuration sécurité
    └── maintenance.py          # Maintenance
```

## 🎯 Fonctionnalités principales

### 1. Authentification
- **Mode autonome** : SQLite local
- **Mode serveur** : JWT avec FastAPI
- Rôles : ADMIN / TECHNICIAN
- Gestion des tokens et expiration

### 2. Gestion des moteurs
- CRUD complet (Create, Read, Update, Delete)
- Association avec ESP32 (UID + Code)
- Informations : nom, code, localisation, description
- Statut en temps réel

### 3. Surveillance temps réel
- Polling automatique (configurable, défaut: 2s)
- Métriques : température, vibration, courant, RPM, batterie
- Alertes sonores et vibrations si seuils dépassés
- Historique de télémétrie

### 4. Contrôle moteur
- Démarrage/Arrêt à distance
- Réglage vitesse RPM
- Confirmation avant démarrage
- Arrêt d'urgence

### 5. Statistiques et rapports
- Statistiques (min, max, moyenne)
- Graphiques de tendance
- Export PDF (admin uniquement)
- Sélection période et machines multiples

### 6. Configuration
- Mode de fonctionnement (autonome/serveur)
- Configuration réseau ESP32
- Seuils de sécurité
- Intervalle de rafraîchissement
- Scan réseau automatique

### 7. Sécurité
- Seuils configurables (température, vibration, batterie)
- Alertes automatiques
- Arrêt d'urgence avec délai
- Gestion des permissions (admin/technicien)

## 🔌 Communication

### ESP32 → Application
- **Mode autonome** : HTTP direct (Wi-Fi local)
- **Mode serveur** : ESP32 → Backend → Application
- Endpoints ESP32 :
  - `GET /api/health` : Vérification santé
  - `GET /api/motor/status` : État moteur
  - `POST /api/motor/command` : Commande (START/STOP)

### Application → Backend (mode serveur)
- Authentification JWT
- API REST complète
- HTTPS/TLS supporté
- Certificats auto-signés optionnels

## 📊 Base de données

### SQLite (local)
- `users` : Utilisateurs
- `motors` : Moteurs
- `telemetry` : Historique télémétrie
- `safety_configs` : Configurations sécurité
- `maintenance_tasks` : Tâches maintenance
- `maintenance_reports` : Rapports maintenance

### PostgreSQL/SQLite (backend)
- Même schéma que SQLite local
- Synchronisation possible

## 🛠️ Technologies utilisées

### Flutter
- **State Management** : Provider
- **Base de données** : sqflite / sqflite_common_ffi
- **HTTP** : http
- **PDF** : pdf, printing
- **Graphiques** : fl_chart
- **Préférences** : shared_preferences

### Backend
- **Framework** : FastAPI
- **ORM** : SQLModel
- **Auth** : OAuth2, JWT, bcrypt
- **Base de données** : SQLite (dev) / PostgreSQL (prod)

## 🚀 Dernières améliorations

### Export PDF
- Limitation des données (max 1000 entrées/moteur)
- Pauses entre traitements pour éviter blocage UI
- Dialog de progression
- Génération asynchrone optimisée

### Gestion connexion
- Détection automatique des erreurs
- État de connexion dans MotorProvider
- Réinitialisation automatique
- Messages d'erreur clairs

### Code qualité
- Architecture modulaire
- Séparation des responsabilités
- Constantes centralisées
- Widgets réutilisables
- Gestion d'erreurs robuste

## 📝 Notes techniques

- **Polling** : Intervalle configurable (défaut 2s)
- **Timeout** : 3s pour connexions réseau
- **Limites PDF** : 1000 entrées/moteur, 200 points/graphique
- **Alertes** : Cooldown de 2s entre alertes
- **Permissions Android** : INTERNET, ACCESS_NETWORK_STATE, VIBRATE

## 🔐 Sécurité

- Authentification JWT avec expiration
- API Key pour ESP32
- HTTPS recommandé en production
- Validation des entrées utilisateur
- Gestion des rôles et permissions

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2025-01-XX

