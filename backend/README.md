# MotorGuard Backend (FastAPI)

Backend FastAPI pour la solution IoT MotorGuard. Ce backend est optionnel pour la démo du hackathon (mode autonome), mais nécessaire pour une utilisation future en mode serveur.

## Installation

1. Créer un environnement virtuel Python :

```bash
python -m venv venv
source venv/bin/activate  # Sur Windows: venv\Scripts\activate
```

2. Installer les dépendances :

```bash
pip install -r requirements.txt
```

## Lancement


```bash
uvicorn app.main:app --reload
```

L'API sera accessible sur `http://localhost:8000`

- Documentation Swagger : `http://localhost:8000/docs`
- Documentation ReDoc : `http://localhost:8000/redoc`

## Base de données

La base de données SQLite `motorguard.db` est créée automatiquement au premier lancement dans le répertoire `backend/`.

## Compte administrateur par défaut

Un compte administrateur est créé automatiquement au premier lancement :

- **Email** : `admin@motorguard.local`
- **Mot de passe** : `admin123`

⚠️ **Important** : Changez ce mot de passe en production !

## Structure

- `app/models.py` : Modèles de données SQLModel
- `app/schemas.py` : Schémas Pydantic pour validation
- `app/database.py` : Configuration de la base de données
- `app/deps.py` : Dépendances (auth, sessions, etc.)
- `app/routers/` : Routes API organisées par domaine
  - `auth.py` : Authentification
  - `users.py` : Gestion des utilisateurs
  - `motors.py` : Gestion des moteurs
  - `telemetry.py` : Télémétrie
  - `maintenance.py` : Tâches et rapports de maintenance
  - `safety.py` : Configuration de sécurité
  - `iot.py` : Endpoints IoT (simulation ESP32)

## Endpoints principaux

### Authentification

- `POST /auth/login` : Connexion
- `POST /auth/login-json` : Connexion (format JSON)

### Utilisateurs

- `GET /users/` : Liste des utilisateurs (ADMIN)
- `POST /users/` : Créer un utilisateur (ADMIN)
- `GET /users/me` : Informations de l'utilisateur connecté

### Moteurs

- `GET /motors/` : Liste des moteurs
- `POST /motors/` : Créer un moteur
- `GET /motors/{id}` : Détails d'un moteur
- `PUT /motors/{id}` : Mettre à jour un moteur
- `DELETE /motors/{id}` : Supprimer un moteur

### Télémétrie

- `POST /telemetry/` : Créer un point de télémétrie
- `GET /telemetry/motor/{motor_id}` : Historique de télémétrie
- `GET /telemetry/motor/{motor_id}/latest` : Dernière télémétrie

### Maintenance

- `POST /maintenance/tasks` : Créer une tâche (ADMIN)
- `GET /maintenance/tasks` : Liste des tâches
- `POST /maintenance/reports` : Créer un rapport

### Sécurité

- `GET /safety/configs/motor/{motor_id}` : Configuration de sécurité
- `PUT /safety/configs/motor/{motor_id}` : Mettre à jour la config

### IoT

- `GET /iot/motor/status` : État du moteur (simulation ESP32)
- `POST /iot/motor/command` : Envoyer une commande (simulation ESP32)

## Tests

Pour tester l'API, vous pouvez utiliser :

- L'interface Swagger : `http://localhost:8000/docs`
- `curl` ou `Postman`
- L'application Flutter (en mode serveur)

## Notes

- Ce backend n'est **pas utilisé** pendant la démo du hackathon (mode autonome)
- L'application Flutter fonctionne en mode autonome avec SQLite local
- Ce backend est prévu pour une utilisation future (cloud / on-premise)
