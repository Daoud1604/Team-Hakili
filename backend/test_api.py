#!/usr/bin/env python3
"""
Script de test pour l'API MotorGuard
Usage: python test_api.py
"""

import requests
import json
import sys
from datetime import datetime

BASE_URL = "http://localhost:8000"

def print_section(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")

def test_health():
    """Test 1: Health Check"""
    print_section("1. Health Check")
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

def test_login():
    """Test 2: Login"""
    print_section("2. Login")
    try:
        response = requests.post(
            f"{BASE_URL}/auth/login-json",
            json={
                "email": "admin@motorguard.local",
                "password": "admin123"
            },
            timeout=5
        )
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            token = data.get("access_token")
            print(f"✅ Token obtenu: {token[:20]}...")
            return token
        else:
            print(f"❌ Erreur: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return None

def test_create_motor(token):
    """Test 3: Créer un moteur"""
    print_section("3. Créer un moteur")
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.post(
            f"{BASE_URL}/motors/",
            headers=headers,
            json={
                "name": "Broyeur Principal",
                "code": "M001",
                "location": "Atelier 3",
                "description": "Broyeur principal de production",
                "esp32_uid": "ESP32_001"
            },
            timeout=5
        )
        print(f"Status: {response.status_code}")
        if response.status_code in [200, 201]:
            print(f"✅ Moteur créé:")
            print(json.dumps(response.json(), indent=2))
            return response.json().get("id")
        else:
            print(f"⚠️  Réponse: {response.text}")
            # Peut-être que le moteur existe déjà, on continue
            return 1
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return None

def test_list_motors(token):
    """Test 4: Lister les moteurs"""
    print_section("4. Lister les moteurs")
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.get(f"{BASE_URL}/motors/", headers=headers, timeout=5)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            motors = response.json()
            print(f"✅ {len(motors)} moteur(s) trouvé(s):")
            for motor in motors:
                print(f"  - {motor.get('name')} (ID: {motor.get('id')}, Code: {motor.get('code')})")
            return motors[0].get("id") if motors else None
        else:
            print(f"❌ Erreur: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return None

def test_create_esp32_device(token, motor_id):
    """Test 5: Créer un ESP32 device"""
    print_section("5. Créer un ESP32 device")
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.post(
            f"{BASE_URL}/esp32-devices/",
            headers=headers,
            json={
                "esp32_uid": "ESP32_001",
                "motor_id": motor_id
            },
            timeout=5
        )
        print(f"Status: {response.status_code}")
        if response.status_code in [200, 201]:
            data = response.json()
            api_key = data.get("api_key")
            print(f"✅ ESP32 device créé:")
            print(f"  - ID: {data.get('id')}")
            print(f"  - UID: {data.get('esp32_uid')}")
            print(f"  - API Key: {api_key[:30]}...")
            return api_key
        else:
            print(f"⚠️  Réponse: {response.text}")
            # Peut-être que le device existe déjà, on récupère l'API key
            # En production, on devrait faire un GET pour récupérer l'API key
            return "EXISTING_DEVICE"
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return None

def test_send_telemetry(api_key, motor_id):
    """Test 6: Envoyer de la télémétrie (simuler ESP32)"""
    print_section("6. Envoyer de la télémétrie (simuler ESP32)")
    if api_key == "EXISTING_DEVICE":
        print("⚠️  Impossible de tester sans API Key valide")
        return False
    
    try:
        headers = {"X-API-Key": api_key, "Content-Type": "application/json"}
        response = requests.post(
            f"{BASE_URL}/iot/telemetry/from-esp32",
            headers=headers,
            json={
                "motor_id": motor_id,
                "temperature": 55.5,
                "vibration": 2.4,
                "current": 12.5,
                "speed_rpm": 1450,
                "is_running": True,
                "battery_percent": 87.0
            },
            timeout=5
        )
        print(f"Status: {response.status_code}")
        if response.status_code in [200, 201]:
            print(f"✅ Télémétrie envoyée:")
            print(json.dumps(response.json(), indent=2))
            return True
        else:
            print(f"❌ Erreur: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

def test_get_telemetry(token, motor_id):
    """Test 7: Récupérer la télémétrie"""
    print_section("7. Récupérer la télémétrie")
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.get(
            f"{BASE_URL}/telemetry/motor/{motor_id}?limit=5",
            headers=headers,
            timeout=5
        )
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            telemetry = response.json()
            print(f"✅ {len(telemetry)} point(s) de télémétrie trouvé(s):")
            for tel in telemetry[:3]:  # Afficher les 3 premiers
                print(f"  - Temp: {tel.get('temperature')}°C, "
                      f"RPM: {tel.get('speed_rpm')}, "
                      f"Running: {tel.get('is_running')}")
            return True
        else:
            print(f"❌ Erreur: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

def test_send_command(token, motor_id):
    """Test 8: Envoyer une commande"""
    print_section("8. Envoyer une commande START")
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.post(
            f"{BASE_URL}/iot/motor/command?motor_id={motor_id}",
            headers=headers,
            json={
                "action": "START",
                "target_speed_rpm": 1500
            },
            timeout=5
        )
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            print(f"✅ Commande envoyée:")
            print(json.dumps(response.json(), indent=2))
            return True
        else:
            print(f"❌ Erreur: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

def main():
    print("\n" + "="*60)
    print("  TEST DE L'API MOTORGUARD")
    print("="*60)
    print(f"\nBase URL: {BASE_URL}")
    print(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Test 1: Health Check
    if not test_health():
        print("\n❌ Le serveur n'est pas accessible. Assurez-vous qu'il est lancé.")
        print("   Commande: cd backend && uvicorn app.main:app --reload")
        sys.exit(1)
    
    # Test 2: Login
    token = test_login()
    if not token:
        print("\n❌ Impossible de se connecter. Vérifiez les identifiants.")
        sys.exit(1)
    
    # Test 3: Créer un moteur
    motor_id = test_create_motor(token)
    if not motor_id:
        motor_id = 1  # Utiliser l'ID 1 par défaut
    
    # Test 4: Lister les moteurs
    motor_id = test_list_motors(token) or motor_id
    
    # Test 5: Créer un ESP32 device
    api_key = test_create_esp32_device(token, motor_id)
    
    # Test 6: Envoyer de la télémétrie
    if api_key and api_key != "EXISTING_DEVICE":
        test_send_telemetry(api_key, motor_id)
    
    # Test 7: Récupérer la télémétrie
    test_get_telemetry(token, motor_id)
    
    # Test 8: Envoyer une commande
    test_send_command(token, motor_id)
    
    # Résumé
    print_section("RÉSUMÉ")
    print("✅ Tests terminés !")
    print("\nPour plus d'informations, consultez:")
    print(f"  - Swagger UI: {BASE_URL}/docs")
    print(f"  - ReDoc: {BASE_URL}/redoc")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Tests interrompus par l'utilisateur")
        sys.exit(0)
    except Exception as e:
        print(f"\n\n❌ Erreur inattendue: {e}")
        sys.exit(1)

