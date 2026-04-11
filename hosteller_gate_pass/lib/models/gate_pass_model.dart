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
  final String? hostelName; // student's hostel name
  final bool isExpired; // true when pass has been used or toDate has passed
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
    this.hostelName,
    this.isExpired = false,
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
      parentApprovalStatus:
          json['parent_approval_status'] as String? ?? 'pending',
      parentApprovedAt: json['parent_approved_at'] != null
          ? DateTime.parse(json['parent_approved_at'] as String)
          : null,
      parentRemarks: json['parent_remarks'] as String?,
      hostelName: json['hostel_name'] as String?,
      isExpired: json['is_expired'] as bool? ?? false,
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
      'hostel_name': hostelName,
      'is_expired': isExpired,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GatePassModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? classId,
    String? className,
    String? departmentId,
    String? departmentName,
    String? reason,
    String? destination,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? advisorStatus,
    String? hodStatus,
    String? wardenStatus,
    bool? parentNotified,
    String? advisorId,
    DateTime? advisorApprovedAt,
    String? advisorRemarks,
    String? hodId,
    DateTime? hodApprovedAt,
    String? hodRemarks,
    String? wardenId,
    DateTime? wardenApprovedAt,
    DateTime? exitTime,
    DateTime? entryTime,
    String? wardenRemarks,
    String? finalStatus,
    String? parentApprovalStatus,
    DateTime? parentApprovedAt,
    String? parentRemarks,
    String? hostelName,
    bool? isExpired,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GatePassModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      reason: reason ?? this.reason,
      destination: destination ?? this.destination,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      status: status ?? this.status,
      advisorStatus: advisorStatus ?? this.advisorStatus,
      hodStatus: hodStatus ?? this.hodStatus,
      wardenStatus: wardenStatus ?? this.wardenStatus,
      parentNotified: parentNotified ?? this.parentNotified,
      advisorId: advisorId ?? this.advisorId,
      advisorApprovedAt: advisorApprovedAt ?? this.advisorApprovedAt,
      advisorRemarks: advisorRemarks ?? this.advisorRemarks,
      hodId: hodId ?? this.hodId,
      hodApprovedAt: hodApprovedAt ?? this.hodApprovedAt,
      hodRemarks: hodRemarks ?? this.hodRemarks,
      wardenId: wardenId ?? this.wardenId,
      wardenApprovedAt: wardenApprovedAt ?? this.wardenApprovedAt,
      exitTime: exitTime ?? this.exitTime,
      entryTime: entryTime ?? this.entryTime,
      wardenRemarks: wardenRemarks ?? this.wardenRemarks,
      finalStatus: finalStatus ?? this.finalStatus,
      parentApprovalStatus: parentApprovalStatus ?? this.parentApprovalStatus,
      parentApprovedAt: parentApprovedAt ?? this.parentApprovedAt,
      parentRemarks: parentRemarks ?? this.parentRemarks,
      hostelName: hostelName ?? this.hostelName,
      isExpired: isExpired ?? this.isExpired,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String getStatusText() {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'advisor_approved':
        return 'Advisor Approved';
      case 'hod_approved':
        return 'HOD Approved';
      case 'warden_approved':
        return 'Warden Approved';
      case 'approved':
        return 'Gate Pass Granted';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  /// True when all three approvals are complete and the gate pass token is valid.
  /// Handles both new status='approved' and legacy status='warden_approved'.
  bool get isFinallyApproved =>
      (status == 'approved' || status == 'warden_approved') &&
      advisorStatus == 'approved' &&
      hodStatus == 'approved' &&
      wardenStatus == 'approved';

  /// True if the pass is approved, not yet expired by flag, and toDate hasn't
  /// passed and the student hasn't returned yet (no entryTime recorded).
  bool get isCurrentlyActive =>
      isFinallyApproved &&
      !isExpired &&
      entryTime == null &&
      DateTime.now().isBefore(toDate);

  /// Whether the pass should visually display as expired (informational only).
  bool get isEffectivelyExpired =>
      isFinallyApproved &&
      (isExpired || entryTime != null || DateTime.now().isAfter(toDate));
}
