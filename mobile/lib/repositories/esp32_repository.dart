import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/telemetry.dart';
import '../core/constants/app_constants.dart';

class Esp32Repository {
  final String baseUrl;

  Esp32Repository({required this.baseUrl});

  Future<Map<String, dynamic>?> getMotorStatus({
    String? esp32Uid,
    String? motorCode,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/motor/status');
      final queryParams = <String, String>{};
      if (esp32Uid != null) queryParams['esp32_uid'] = esp32Uid;
      if (motorCode != null) queryParams['motor_code'] = motorCode;

      final response = await http
          .get(uri.replace(queryParameters: queryParams))
          .timeout(AppConstants.connectionTimeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> sendMotorCommand({
    required String action, // "START" ou "STOP"
    double? targetSpeedRpm,
    String? esp32Uid,
    String? motorCode,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/motor/command');
      final queryParams = <String, String>{};
      if (esp32Uid != null) queryParams['esp32_uid'] = esp32Uid;
      if (motorCode != null) queryParams['motor_code'] = motorCode;

      final body = json.encode({
        'action': action,
        if (targetSpeedRpm != null) 'target_speed_rpm': targetSpeedRpm,
      });

      final response = await http
          .post(
            uri.replace(queryParameters: queryParams),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(AppConstants.connectionTimeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/api/health');
      final response =
          await http.get(uri).timeout(AppConstants.connectionTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Telemetry? parseStatusToTelemetry(Map<String, dynamic> status, int motorId) {
    try {
      return Telemetry(
        motorId: motorId,
        temperature: (status['temperature'] as num).toDouble(),
        vibration: (status['vibration'] as num).toDouble(),
        current: (status['current'] as num).toDouble(),
        speedRpm: (status['speed_rpm'] as num).toDouble(),
        isRunning: status['is_running'] as bool,
        batteryPercent: status['battery_percent'] != null
            ? (status['battery_percent'] as num).toDouble()
            : null,
        createdAt: DateTime.parse(status['timestamp'] as String),
      );
    } catch (e) {
      return null;
    }
  }
}
