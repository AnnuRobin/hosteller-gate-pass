import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF8B5CF6);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color backgroundColor = Color(0xFFF9FAFB);
  
  // Status colors
  static const Color pendingColor = Color(0xFFF59E0B);
  static const Color approvedColor = Color(0xFF10B981);
  static const Color rejectedColor = Color(0xFFEF4444);
  
  // Roles
  static const String roleStudent = 'student';
  static const String roleAdvisor = 'advisor';
  static const String roleHod = 'hod';
  static const String roleParent = 'parent';
  
  // Status
  static const String statusPending = 'pending';
  static const String statusAdvisorApproved = 'advisor_approved';
  static const String statusHodApproved = 'hod_approved';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
}

// ============================================
// FILE: lib/models/user_model.dart
// ============================================
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