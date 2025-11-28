class MaintenanceReport {
  final int? id;
  final int taskId;
  final String summary;
  final String? details;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime createdAt;

  MaintenanceReport({
    this.id,
    required this.taskId,
    required this.summary,
    this.details,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'summary': summary,
      'details': details,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MaintenanceReport.fromMap(Map<String, dynamic> map) {
    return MaintenanceReport(
      id: map['id'] as int?,
      taskId: map['task_id'] as int,
      summary: map['summary'] as String,
      details: map['details'] as String?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
