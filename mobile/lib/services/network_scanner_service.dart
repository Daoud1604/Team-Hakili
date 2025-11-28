import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class Esp32Device {
  final String ip;
  final String url;
  final String? hostname;
  final bool isReachable;

  Esp32Device({
    required this.ip,
    required this.url,
    this.hostname,
    required this.isReachable,
  });
}

class NetworkScannerService {
  /// Scanne le réseau local pour trouver des ESP32
  ///
  /// [networkBase] : Base du réseau (ex: "192.168.1")
  /// [startRange] : Première IP à scanner (ex: 1)
  /// [endRange] : Dernière IP à scanner (ex: 254)
  /// [port] : Port à tester (par défaut 80)
  /// [timeout] : Timeout pour chaque requête (par défaut 1 seconde)
  /// [onProgress] : Callback appelé avec le progrès (0.0 à 1.0)
  static Future<List<Esp32Device>> scanNetwork({
    String networkBase = '192.168.1',
    int startRange = 1,
    int endRange = 254,
    int port = 80,
    Duration timeout = const Duration(seconds: 1),
    Function(double)? onProgress,
  }) async {
    final List<Esp32Device> foundDevices = [];
    final total = endRange - startRange + 1;
    int scanned = 0;

    // Créer une liste de futures pour scanner en parallèle (par lots)
    final futures = <Future<void>>[];
    const batchSize = 10; // Scanner 10 IPs en parallèle à la fois

    for (int i = startRange; i <= endRange; i++) {
      final ip = '$networkBase.$i';
      final url = 'http://$ip:$port';

      futures.add(_checkEsp32Device(ip, url, timeout).then((device) {
        scanned++;
        if (onProgress != null) {
          onProgress(scanned / total);
        }
        if (device != null && device.isReachable) {
          foundDevices.add(device);
        }
      }));

      // Exécuter par lots pour ne pas surcharger le réseau
      if (futures.length >= batchSize || i == endRange) {
        await Future.wait(futures);
        futures.clear();
      }
    }

    return foundDevices;
  }

  /// Vérifie si une IP correspond à un ESP32
  static Future<Esp32Device?> _checkEsp32Device(
    String ip,
    String url,
    Duration timeout,
  ) async {
    try {
      // Tester l'endpoint /api/health qui est spécifique à notre ESP32
      final uri = Uri.parse('$url/api/health');
      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        // C'est probablement un ESP32 MotorGuard
        return Esp32Device(
          ip: ip,
          url: url,
          isReachable: true,
        );
      }
    } catch (e) {
      // IP non accessible ou pas un ESP32
    }
    return null;
  }

  /// Détecte automatiquement la base du réseau à partir de l'IP locale
  static Future<String?> detectNetworkBase() async {
    try {
      // Obtenir l'adresse IP locale
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              // Retourner les 3 premiers octets (ex: "192.168.1")
              return '${parts[0]}.${parts[1]}.${parts[2]}';
            }
          }
        }
      }
    } catch (e) {
      // Erreur lors de la détection
    }
    return null;
  }

  /// Scanne le réseau en utilisant la base détectée automatiquement
  static Future<List<Esp32Device>> scanNetworkAuto({
    int startRange = 1,
    int endRange = 254,
    int port = 80,
    Duration timeout = const Duration(seconds: 1),
    Function(double)? onProgress,
  }) async {
    final networkBase = await detectNetworkBase();
    if (networkBase == null) {
      // Si on ne peut pas détecter, utiliser une valeur par défaut
      return scanNetwork(
        networkBase: '192.168.1',
        startRange: startRange,
        endRange: endRange,
        port: port,
        timeout: timeout,
        onProgress: onProgress,
      );
    }

    return scanNetwork(
      networkBase: networkBase,
      startRange: startRange,
      endRange: endRange,
      port: port,
      timeout: timeout,
      onProgress: onProgress,
    );
  }
}
