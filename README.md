# MotorGuard - Solution IoT pour la surveillance de moteurs

Solution complète IoT pour la surveillance, le contrôle et la maintenance de moteurs industriels.

## 🏗️ Architecture

MotorGuard se compose de trois composants principaux :

1. **Firmware ESP32** : Capteur/contrôleur embarqué (à développer séparément)
2. **Application Flutter** : Interface mobile Android (mode autonome)
3. **Backend FastAPI** : Serveur optionnel pour usage cloud/on-premise

## 📁 Structure du projet

```
motorguard/
├── backend/              # Backend FastAPI (optionnel)
│   ├── app/
│   │   ├── main.py
│   │   ├── models.py
│   │   ├── routers/
│   │   └── ...
│   └── requirements.txt
│
├── mobile/              # Application Flutter
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── screens/
│   │   ├── providers/
│   │   └── repositories/
│   └── pubspec.yaml
│
└── docs/                # Documentation
    ├── endpoints_for_esp32.md
    ├── api_reference.md
    ├── architecture.md
    └── user_guide_mobile.md
```

## 🚀 Démarrage rapide

### Mode autonome (pour le hackathon)

1. **Allumer l'ESP32** (doit être configuré en mode AP)
2. **Connecter le téléphone** au Wi-Fi `MotorGuard_AP` (mot de passe: `motorguard123`)
3. **Installer l'APK** sur Android :
   ```bash
   cd mobile
   flutter build apk --release
   # Installer build/app/outputs/flutter-apk/app-release.apk
   ```
4. **Ouvrir l'app** et se connecter avec :
   - Email: `admin@motorguard.local`
   - Mot de passe: `admin123`

### Backend FastAPI (optionnel)

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

L'API sera accessible sur `http://localhost:8000`

- Documentation Swagger : `http://localhost:8000/docs`

## 📱 Application Flutter

### Installation

```bash
cd mobile
flutter pub get
flutter run  # Mode debug
```

### Build APK

```bash
flutter build apk --release
```

L'APK sera dans : `build/app/outputs/flutter-apk/app-release.apk`

### Fonctionnalités

- ✅ Authentification (ADMIN / TECHNICIAN)
- ✅ Gestion multi-moteurs
- ✅ Surveillance temps réel
- ✅ Contrôle moteur (START / STOP)
- ✅ Historique de télémétrie
- ✅ Statistiques d'utilisation
- ✅ Configuration de sécurité
- ✅ Gestion des utilisateurs
- ✅ Mode autonome (ESP32 direct)

## 🔌 Communication ESP32

L'ESP32 doit exposer une API REST simple :

- `GET /api/health` : Vérification de santé
- `GET /api/motor/status` : État actuel du moteur
- `POST /api/motor/command` : Commande (START/STOP)

Voir `docs/endpoints_for_esp32.md` pour la documentation complète.

## 📚 Documentation

- **[Guide utilisateur mobile](docs/user_guide_mobile.md)** : Guide complet pour utiliser l'application
- **[Architecture](docs/architecture.md)** : Architecture détaillée du système
- **[Endpoints ESP32](docs/endpoints_for_esp32.md)** : Documentation pour le firmware ESP32
- **[API Reference](docs/api_reference.md)** : Documentation de l'API FastAPI

## 🎯 Modes de fonctionnement

### Mode 1 : Autonome (prioritaire)

- Téléphone + ESP32 uniquement
- Communication directe via Wi-Fi AP
- Stockage local SQLite
- 100% hors ligne

### Mode 2 : Serveur (optionnel)

- Backend FastAPI centralisé
- Multi-utilisateurs
- Synchronisation cloud
- Pour usage futur

## 🛠️ Technologies

- **Flutter** : Application mobile
- **FastAPI** : Backend Python
- **SQLite** : Base de données
- **ESP32** : Capteur/contrôleur IoT
- **Provider** : State management Flutter

## 📝 Notes importantes

- ⚠️ Pour la démo du hackathon, seul le **mode autonome** est utilisé
- ⚠️ L'ESP32 doit être configuré en mode Access Point
- ⚠️ Le téléphone doit être connecté au Wi-Fi de l'ESP32
- ⚠️ Les mots de passe sont stockés en clair (à améliorer en production)

## 📄 Licence

Propriétaire - Hackathon MotorGuard

---

**Développé avec ❤️ pour le hackathon MotorGuard**
