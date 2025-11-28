#!/usr/bin/env python3
"""
Simulateur ESP32 pour tests sans matériel
Votre PC joue le rôle de l'ESP32
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import random
from datetime import datetime
from urllib.parse import urlparse, parse_qs
import socket

# État simulé du moteur
motor_state = {
    "esp32_uid": "ESP32_001",
    "motor_code": "M001",
    "temperature": 55.0,
    "vibration": 2.4,
    "current": 12.5,
    "speed_rpm": 1450.0,
    "is_running": True,
    "battery_percent": 87.0,
}

class ESP32SimulatorHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed_path = urlparse(self.path)
        
        # Health check - utilisé par le scan réseau
        if parsed_path.path == "/api/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok"}).encode())
            return
        
        # Motor status - récupère l'état du moteur
        elif parsed_path.path == "/api/motor/status":
            # Simuler des variations aléatoires réalistes
            if motor_state["is_running"]:
                motor_state["temperature"] = round(50 + random.uniform(-5, 15), 1)
                motor_state["vibration"] = round(2.0 + random.uniform(-0.5, 2.0), 1)
                motor_state["current"] = round(10 + random.uniform(-2, 8), 1)
                motor_state["speed_rpm"] = round(1400 + random.uniform(-50, 100), 1)
            else:
                motor_state["temperature"] = round(25 + random.uniform(-2, 5), 1)
                motor_state["vibration"] = round(0.1 + random.uniform(-0.05, 0.1), 1)
                motor_state["current"] = 0.0
                motor_state["speed_rpm"] = 0.0
            
            motor_state["battery_percent"] = round(
                max(0, motor_state["battery_percent"] - random.uniform(0, 0.2)), 1
            )
            motor_state["timestamp"] = datetime.utcnow().isoformat() + "Z"
            
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps(motor_state).encode())
            return
        
        # Route non trouvée
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Not Found")
    
    def do_POST(self):
        parsed_path = urlparse(self.path)
        
        # Motor command - contrôle le moteur
        if parsed_path.path == "/api/motor/command":
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length)
            
            try:
                data = json.loads(body.decode())
                action = data.get("action")
                
                if action == "START":
                    motor_state["is_running"] = True
                    motor_state["speed_rpm"] = data.get("target_speed_rpm", 1500.0)
                    print(f"✅ [COMMANDE] Moteur démarré à {motor_state['speed_rpm']} RPM")
                elif action == "STOP":
                    motor_state["is_running"] = False
                    motor_state["speed_rpm"] = 0.0
                    print(f"🛑 [COMMANDE] Moteur arrêté")
                else:
                    self.send_response(400)
                    self.send_header("Content-Type", "application/json")
                    self.end_headers()
                    self.wfile.write(json.dumps({"error": "Invalid action"}).encode())
                    return
                
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(json.dumps({"status": "ok"}).encode())
                
            except json.JSONDecodeError:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b"Invalid JSON")
            return
        
        # Route non trouvée
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Not Found")
    
    def log_message(self, format, *args):
        # Logs personnalisés
        print(f"[ESP32 Sim] {args[0]}")

def get_local_ip():
    """Trouve l'IP locale du PC"""
    try:
        # Se connecter à une adresse externe pour déterminer l'interface locale
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"

def run(server_class=HTTPServer, handler_class=ESP32SimulatorHandler, port=8001):
    server_address = ("0.0.0.0", port)  # 0.0.0.0 = écouter sur toutes les interfaces
    httpd = server_class(server_address, handler_class)
    
    local_ip = get_local_ip()
    
    print("=" * 60)
    print("🚀 SIMULATEUR ESP32 DÉMARRÉ")
    print("=" * 60)
    print(f"📡 IP du PC (ESP32) : {local_ip}")
    print(f"🌐 Port : {port}")
    print(f"\n📋 Endpoints disponibles :")
    print(f"   - GET  http://{local_ip}:{port}/api/health")
    print(f"   - GET  http://{local_ip}:{port}/api/motor/status")
    print(f"   - POST http://{local_ip}:{port}/api/motor/command")
    print(f"\n💡 Configuration dans l'app Flutter :")
    print(f"   - Mode : Local autonome")
    print(f"   - IP ESP32 : {local_ip}")
    print(f"   - Port : {port}")
    print(f"\n⏹️  Appuyez sur Ctrl+C pour arrêter")
    print("=" * 60)
    print()
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\n🛑 Arrêt du simulateur ESP32...")
        httpd.shutdown()

if __name__ == "__main__":
    import sys
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8001
    run(port=port)

