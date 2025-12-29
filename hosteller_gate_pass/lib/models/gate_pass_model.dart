class GatePassModel {
  final String id;
  final String studentId;
  final String classId;
  final String departmentId;
  final String reason;
  final String destination;
  final DateTime fromDate;
  final DateTime toDate;
  final String status;
  final String advisorStatus;
  final String hodStatus;
  final bool parentNotified;
  final String? advisorId;
  final DateTime? advisorApprovedAt;
  final String? advisorRemarks;
  final String? hodId;
  final DateTime? hodApprovedAt;
  final String? hodRemarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  GatePassModel({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.departmentId,
    required this.reason,
    required this.destination,
    required this.fromDate,
    required this.toDate,
    required this.status,
    required this.advisorStatus,
    required this.hodStatus,
    required this.parentNotified,
    this.advisorId,
    this.advisorApprovedAt,
    this.advisorRemarks,
    this.hodId,
    this.hodApprovedAt,
    this.hodRemarks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GatePassModel.fromJson(Map<String, dynamic> json) {
    return GatePassModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      classId: json['class_id'] as String,
      departmentId: json['department_id'] as String,
      reason: json['reason'] as String,
      destination: json['destination'] as String,
      fromDate: DateTime.parse(json['from_date'] as String),
      toDate: DateTime.parse(json['to_date'] as String),
      status: json['status'] as String,
      advisorStatus: json['advisor_status'] as String? ?? 'pending',
      hodStatus: json['hod_status'] as String? ?? 'pending',
      parentNotified: json['parent_notified'] as bool? ?? false,
      advisorId: json['advisor_id'] as String?,
      advisorApprovedAt:
          json['advisor_approved_at'] != null
              ? DateTime.parse(json['advisor_approved_at'] as String)
              : null,
      advisorRemarks: json['advisor_remarks'] as String?,
      hodId: json['hod_id'] as String?,
      hodApprovedAt:
          json['hod_approved_at'] != null
              ? DateTime.parse(json['hod_approved_at'] as String)
              : null,
      hodRemarks: json['hod_remarks'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'class_id': classId,
      'department_id': departmentId,
      'reason': reason,
      'destination': destination,
      'from_date': fromDate.toIso8601String(),
      'to_date': toDate.toIso8601String(),
      'status': status,
      'advisor_status': advisorStatus,
      'hod_status': hodStatus,
      'parent_notified': parentNotified,
      'advisor_id': advisorId,
      'advisor_approved_at': advisorApprovedAt?.toIso8601String(),
      'advisor_remarks': advisorRemarks,
      'hod_id': hodId,
      'hod_approved_at': hodApprovedAt?.toIso8601String(),
      'hod_remarks': hodRemarks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String getStatusText() {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'advisor_approved':
        return 'Advisor Approved';
      case 'hod_approved':
        return 'HOD Approved';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }
}
