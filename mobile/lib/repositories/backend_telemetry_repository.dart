import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/telemetry.dart';

class BackendTelemetryRepository {
  final String baseUrl;
  final String? authToken;
  final bool allowSelfSignedCert;
  late http.Client _client;

  BackendTelemetryRepository({
    required this.baseUrl,
    this.authToken,
    this.allowSelfSignedCert = false,
  }) {
    if (allowSelfSignedCert) {
      final ioClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      _client = IOClient(ioClient);
    } else {
      _client = http.Client();
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  Future<List<Telemetry>> getMotorTelemetry(
    int motorId, {
    int limit = 100,
    int hours = 24,
  }) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/telemetry/motor/$motorId?limit=$limit&hours=$hours');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => _telemetryFromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Telemetry?> createTelemetry(Telemetry telemetry) async {
    try {
      final uri = Uri.parse('$baseUrl/telemetry/');
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: json.encode(_telemetryToJson(telemetry)),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return _telemetryFromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Telemetry _telemetryFromJson(Map<String, dynamic> json) {
    return Telemetry(
      id: json['id'],
      motorId: json['motor_id'],
      temperature: json['temperature'].toDouble(),
      vibration: json['vibration'].toDouble(),
      current: json['current'].toDouble(),
      speedRpm: json['speed_rpm'].toDouble(),
      isRunning: json['is_running'],
      batteryPercent: json['battery_percent']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> _telemetryToJson(Telemetry telemetry) {
    return {
      'motor_id': telemetry.motorId,
      'temperature': telemetry.temperature,
      'vibration': telemetry.vibration,
      'current': telemetry.current,
      'speed_rpm': telemetry.speedRpm,
      'is_running': telemetry.isRunning,
      'battery_percent': telemetry.batteryPercent,
    };
  }

  void dispose() {
    _client.close();
  }
}
