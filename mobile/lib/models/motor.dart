class Motor {
  final int? id;
  final String name;
  final String code;
  final String? location;
  final String? description;
  final String? esp32Uid;
  final bool isRunning;
  final double? lastTemperature;
  final double? lastVibration;
  final double? lastCurrent;
  final double? lastSpeedRpm;
  final double? lastBatteryPercent;
  final DateTime? lastUpdate;

  Motor({
    this.id,
    required this.name,
    required this.code,
    this.location,
    this.description,
    this.esp32Uid,
    this.isRunning = false,
    this.lastTemperature,
    this.lastVibration,
    this.lastCurrent,
    this.lastSpeedRpm,
    this.lastBatteryPercent,
    this.lastUpdate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'location': location,
      'description': description,
      'esp32_uid': esp32Uid,
      'is_running': isRunning ? 1 : 0,
      'last_temperature': lastTemperature,
      'last_vibration': lastVibration,
      'last_current': lastCurrent,
      'last_speed_rpm': lastSpeedRpm,
      'last_battery_percent': lastBatteryPercent,
      'last_update': lastUpdate?.toIso8601String(),
    };
  }

  factory Motor.fromMap(Map<String, dynamic> map) {
    return Motor(
      id: map['id'] as int?,
      name: map['name'] as String,
      code: map['code'] as String,
      location: map['location'] as String?,
      description: map['description'] as String?,
      esp32Uid: map['esp32_uid'] as String?,
      isRunning: (map['is_running'] as int) == 1,
      lastTemperature: map['last_temperature'] as double?,
      lastVibration: map['last_vibration'] as double?,
      lastCurrent: map['last_current'] as double?,
      lastSpeedRpm: map['last_speed_rpm'] as double?,
      lastBatteryPercent: map['last_battery_percent'] as double?,
      lastUpdate: map['last_update'] != null
          ? DateTime.parse(map['last_update'] as String)
          : null,
    );
  }

  Motor copyWith({
    int? id,
    String? name,
    String? code,
    String? location,
    String? description,
    String? esp32Uid,
    bool? isRunning,
    double? lastTemperature,
    double? lastVibration,
    double? lastCurrent,
    double? lastSpeedRpm,
    double? lastBatteryPercent,
    DateTime? lastUpdate,
  }) {
    return Motor(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      location: location ?? this.location,
      description: description ?? this.description,
      esp32Uid: esp32Uid ?? this.esp32Uid,
      isRunning: isRunning ?? this.isRunning,
      lastTemperature: lastTemperature ?? this.lastTemperature,
      lastVibration: lastVibration ?? this.lastVibration,
      lastCurrent: lastCurrent ?? this.lastCurrent,
      lastSpeedRpm: lastSpeedRpm ?? this.lastSpeedRpm,
      lastBatteryPercent: lastBatteryPercent ?? this.lastBatteryPercent,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}
