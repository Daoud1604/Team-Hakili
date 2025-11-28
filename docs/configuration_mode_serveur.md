# Configuration Mode Serveur - MotorGuard

Ce document explique comment configurer MotorGuard en mode serveur, où l'ESP32 et le téléphone sont connectés au même Wi-Fi avec accès Internet, et communiquent via le backend FastAPI.

## Architecture

```
┌─────────────┐         Wi-Fi + Internet          ┌─────────────┐
│   ESP32     │───────────────────────────────────►│  FastAPI    │
│  (Capteur)  │   POST /iot/telemetry/from-esp32   │  Backend    │
│             │   (avec X-API-Key header)          │             │
└─────────────┘                                    └─────────────┘
                                                           │
                                                           │ SQLite
                                                           ▼
                                                    ┌─────────────┐
                                                    │  Base de    │
                                                    │  données    │
                                                    └─────────────┘
                                                           ▲
                                                           │ HTTP/REST + JWT
                                                           │
                                                    ┌─────────────┐
                                                    │  Flutter    │
                                                    │   (App)     │
                                                    └─────────────┘
```

## 1. Configuration Backend FastAPI

### 1.1 Lancer le backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Le backend sera accessible sur `http://VOTRE_IP:8000` (ex: `http://192.168.1.100:8000`)

### 1.2 Créer un ESP32 Device

Via l'API (Swagger: `http://VOTRE_IP:8000/docs`) :

```bash
POST /esp32-devices/
{
  "esp32_uid": "ESP32_001",
  "motor_id": 1  # Optionnel, peut être associé plus tard
}
```

Réponse :

```json
{
  "id": 1,
  "esp32_uid": "ESP32_001",
  "api_key": "abc123...", // ⚠️ À sauvegarder pour l'ESP32
  "motor_id": null,
  "is_active": true,
  "created_at": "2025-01-24T12:00:00Z",
  "last_seen": null
}
```

**Important** : Notez l'`api_key` générée, elle sera nécessaire pour l'ESP32.

### 1.3 Associer l'ESP32 à un moteur

```bash
PATCH /esp32-devices/{device_id}/motor?motor_id=1
```

## 2. Configuration ESP32

### 2.1 Code Arduino

```cpp
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// Configuration Wi-Fi
const char* ssid = "VOTRE_WIFI";
const char* password = "VOTRE_MOT_DE_PASSE";

// Configuration Backend
const char* backendUrl = "http://192.168.1.100:8000";  // IP du serveur
const char* apiKey = "VOTRE_API_KEY_GENERE";  // API Key du backend

// Identifiants ESP32
String esp32_uid = "ESP32_001";
int motor_id = 1;  // ID du moteur dans le backend

// Variables d'état
float temperature = 0.0;
float vibration = 0.0;
float current = 0.0;
float speed_rpm = 0.0;
bool is_running = false;
float battery_percent = 100.0;

HTTPClient http;

void setup() {
  Serial.begin(115200);

  // Connexion Wi-Fi
  WiFi.begin(ssid, password);
  Serial.print("Connexion au Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.print("Connecté ! IP: ");
  Serial.println(WiFi.localIP());
}

void loop() {
  // Lire les capteurs
  temperature = readTemperatureSensor();
  vibration = readVibrationSensor();
  current = readCurrentSensor();
  speed_rpm = readSpeedSensor();
  is_running = (speed_rpm > 0);

  // Envoyer les données au backend toutes les 2 secondes
  sendTelemetryToBackend();

  delay(2000);
}

void sendTelemetryToBackend() {
  http.begin(String(backendUrl) + "/iot/telemetry/from-esp32");

  // ⚠️ IMPORTANT : Ajouter l'API Key dans le header
  http.addHeader("Content-Type", "application/json");
  http.addHeader("X-API-Key", apiKey);

  // Créer le JSON
  DynamicJsonDocument doc(512);
  doc["motor_id"] = motor_id;
  doc["temperature"] = temperature;
  doc["vibration"] = vibration;
  doc["current"] = current;
  doc["speed_rpm"] = speed_rpm;
  doc["is_running"] = is_running;
  doc["battery_percent"] = battery_percent;

  String jsonString;
  serializeJson(doc, jsonString);

  int httpResponseCode = http.POST(jsonString);

  if (httpResponseCode > 0) {
    Serial.printf("Télémétrie envoyée: %d\n", httpResponseCode);
  } else {
    Serial.printf("Erreur: %s\n", http.errorToString(httpResponseCode).c_str());
  }

  http.end();
}
```

### 2.2 Pour HTTPS (recommandé en production)

Si le backend utilise HTTPS, modifier :

```cpp
#include <WiFiClientSecure.h>

WiFiClientSecure client;
HTTPClient http;

void setup() {
  // ...

  // Pour certificat auto-signé (développement uniquement)
  client.setInsecure();

  // OU pour certificat valide
  // client.setCACert(rootCACertificate);
}

void sendTelemetryToBackend() {
  http.begin(client, String(backendUrl) + "/iot/telemetry/from-esp32");
  // ... reste identique
}
```

## 3. Configuration Application Flutter

### 3.1 Configurer le mode serveur

Dans l'application Flutter :

1. Aller dans **Paramètres → Configuration IoT / Réseau**
2. Sélectionner **Mode d'opération : Serveur FastAPI**
3. Entrer l'URL du backend : `http://192.168.1.100:8000` (ou `https://...` si HTTPS)
4. Si certificat auto-signé : Activer "Autoriser certificats auto-signés" (dev uniquement)

### 3.2 Se connecter

1. Utiliser les identifiants du backend :
   - Email : `admin@motorguard.local`
   - Mot de passe : `admin123`

L'application utilisera automatiquement le backend en mode serveur.

## 4. Sécurité

### 4.1 HTTPS (Recommandé)

Pour activer HTTPS sur le backend :

```bash
# Générer un certificat auto-signé (dev)
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 365

# Lancer avec HTTPS
uvicorn app.main:app --host 0.0.0.0 --port 8000 --ssl-keyfile key.pem --ssl-certfile cert.pem
```

### 4.2 Authentification

- **ESP32** : Utilise l'API Key dans le header `X-API-Key`
- **Flutter App** : Utilise JWT (token obtenu via `/auth/login-json`)

### 4.3 Production

⚠️ **Important pour la production** :

1. Changer `SECRET_KEY` dans `backend/app/deps.py`
2. Utiliser un certificat SSL valide (Let's Encrypt)
3. Désactiver les certificats auto-signés dans Flutter
4. Configurer CORS correctement dans `backend/app/main.py`

## 5. Vérification

### 5.1 Vérifier que l'ESP32 envoie des données

```bash
# Vérifier les dernières télémétries
GET /telemetry/motor/1?limit=10
```

### 5.2 Vérifier la connexion Flutter

L'application devrait afficher :

- ✅ "Wi-Fi connecté" (si connecté au réseau)
- ✅ Les données des moteurs depuis le backend
- ✅ Les commandes START/STOP fonctionnent

## 6. Dépannage

### Problème : ESP32 ne peut pas se connecter au backend

- Vérifier que l'ESP32 est sur le même réseau Wi-Fi
- Vérifier l'URL du backend (IP correcte)
- Vérifier que le backend est accessible : `curl http://IP:8000/health`

### Problème : Erreur 401 Unauthorized

- Vérifier que l'API Key est correcte dans le code ESP32
- Vérifier que l'ESP32 device est actif dans le backend

### Problème : Flutter ne peut pas se connecter

- Vérifier l'URL du backend dans les paramètres
- Vérifier les identifiants de connexion
- Vérifier que le backend est accessible depuis le téléphone

## 7. Avantages du mode serveur

- ✅ Multi-utilisateurs : plusieurs téléphones peuvent se connecter
- ✅ Données centralisées : toutes les données sur le serveur
- ✅ Accès à distance : possible si le backend est accessible via Internet
- ✅ Historique complet : toutes les données stockées sur le serveur
- ✅ Sécurité renforcée : API Key + JWT
