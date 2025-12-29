class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final String? departmentId;
  final String? classId;
  final DateTime createdAt;
  
  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.departmentId,
    this.classId,
    required this.createdAt,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      departmentId: json['department_id'] as String?,
      classId: json['class_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'department_id': departmentId,
      'class_id': classId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}