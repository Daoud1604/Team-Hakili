# Endpoints ESP32 - Documentation pour le firmware

Cette documentation décrit les endpoints HTTP que le firmware ESP32 doit exposer pour communiquer avec l'application Flutter MotorGuard.

## Configuration réseau

- **Mode** : Access Point (AP)
- **SSID par défaut** : `MotorGuard_AP`
- **Mot de passe par défaut** : `motorguard123`
- **IP ESP32** : `192.168.4.1` (IP typique en mode AP)

## Base URL

```
http://192.168.4.1
```

## Endpoints

### 1. Health Check

Vérifie que l'ESP32 est accessible et fonctionne.

**Endpoint** : `GET /api/health`

**Réponse** :

```json
{
  "status": "ok"
}
```

**Code de statut** : `200 OK`

**Exemple de requête** :

```bash
curl http://192.168.4.1/api/health
```

---

### 2. Obtenir l'état du moteur

Récupère l'état actuel du moteur (télémétrie en temps réel).

**Endpoint** : `GET /api/motor/status`

**Paramètres de requête (optionnels)** :

- `esp32_uid` (string) : Identifiant unique de l'ESP32 (ex: "ESP32_001")
- `motor_code` (string) : Code du moteur (ex: "M001")

**Réponse** :

```json
{
  "esp32_uid": "ESP32_001",
  "motor_code": "M001",
  "temperature": 55.0,
  "vibration": 2.4,
  "current": 12.5,
  "speed_rpm": 1450,
  "is_running": true,
  "battery_percent": 87.0,
  "timestamp": "2025-11-24T12:34:56Z"
}
```

**Champs de la réponse** :

- `esp32_uid` (string) : Identifiant unique de l'ESP32
- `motor_code` (string) : Code du moteur associé
- `temperature` (float) : Température en degrés Celsius
- `vibration` (float) : Vibration en mm/s
- `current` (float) : Courant en ampères
- `speed_rpm` (float) : Vitesse en tours par minute
- `is_running` (boolean) : État du moteur (true = en marche, false = arrêté)
- `battery_percent` (float, optionnel) : Pourcentage de batterie (0-100)
- `timestamp` (string ISO 8601) : Date et heure de la mesure

**Code de statut** : `200 OK`

**Exemple de requête** :

```bash
curl "http://192.168.4.1/api/motor/status?esp32_uid=ESP32_001"
```

**Exemple de requête avec code moteur** :

```bash
curl "http://192.168.4.1/api/motor/status?motor_code=M001"
```

---

### 3. Envoyer une commande au moteur

Envoie une commande de démarrage ou d'arrêt au moteur.

**Endpoint** : `POST /api/motor/command`

**Paramètres de requête (optionnels)** :

- `esp32_uid` (string) : Identifiant unique de l'ESP32
- `motor_code` (string) : Code du moteur

**Body (JSON)** :

```json
{
  "action": "START",
  "target_speed_rpm": 1500.0
}
```

**Champs du body** :

- `action` (string, requis) : Action à effectuer
  - `"START"` : Démarrer le moteur
  - `"STOP"` : Arrêter le moteur
- `target_speed_rpm` (float, optionnel) : Vitesse cible en RPM (requis si action = "START")
  - Plage recommandée : 540 - 1800 RPM

**Réponse** :

```json
{
  "status": "ok"
}
```

**Code de statut** : `200 OK` (succès) ou `400 Bad Request` (erreur)

**Exemple de requête (démarrage)** :

```bash
curl -X POST "http://192.168.4.1/api/motor/command?esp32_uid=ESP32_001" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "START",
    "target_speed_rpm": 1500.0
  }'
```

**Exemple de requête (arrêt)** :

```bash
curl -X POST "http://192.168.4.1/api/motor/command?esp32_uid=ESP32_001" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "STOP"
  }'
```

---

## Implémentation côté ESP32

### Exemple de structure (Arduino/ESP-IDF)

```cpp
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

WebServer server(80);

// Variables d'état du moteur
String esp32_uid = "ESP32_001";
String motor_code = "M001";
float temperature = 0.0;
float vibration = 0.0;
float current = 0.0;
float speed_rpm = 0.0;
bool is_running = false;
float battery_percent = 100.0;

void handleHealth() {
  server.send(200, "application/json", "{\"status\":\"ok\"}");
}

void handleMotorStatus() {
  DynamicJsonDocument doc(512);
  doc["esp32_uid"] = esp32_uid;
  doc["motor_code"] = motor_code;
  doc["temperature"] = temperature;
  doc["vibration"] = vibration;
  doc["current"] = current;
  doc["speed_rpm"] = speed_rpm;
  doc["is_running"] = is_running;
  doc["battery_percent"] = battery_percent;
  doc["timestamp"] = getCurrentTimestamp(); // Fonction à implémenter

  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

void handleMotorCommand() {
  if (server.hasArg("plain")) {
    DynamicJsonDocument doc(512);
    deserializeJson(doc, server.arg("plain"));

    String action = doc["action"];

    if (action == "START") {
      float target_speed = doc["target_speed_rpm"];
      // Implémenter la logique de démarrage
      is_running = true;
      speed_rpm = target_speed;
      // Contrôler le GPIO/relais pour démarrer le moteur
    } else if (action == "STOP") {
      // Implémenter la logique d'arrêt
      is_running = false;
      speed_rpm = 0.0;
      // Contrôler le GPIO/relais pour arrêter le moteur
    }

    server.send(200, "application/json", "{\"status\":\"ok\"}");
  } else {
    server.send(400, "application/json", "{\"error\":\"Invalid request\"}");
  }
}

void setup() {
  // Configuration du Wi-Fi en mode AP
  WiFi.softAP("MotorGuard_AP", "motorguard123");
  IPAddress IP = WiFi.softAPIP();
  Serial.print("AP IP address: ");
  Serial.println(IP);

  // Configuration des routes
  server.on("/api/health", handleHealth);
  server.on("/api/motor/status", handleMotorStatus);
  server.on("/api/motor/command", HTTP_POST, handleMotorCommand);

  server.begin();
}

void loop() {
  server.handleClient();
  // Lire les capteurs et mettre à jour les variables
  // temperature = readTemperature();
  // vibration = readVibration();
  // current = readCurrent();
  // speed_rpm = readSpeedRPM();
}
```

---

## Notes importantes

1. **Format de date** : Utiliser le format ISO 8601 pour les timestamps (ex: "2025-11-24T12:34:56Z")

2. **Gestion des erreurs** : En cas d'erreur, retourner un code HTTP approprié (400, 404, 500) avec un message JSON :

   ```json
   {
     "error": "Description de l'erreur"
   }
   ```

3. **Timeout** : L'application Flutter attend une réponse dans les 5 secondes. Assurez-vous que les endpoints répondent rapidement.

4. **CORS** : Si nécessaire, ajouter les en-têtes CORS pour permettre les requêtes depuis l'application mobile.

5. **Sécurité** : En production, considérer l'ajout d'une authentification (token, API key) pour sécuriser les endpoints.

---

## Tests

Pour tester les endpoints avant l'intégration avec l'application Flutter :

```bash
# Test health
curl http://192.168.4.1/api/health

# Test status
curl "http://192.168.4.1/api/motor/status?esp32_uid=ESP32_001"

# Test command START
curl -X POST "http://192.168.4.1/api/motor/command" \
  -H "Content-Type: application/json" \
  -d '{"action":"START","target_speed_rpm":1500}'

# Test command STOP
curl -X POST "http://192.168.4.1/api/motor/command" \
  -H "Content-Type: application/json" \
  -d '{"action":"STOP"}'
```
