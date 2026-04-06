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
  final String? hostelName;
  final String? roomNo;
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
    this.hostelName,
    this.roomNo,
    this.emailVerified = false,
    this.emailVerifiedAt,
    required this.createdAt,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'student',
      departmentId: json['department_id']?.toString(),
      classId: json['class_id']?.toString(),
      semester: json['semester'] is int ? json['semester'] : int.tryParse(json['semester']?.toString() ?? ''),
      section: json['section']?.toString(),
      homeAddress: json['home_address']?.toString(),
      hostelName: json['hostel_name']?.toString(),
      roomNo: json['room_no']?.toString(),
      emailVerified: json['email_verified'] == true,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'].toString())
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
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
      'hostel_name': hostelName,
      'room_no': roomNo,
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
