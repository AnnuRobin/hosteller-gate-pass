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

