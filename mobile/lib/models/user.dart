class User {
  final int? id;
  final String fullName;
  final String email;
  final String password; // En production, ne jamais stocker en clair
  final String role; // "ADMIN" ou "TECHNICIAN"
  final bool isActive;
  final DateTime createdAt;

  User({
    this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'password': password,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      role: map['role'] as String,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  User copyWith({
    int? id,
    String? fullName,
    String? email,
    String? password,
    String? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
