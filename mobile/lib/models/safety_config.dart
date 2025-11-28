class SafetyConfig {
  final int? id;
  final int motorId;
  final double maxTemperature;
  final double maxVibration;
  final double minBatteryPercent;
  final int emergencyStopDelaySeconds;
  final bool enableSmsAlerts;
  final String? smsPhoneNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SafetyConfig({
    this.id,
    required this.motorId,
    this.maxTemperature = 80.0,
    this.maxVibration = 5.0,
    this.minBatteryPercent = 20.0,
    this.emergencyStopDelaySeconds = 5,
    this.enableSmsAlerts = false,
    this.smsPhoneNumber,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'motor_id': motorId,
      'max_temperature': maxTemperature,
      'max_vibration': maxVibration,
      'min_battery_percent': minBatteryPercent,
      'emergency_stop_delay_seconds': emergencyStopDelaySeconds,
      'enable_sms_alerts': enableSmsAlerts ? 1 : 0,
      'sms_phone_number': smsPhoneNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory SafetyConfig.fromMap(Map<String, dynamic> map) {
    return SafetyConfig(
      id: map['id'] as int?,
      motorId: map['motor_id'] as int,
      maxTemperature: map['max_temperature'] as double,
      maxVibration: map['max_vibration'] as double,
      minBatteryPercent: map['min_battery_percent'] as double,
      emergencyStopDelaySeconds: map['emergency_stop_delay_seconds'] as int,
      enableSmsAlerts: (map['enable_sms_alerts'] as int) == 1,
      smsPhoneNumber: map['sms_phone_number'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  SafetyConfig copyWith({
    int? id,
    int? motorId,
    double? maxTemperature,
    double? maxVibration,
    double? minBatteryPercent,
    int? emergencyStopDelaySeconds,
    bool? enableSmsAlerts,
    String? smsPhoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SafetyConfig(
      id: id ?? this.id,
      motorId: motorId ?? this.motorId,
      maxTemperature: maxTemperature ?? this.maxTemperature,
      maxVibration: maxVibration ?? this.maxVibration,
      minBatteryPercent: minBatteryPercent ?? this.minBatteryPercent,
      emergencyStopDelaySeconds:
          emergencyStopDelaySeconds ?? this.emergencyStopDelaySeconds,
      enableSmsAlerts: enableSmsAlerts ?? this.enableSmsAlerts,
      smsPhoneNumber: smsPhoneNumber ?? this.smsPhoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
