import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/motor.dart';

class BackendMotorRepository {
  final String baseUrl;
  final String? authToken;
  final bool allowSelfSignedCert;
  late http.Client _client;

  BackendMotorRepository({
    required this.baseUrl,
    this.authToken,
    this.allowSelfSignedCert = false,
  }) {
    if (allowSelfSignedCert) {
      // ⚠️ Pour certificat auto-signé en développement uniquement
      final ioClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      _client = IOClient(ioClient);
    } else {
      _client = http.Client(); // Utilise les certificats système
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  Future<List<Motor>> getAllMotors() async {
    try {
      final uri = Uri.parse('$baseUrl/motors/');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => _motorFromJson(json)).toList();
      }
      throw Exception('Failed to load motors: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error loading motors: $e');
    }
  }

  Future<Motor?> getMotorById(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/motors/$id');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _motorFromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Motor> createMotor(Motor motor) async {
    try {
      final uri = Uri.parse('$baseUrl/motors/');
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: json.encode(_motorToJson(motor)),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return _motorFromJson(data);
      }
      throw Exception('Failed to create motor: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error creating motor: $e');
    }
  }

  Future<Motor> updateMotor(Motor motor) async {
    try {
      final uri = Uri.parse('$baseUrl/motors/${motor.id}');
      final response = await _client
          .put(
            uri,
            headers: _headers,
            body: json.encode(_motorToJson(motor)),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _motorFromJson(data);
      }
      throw Exception('Failed to update motor: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error updating motor: $e');
    }
  }

  Future<bool> deleteMotor(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/motors/$id');
      final response = await _client
          .delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getMotorStatus(int motorId) async {
    try {
      final uri = Uri.parse('$baseUrl/telemetry/motor/$motorId?limit=1');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> sendMotorCommand(int motorId, String action,
      {double? targetSpeedRpm}) async {
    try {
      final uri = Uri.parse('$baseUrl/iot/motor/command?motor_id=$motorId');
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: json.encode({
              'action': action,
              if (targetSpeedRpm != null) 'target_speed_rpm': targetSpeedRpm,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Motor _motorFromJson(Map<String, dynamic> json) {
    return Motor(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      location: json['location'],
      description: json['description'],
      esp32Uid: json['esp32_uid'],
      isRunning: json['is_running'] ?? false,
      lastTemperature: json['last_temperature']?.toDouble(),
      lastVibration: json['last_vibration']?.toDouble(),
      lastCurrent: json['last_current']?.toDouble(),
      lastSpeedRpm: json['last_speed_rpm']?.toDouble(),
      lastBatteryPercent: json['last_battery_percent']?.toDouble(),
      lastUpdate: json['last_update'] != null
          ? DateTime.parse(json['last_update'])
          : null,
    );
  }

  Map<String, dynamic> _motorToJson(Motor motor) {
    return {
      'name': motor.name,
      'code': motor.code,
      'location': motor.location,
      'description': motor.description,
      'esp32_uid': motor.esp32Uid,
    };
  }

  void dispose() {
    _client.close();
  }
}
