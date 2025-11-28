# Structure du Projet MotorGuard

## Organisation des dossiers

```
lib/
├── core/                    # Code central réutilisable
│   ├── constants/          # Constantes de l'application
│   │   ├── app_constants.dart
│   │   └── app_strings.dart
│   └── utils/              # Utilitaires
│       ├── validators.dart
│       └── date_formatters.dart
│
├── features/               # Fonctionnalités métier (organisation future)
│
├── models/                 # Modèles de données
│   ├── motor.dart
│   ├── telemetry.dart
│   ├── user.dart
│   └── ...
│
├── providers/              # State management (Provider)
│   ├── auth_provider.dart
│   ├── config_provider.dart
│   └── motor_provider.dart
│
├── repositories/           # Accès aux données
│   ├── motor_repository.dart
│   ├── telemetry_repository.dart
│   ├── esp32_repository.dart
│   └── backend_*.dart
│
├── screens/                # Écrans de l'application
│   ├── auth/
│   │   └── login_screen.dart
│   ├── dashboard/
│   │   └── home_screen.dart
│   ├── motors/
│   │   ├── motors_list_screen.dart
│   │   ├── motor_detail_screen.dart
│   │   └── motor_form_screen.dart
│   └── ...
│
├── services/               # Services métier
│   ├── alert_service.dart
│   ├── network_scanner_service.dart
│   └── pdf_export_service.dart
│
├── shared/                 # Composants partagés
│   └── widgets/
│       ├── common/         # Widgets communs réutilisables
│       │   ├── loading_indicator.dart
│       │   ├── empty_state.dart
│       │   ├── error_message.dart
│       │   └── confirm_dialog.dart
│       └── motor/          # Widgets spécifiques aux moteurs
│           ├── motor_card.dart
│           ├── metric_card.dart
│           └── rpm_gauge.dart
│
├── theme/                  # Thème et styles
│   └── app_theme.dart
│
├── database/               # Base de données locale
│   └── database_helper.dart
│
└── main.dart               # Point d'entrée
```

## Principes de développement

### 1. Séparation des responsabilités

- **Models** : Structure de données uniquement
- **Repositories** : Accès aux données (local/remote)
- **Providers** : Gestion de l'état
- **Screens** : Interface utilisateur
- **Services** : Logique métier réutilisable
- **Widgets** : Composants UI réutilisables

### 2. Réutilisabilité

- Utiliser les widgets communs (`shared/widgets/common/`)
- Extraire les constantes dans `core/constants/`
- Utiliser les utilitaires dans `core/utils/`

### 3. Maintenabilité

- Noms explicites pour les classes et fonctions
- Commentaires uniquement pour la logique complexe
- Structure modulaire et claire

## Patterns utilisés

- **Provider** : State management
- **Repository Pattern** : Abstraction de l'accès aux données
- **Service Pattern** : Logique métier réutilisable
- **Widget Composition** : Réutilisation de widgets
