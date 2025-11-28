class MaintenanceTask {
  final int? id;
  final int motorId;
  final int assignedToUserId;
  final int createdByUserId;
  final String title;
  final String? description;
  final DateTime scheduledDate;
  final String status; // "PLANNED", "IN_PROGRESS", "DONE", "CANCELLED"
  final DateTime createdAt;
  final DateTime? updatedAt;

  MaintenanceTask({
    this.id,
    required this.motorId,
    required this.assignedToUserId,
    required this.createdByUserId,
    required this.title,
    this.description,
    required this.scheduledDate,
    this.status = "PLANNED",
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'motor_id': motorId,
      'assigned_to_user_id': assignedToUserId,
      'created_by_user_id': createdByUserId,
      'title': title,
      'description': description,
      'scheduled_date': scheduledDate.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory MaintenanceTask.fromMap(Map<String, dynamic> map) {
    return MaintenanceTask(
      id: map['id'] as int?,
      motorId: map['motor_id'] as int,
      assignedToUserId: map['assigned_to_user_id'] as int,
      createdByUserId: map['created_by_user_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      scheduledDate: DateTime.parse(map['scheduled_date'] as String),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  MaintenanceTask copyWith({
    int? id,
    int? motorId,
    int? assignedToUserId,
    int? createdByUserId,
    String? title,
    String? description,
    DateTime? scheduledDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceTask(
      id: id ?? this.id,
      motorId: motorId ?? this.motorId,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
