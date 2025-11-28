# MotorGuard API Reference

Documentation de l'API REST du backend FastAPI MotorGuard.

## Base URL

```
http://localhost:8000
```

## Authentification

La plupart des endpoints nécessitent une authentification via JWT. Pour obtenir un token :

1. Se connecter via `POST /auth/login`
2. Utiliser le token dans l'en-tête `Authorization: Bearer <token>`

---

## Endpoints d'authentification

### POST /auth/login

Connexion utilisateur (format OAuth2).

**Body (form-data)** :

- `username` : Email de l'utilisateur
- `password` : Mot de passe

**Réponse** :

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

### POST /auth/login-json

Connexion utilisateur (format JSON).

**Body (JSON)** :

```json
{
  "email": "admin@motorguard.local",
  "password": "admin123"
}
```

**Réponse** : Identique à `/auth/login`

---

## Endpoints utilisateurs

### GET /users/

Liste tous les utilisateurs (ADMIN uniquement).

**Headers** : `Authorization: Bearer <token>`

**Réponse** :

```json
[
  {
    "id": 1,
    "full_name": "Administrateur",
    "email": "admin@motorguard.local",
    "role": "ADMIN",
    "is_active": true,
    "created_at": "2025-11-24T10:00:00Z"
  }
]
```

### POST /users/

Créer un nouvel utilisateur (ADMIN uniquement).

**Body (JSON)** :

```json
{
  "full_name": "Jean Dupont",
  "email": "jean.dupont@example.com",
  "password": "motdepasse123",
  "role": "TECHNICIAN"
}
```

**Réponse** : Objet User (sans le mot de passe)

### GET /users/me

Obtenir les informations de l'utilisateur connecté.

**Réponse** : Objet User

### GET /users/{user_id}

Obtenir un utilisateur par ID (ADMIN uniquement).

---

## Endpoints moteurs

### GET /motors/

Liste tous les moteurs.

**Réponse** :

```json
[
  {
    "id": 1,
    "name": "Broyeur Principal",
    "code": "M001",
    "location": "Atelier 3",
    "description": "Broyeur à marteaux",
    "esp32_uid": "ESP32_001",
    "is_running": true,
    "last_temperature": 55.0,
    "last_vibration": 2.4,
    "last_current": 12.5,
    "last_speed_rpm": 1450,
    "last_battery_percent": 87.0,
    "last_update": "2025-11-24T12:34:56Z"
  }
]
```

### POST /motors/

Créer un nouveau moteur.

**Body (JSON)** :

```json
{
  "name": "Broyeur Principal",
  "code": "M001",
  "location": "Atelier 3",
  "description": "Broyeur à marteaux",
  "esp32_uid": "ESP32_001"
}
```

### GET /motors/{motor_id}

Obtenir un moteur par ID.

### PUT /motors/{motor_id}

Mettre à jour un moteur.

**Body (JSON)** : Champs à mettre à jour (tous optionnels)

### DELETE /motors/{motor_id}

Supprimer un moteur.

---

## Endpoints télémétrie

### POST /telemetry/

Créer un point de télémétrie.

**Body (JSON)** :

```json
{
  "motor_id": 1,
  "temperature": 55.0,
  "vibration": 2.4,
  "current": 12.5,
  "speed_rpm": 1450,
  "is_running": true,
  "battery_percent": 87.0
}
```

### GET /telemetry/motor/{motor_id}

Obtenir l'historique de télémétrie d'un moteur.

**Paramètres de requête** :

- `limit` (int, optionnel) : Nombre maximum de résultats (défaut: 100)
- `hours` (int, optionnel) : Nombre d'heures à remonter (défaut: 24)

**Exemple** : `/telemetry/motor/1?limit=50&hours=12`

### GET /telemetry/motor/{motor_id}/latest

Obtenir la dernière télémétrie d'un moteur.

---

## Endpoints maintenance

### POST /maintenance/tasks

Créer une tâche de maintenance (ADMIN uniquement).

**Body (JSON)** :

```json
{
  "motor_id": 1,
  "assigned_to_user_id": 2,
  "title": "Maintenance préventive",
  "description": "Vérification des roulements",
  "scheduled_date": "2025-12-01T09:00:00Z"
}
```

### GET /maintenance/tasks

Liste les tâches de maintenance.

**Paramètres de requête** :

- `motor_id` (int, optionnel)
- `assigned_to_user_id` (int, optionnel)
- `status` (string, optionnel) : "PLANNED", "IN_PROGRESS", "DONE", "CANCELLED"

**Note** : Les techniciens voient uniquement leurs propres tâches.

### GET /maintenance/tasks/{task_id}

Obtenir une tâche par ID.

### PUT /maintenance/tasks/{task_id}/status

Mettre à jour le statut d'une tâche.

**Paramètres de requête** :

- `new_status` (string) : Nouveau statut

### POST /maintenance/reports

Créer un rapport de maintenance.

**Body (JSON)** :

```json
{
  "task_id": 1,
  "summary": "Maintenance effectuée avec succès",
  "details": "Roulements vérifiés et graissés",
  "start_time": "2025-12-01T09:00:00Z",
  "end_time": "2025-12-01T10:30:00Z"
}
```

### GET /maintenance/reports/task/{task_id}

Obtenir le rapport d'une tâche.

---

## Endpoints sécurité

### POST /safety/configs

Créer une configuration de sécurité pour un moteur.

**Body (JSON)** :

```json
{
  "motor_id": 1,
  "max_temperature": 80.0,
  "max_vibration": 5.0,
  "min_battery_percent": 20.0,
  "emergency_stop_delay_seconds": 5,
  "enable_sms_alerts": false,
  "sms_phone_number": null
}
```

### GET /safety/configs/motor/{motor_id}

Obtenir la configuration de sécurité d'un moteur.

### PUT /safety/configs/motor/{motor_id}

Mettre à jour la configuration de sécurité.

---

## Endpoints IoT (simulation)

Ces endpoints simulent ce que l'ESP32 devrait exposer. En production, ils seraient appelés directement par l'ESP32.

### GET /iot/motor/status

Obtenir l'état actuel d'un moteur.

**Paramètres de requête** :

- `esp32_uid` (string, optionnel)
- `motor_code` (string, optionnel)

### POST /iot/motor/command

Envoyer une commande au moteur.

**Paramètres de requête** : Identiques à `/iot/motor/status`

**Body (JSON)** :

```json
{
  "action": "START",
  "target_speed_rpm": 1500.0
}
```

---

## Endpoints système

### GET /health

Vérification de santé de l'API.

**Réponse** :

```json
{
  "status": "ok"
}
```

### GET /

Page d'accueil de l'API.

**Réponse** :

```json
{
  "message": "MotorGuard API",
  "version": "1.0.0",
  "docs": "/docs"
}
```

---

## Documentation interactive

Une documentation interactive Swagger est disponible à :

```
http://localhost:8000/docs
```

Une documentation ReDoc est disponible à :

```
http://localhost:8000/redoc
```

---

## Codes de statut HTTP

- `200 OK` : Requête réussie
- `201 Created` : Ressource créée avec succès
- `400 Bad Request` : Requête invalide
- `401 Unauthorized` : Authentification requise
- `403 Forbidden` : Permissions insuffisantes
- `404 Not Found` : Ressource non trouvée
- `500 Internal Server Error` : Erreur serveur

---

## Exemples d'utilisation

### Exemple complet : Créer un moteur et récupérer sa télémétrie

```bash
# 1. Se connecter
TOKEN=$(curl -X POST "http://localhost:8000/auth/login-json" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@motorguard.local","password":"admin123"}' \
  | jq -r '.access_token')

# 2. Créer un moteur
curl -X POST "http://localhost:8000/motors/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Broyeur Principal",
    "code": "M001",
    "location": "Atelier 3",
    "esp32_uid": "ESP32_001"
  }'

# 3. Créer un point de télémétrie
curl -X POST "http://localhost:8000/telemetry/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "motor_id": 1,
    "temperature": 55.0,
    "vibration": 2.4,
    "current": 12.5,
    "speed_rpm": 1450,
    "is_running": true,
    "battery_percent": 87.0
  }'

# 4. Récupérer l'historique
curl "http://localhost:8000/telemetry/motor/1?limit=10" \
  -H "Authorization: Bearer $TOKEN"
```
