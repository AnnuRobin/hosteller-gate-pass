class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final String? departmentId;
  final String? classId;
  final int? semester;
  final String? section;
  final String? homeAddress;
  final bool emailVerified;
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;
  
  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.departmentId,
    this.classId,
    this.semester,
    this.section,
    this.homeAddress,
    this.emailVerified = false,
    this.emailVerifiedAt,
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
      semester: json['semester'] as int?,
      section: json['section'] as String?,
      homeAddress: json['home_address'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'] as String)
          : null,
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
      'semester': semester,
      'section': section,
      'home_address': homeAddress,
      'email_verified': emailVerified,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  String get roleDisplayName {
    switch (role) {
      case 'student':
        return 'Student';
      case 'advisor':
        return 'Advisor';
      case 'hod':
        return 'HOD';
      case 'warden':
        return 'Warden';
      case 'admin':
        return 'Admin';
      case 'parent':
        return 'Parent';
      default:
        return role;
    }
  }
}
