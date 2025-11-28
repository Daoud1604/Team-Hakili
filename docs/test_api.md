# Guide de Test des API MotorGuard

Ce document explique comment tester les endpoints de l'API FastAPI MotorGuard.

## 1. Interface Swagger (Recommandé)

### 1.1 Accéder à Swagger UI

Une fois le backend lancé :

```bash
cd backend
uvicorn app.main:app --reload
```

Ouvrez votre navigateur et allez sur :

- **Swagger UI** : `http://localhost:8000/docs`
- **ReDoc** : `http://localhost:8000/redoc`

### 1.2 Tester avec Swagger

**Méthode simple - Connexion directe :**

1. Cliquez sur le bouton "Authorize" 🔒 en haut à droite de Swagger UI

2. **Si vous voyez plusieurs flows OAuth2** :

   - Cherchez celui nommé **"OAuth2PasswordBearer"** ou **"password"**
   - **Ignorez** "Client credentials" (ce n'est pas celui qu'on utilise)
   - Si vous ne voyez que "Client credentials", voir la méthode alternative ci-dessous

3. Dans le formulaire **OAuth2PasswordBearer** :

   - **username** : Entrez votre **email** → `admin@motorguard.local`
     - ⚠️ **Important** : Le champ s'appelle "username" mais utilisez votre **email**
   - **password** : Entrez votre mot de passe → `admin123`

4. Cliquez sur "Authorize"

5. Swagger se connecte automatiquement et récupère le token

6. Vous devriez voir un cadenas vert ✅ à côté de "Authorize"

7. ✅ **C'est tout !** Vous pouvez maintenant tester tous les endpoints protégés

**Méthode alternative - Si vous ne voyez pas le flow "password" :**

1. Allez sur `/auth/login-json` → "Try it out"
2. Entrez :
   ```json
   {
     "email": "admin@motorguard.local",
     "password": "admin123"
   }
   ```
3. Cliquez sur "Execute"
4. Copiez le `access_token` retourné (c'est un long token JWT)
5. Cliquez sur "Authorize" 🔒
6. Dans le champ "Value", entrez **SEULEMENT le token** (sans "Bearer")
7. Cliquez sur "Authorize"

8. **Tester les endpoints** :
   - Tous les endpoints protégés sont maintenant accessibles
   - Cliquez sur n'importe quel endpoint → "Try it out" → "Execute"

## 2. Tests avec curl (Ligne de commande)

### 2.1 Health Check

```bash
curl http://localhost:8000/health
```

Réponse attendue :

```json
{ "status": "ok" }
```

### 2.2 Authentification

```bash
curl -X POST "http://localhost:8000/auth/login-json" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@motorguard.local",
    "password": "admin123"
  }'
```

Réponse :

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

**Sauvegardez le token** pour les requêtes suivantes.

### 2.3 Créer un moteur

```bash
TOKEN="VOTRE_TOKEN_ICI"

curl -X POST "http://localhost:8000/motors/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Broyeur Principal",
    "code": "M001",
    "location": "Atelier 3",
    "description": "Broyeur principal de production",
    "esp32_uid": "ESP32_001"
  }'
```

### 2.4 Lister les moteurs

```bash
curl -X GET "http://localhost:8000/motors/" \
  -H "Authorization: Bearer $TOKEN"
```

### 2.5 Créer un ESP32 Device

```bash
curl -X POST "http://localhost:8000/esp32-devices/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "esp32_uid": "ESP32_001",
    "motor_id": 1
  }'
```

Réponse (notez l'`api_key`) :

```json
{
  "id": 1,
  "esp32_uid": "ESP32_001",
  "api_key": "abc123xyz...",
  "motor_id": 1,
  "is_active": true,
  "created_at": "2025-01-24T12:00:00Z",
  "last_seen": null
}
```

### 2.6 Envoyer de la télémétrie (comme l'ESP32)

```bash
API_KEY="VOTRE_API_KEY_ICI"

curl -X POST "http://localhost:8000/iot/telemetry/from-esp32" \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "motor_id": 1,
    "temperature": 55.5,
    "vibration": 2.4,
    "current": 12.5,
    "speed_rpm": 1450,
    "is_running": true,
    "battery_percent": 87.0
  }'
```

### 2.7 Récupérer la télémétrie d'un moteur

```bash
curl -X GET "http://localhost:8000/telemetry/motor/1?limit=10&hours=24" \
  -H "Authorization: Bearer $TOKEN"
```

### 2.8 Envoyer une commande au moteur

```bash
curl -X POST "http://localhost:8000/iot/motor/command?motor_id=1" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "START",
    "target_speed_rpm": 1500
  }'
```

## 3. Tests avec Postman/Insomnia

### 3.1 Configuration de base

1. **Créer une collection** "MotorGuard API"
2. **Variable d'environnement** :
   - `base_url` : `http://localhost:8000`
   - `token` : (sera rempli après login)

### 3.2 Requête de login

**POST** `{{base_url}}/auth/login-json`

Body (JSON) :

```json
{
  "email": "admin@motorguard.local",
  "password": "admin123"
}
```

**Tests** (onglet Tests dans Postman) :

```javascript
if (pm.response.code === 200) {
  const jsonData = pm.response.json();
  pm.environment.set("token", jsonData.access_token);
}
```

### 3.3 Requêtes authentifiées

Pour toutes les requêtes suivantes, ajouter dans **Headers** :

- Key: `Authorization`
- Value: `Bearer {{token}}`

## 4. Script de test complet (Bash)

Créez un fichier `test_api.sh` :

```bash
#!/bin/bash

BASE_URL="http://localhost:8000"

echo "1. Health Check..."
curl -s "$BASE_URL/health" | jq
echo ""

echo "2. Login..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login-json" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@motorguard.local",
    "password": "admin123"
  }')

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.access_token')
echo "Token: $TOKEN"
echo ""

echo "3. Créer un moteur..."
curl -s -X POST "$BASE_URL/motors/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Broyeur Principal",
    "code": "M001",
    "location": "Atelier 3"
  }' | jq
echo ""

echo "4. Lister les moteurs..."
curl -s -X GET "$BASE_URL/motors/" \
  -H "Authorization: Bearer $TOKEN" | jq
echo ""

echo "5. Créer un ESP32 device..."
ESP32_RESPONSE=$(curl -s -X POST "$BASE_URL/esp32-devices/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "esp32_uid": "ESP32_001",
    "motor_id": 1
  }')

API_KEY=$(echo $ESP32_RESPONSE | jq -r '.api_key')
echo "API Key: $API_KEY"
echo ""

echo "6. Envoyer de la télémétrie (comme ESP32)..."
curl -s -X POST "$BASE_URL/iot/telemetry/from-esp32" \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "motor_id": 1,
    "temperature": 55.5,
    "vibration": 2.4,
    "current": 12.5,
    "speed_rpm": 1450,
    "is_running": true,
    "battery_percent": 87.0
  }' | jq
echo ""

echo "7. Récupérer la télémétrie..."
curl -s -X GET "$BASE_URL/telemetry/motor/1?limit=5" \
  -H "Authorization: Bearer $TOKEN" | jq
echo ""

echo "✅ Tests terminés !"
```

Exécuter :

```bash
chmod +x test_api.sh
./test_api.sh
```

## 5. Tests avec Python (requests)

Créez un fichier `test_api.py` :

```python
import requests
import json

BASE_URL = "http://localhost:8000"

# 1. Health Check
print("1. Health Check...")
response = requests.get(f"{BASE_URL}/health")
print(response.json())
print()

# 2. Login
print("2. Login...")
response = requests.post(
    f"{BASE_URL}/auth/login-json",
    json={
        "email": "admin@motorguard.local",
        "password": "admin123"
    }
)
token = response.json()["access_token"]
print(f"Token: {token}")
print()

# 3. Créer un moteur
print("3. Créer un moteur...")
headers = {"Authorization": f"Bearer {token}"}
response = requests.post(
    f"{BASE_URL}/motors/",
    headers=headers,
    json={
        "name": "Broyeur Principal",
        "code": "M001",
        "location": "Atelier 3"
    }
)
print(json.dumps(response.json(), indent=2))
print()

# 4. Lister les moteurs
print("4. Lister les moteurs...")
response = requests.get(f"{BASE_URL}/motors/", headers=headers)
print(json.dumps(response.json(), indent=2))
print()

# 5. Créer un ESP32 device
print("5. Créer un ESP32 device...")
response = requests.post(
    f"{BASE_URL}/esp32-devices/",
    headers=headers,
    json={
        "esp32_uid": "ESP32_001",
        "motor_id": 1
    }
)
api_key = response.json()["api_key"]
print(f"API Key: {api_key}")
print()

# 6. Envoyer de la télémétrie (comme ESP32)
print("6. Envoyer de la télémétrie...")
response = requests.post(
    f"{BASE_URL}/iot/telemetry/from-esp32",
    headers={"X-API-Key": api_key},
    json={
        "motor_id": 1,
        "temperature": 55.5,
        "vibration": 2.4,
        "current": 12.5,
        "speed_rpm": 1450,
        "is_running": True,
        "battery_percent": 87.0
    }
)
print(json.dumps(response.json(), indent=2))
print()

# 7. Récupérer la télémétrie
print("7. Récupérer la télémétrie...")
response = requests.get(
    f"{BASE_URL}/telemetry/motor/1?limit=5",
    headers=headers
)
print(json.dumps(response.json(), indent=2))
print()

print("✅ Tests terminés !")
```

Exécuter :

```bash
pip install requests
python test_api.py
```

## 6. Endpoints principaux à tester

### Authentification

- `POST /auth/login-json` - Connexion
- `GET /users/me` - Informations utilisateur

### Moteurs

- `GET /motors/` - Liste des moteurs
- `POST /motors/` - Créer un moteur
- `GET /motors/{id}` - Détails d'un moteur
- `PUT /motors/{id}` - Modifier un moteur
- `DELETE /motors/{id}` - Supprimer un moteur

### ESP32 Devices

- `POST /esp32-devices/` - Créer un device ESP32
- `GET /esp32-devices/` - Liste des devices
- `PATCH /esp32-devices/{id}/motor` - Associer à un moteur
- `POST /esp32-devices/{id}/regenerate-api-key` - Régénérer la clé

### Télémétrie

- `POST /iot/telemetry/from-esp32` - Envoyer télémétrie (ESP32)
- `GET /telemetry/motor/{motor_id}` - Récupérer télémétrie

### Commandes

- `POST /iot/motor/command` - Envoyer commande START/STOP

## 7. Vérification des erreurs

### Erreur 401 Unauthorized

- Token manquant ou expiré
- Vérifier le header `Authorization: Bearer TOKEN`

### Erreur 403 Forbidden

- Permissions insuffisantes (nécessite ADMIN)
- Vérifier le rôle de l'utilisateur

### Erreur 404 Not Found

- Endpoint ou ressource inexistante
- Vérifier l'URL et l'ID

### Erreur 422 Validation Error

- Données invalides
- Vérifier le format JSON et les champs requis

## 8. Tests de charge (optionnel)

Avec `ab` (Apache Bench) :

```bash
# Test de charge sur health endpoint
ab -n 1000 -c 10 http://localhost:8000/health
```

Avec `wrk` :

```bash
wrk -t4 -c100 -d30s http://localhost:8000/health
```

## 9. Monitoring

Vérifier les logs du serveur :

```bash
# Les logs s'affichent dans le terminal où uvicorn tourne
# Ou rediriger vers un fichier :
uvicorn app.main:app --reload 2>&1 | tee api.log
```

## 10. Tests d'intégration

Pour tester le flux complet :

1. ✅ Créer un utilisateur (ADMIN)
2. ✅ Se connecter et obtenir un token
3. ✅ Créer un moteur
4. ✅ Créer un ESP32 device et obtenir l'API Key
5. ✅ Associer l'ESP32 au moteur
6. ✅ Envoyer de la télémétrie (simuler l'ESP32)
7. ✅ Récupérer la télémétrie via l'API
8. ✅ Envoyer une commande START/STOP
9. ✅ Vérifier que le moteur a été mis à jour
