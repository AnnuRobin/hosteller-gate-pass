class GatePassModel {
  final String id;
  final String studentId;
  final String? studentName;
  final String classId;
  final String? className;
  final String departmentId;
  final String? departmentName;
  final String reason;
  final String destination;
  final DateTime fromDate;
  final DateTime toDate;
  final String status;
  final String advisorStatus;
  final String hodStatus;
  final String wardenStatus;
  final bool parentNotified;
  final String? advisorId;
  final DateTime? advisorApprovedAt;
  final String? advisorRemarks;
  final String? hodId;
  final DateTime? hodApprovedAt;
  final String? hodRemarks;
  final String? wardenId;
  final DateTime? wardenApprovedAt;
  final DateTime? exitTime;
  final DateTime? entryTime;
  final String? wardenRemarks;
  final String? finalStatus; // 'granted' or 'denied'
  final String parentApprovalStatus; // 'pending', 'approved', 'rejected'
  final DateTime? parentApprovedAt;
  final String? parentRemarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  GatePassModel({
    required this.id,
    required this.studentId,
    this.studentName,
    required this.classId,
    this.className,
    required this.departmentId,
    this.departmentName,
    required this.reason,
    required this.destination,
    required this.fromDate,
    required this.toDate,
    required this.status,
    required this.advisorStatus,
    required this.hodStatus,
    this.wardenStatus = 'pending',
    required this.parentNotified,
    this.advisorId,
    this.advisorApprovedAt,
    this.advisorRemarks,
    this.hodId,
    this.hodApprovedAt,
    this.hodRemarks,
    this.wardenId,
    this.wardenApprovedAt,
    this.exitTime,
    this.entryTime,
    this.wardenRemarks,
    this.finalStatus,
    this.parentApprovalStatus = 'pending',
    this.parentApprovedAt,
    this.parentRemarks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GatePassModel.fromJson(Map<String, dynamic> json) {
    return GatePassModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String?,
      classId: json['class_id'] as String,
      className: json['class_name'] as String?,
      departmentId: json['department_id'] as String,
      departmentName: json['department_name'] as String?,
      reason: json['reason'] as String,
      destination: json['destination'] as String,
      fromDate: DateTime.parse(json['from_date'] as String),
      toDate: DateTime.parse(json['to_date'] as String),
      status: json['status'] as String,
      advisorStatus: json['advisor_status'] as String? ?? 'pending',
      hodStatus: json['hod_status'] as String? ?? 'pending',
      wardenStatus: json['warden_status'] as String? ?? 'pending',
      parentNotified: json['parent_notified'] as bool? ?? false,
      advisorId: json['advisor_id'] as String?,
      advisorApprovedAt: json['advisor_approved_at'] != null
          ? DateTime.parse(json['advisor_approved_at'] as String)
          : null,
      advisorRemarks: json['advisor_remarks'] as String?,
      hodId: json['hod_id'] as String?,
      hodApprovedAt: json['hod_approved_at'] != null
          ? DateTime.parse(json['hod_approved_at'] as String)
          : null,
      hodRemarks: json['hod_remarks'] as String?,
      wardenId: json['warden_id'] as String?,
      wardenApprovedAt: json['warden_approved_at'] != null
          ? DateTime.parse(json['warden_approved_at'] as String)
          : null,
      exitTime: json['exit_time'] != null
          ? DateTime.parse(json['exit_time'] as String)
          : null,
      entryTime: json['entry_time'] != null
          ? DateTime.parse(json['entry_time'] as String)
          : null,
      wardenRemarks: json['warden_remarks'] as String?,
      finalStatus: json['final_status'] as String?,
      parentApprovalStatus: json['parent_approval_status'] as String? ?? 'pending',
      parentApprovedAt: json['parent_approved_at'] != null
          ? DateTime.parse(json['parent_approved_at'] as String)
          : null,
      parentRemarks: json['parent_remarks'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'class_id': classId,
      'class_name': className,
      'department_id': departmentId,
      'department_name': departmentName,
      'reason': reason,
      'destination': destination,
      'from_date': fromDate.toIso8601String(),
      'to_date': toDate.toIso8601String(),
      'status': status,
      'advisor_status': advisorStatus,
      'hod_status': hodStatus,
      'warden_status': wardenStatus,
      'parent_notified': parentNotified,
      'advisor_id': advisorId,
      'advisor_approved_at': advisorApprovedAt?.toIso8601String(),
      'advisor_remarks': advisorRemarks,
      'hod_id': hodId,
      'hod_approved_at': hodApprovedAt?.toIso8601String(),
      'hod_remarks': hodRemarks,
      'warden_id': wardenId,
      'warden_approved_at': wardenApprovedAt?.toIso8601String(),
      'exit_time': exitTime?.toIso8601String(),
      'entry_time': entryTime?.toIso8601String(),
      'warden_remarks': wardenRemarks,
      'final_status': finalStatus,
      'parent_approval_status': parentApprovalStatus,
      'parent_approved_at': parentApprovedAt?.toIso8601String(),
      'parent_remarks': parentRemarks,
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
