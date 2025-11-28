class Telemetry {
  final int? id;
  final int motorId;
  final double temperature;
  final double vibration;
  final double current;
  final double speedRpm;
  final bool isRunning;
  final double? batteryPercent;
  final DateTime createdAt;

  Telemetry({
    this.id,
    required this.motorId,
    required this.temperature,
    required this.vibration,
    required this.current,
    required this.speedRpm,
    required this.isRunning,
    this.batteryPercent,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'motor_id': motorId,
      'temperature': temperature,
      'vibration': vibration,
      'current': current,
      'speed_rpm': speedRpm,
      'is_running': isRunning ? 1 : 0,
      'battery_percent': batteryPercent,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Telemetry.fromMap(Map<String, dynamic> map) {
    return Telemetry(
      id: map['id'] as int?,
      motorId: map['motor_id'] as int,
      temperature: map['temperature'] as double,
      vibration: map['vibration'] as double,
      current: map['current'] as double,
      speedRpm: map['speed_rpm'] as double,
      isRunning: (map['is_running'] as int) == 1,
      batteryPercent: map['battery_percent'] as double?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
