class ParentOtpModel {
  final String id;
  final String gatePassRequestId;
  final String parentPhone;
  final String otpCode;
  final bool isVerified;
  final DateTime expiresAt;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final int attempts;

  ParentOtpModel({
    required this.id,
    required this.gatePassRequestId,
    required this.parentPhone,
    required this.otpCode,
    required this.isVerified,
    required this.expiresAt,
    this.verifiedAt,
    required this.createdAt,
    required this.attempts,
  });

  factory ParentOtpModel.fromJson(Map<String, dynamic> json) {
    return ParentOtpModel(
      id: json['id'] as String,
      gatePassRequestId: json['gate_pass_request_id'] as String,
      parentPhone: json['parent_phone'] as String,
      otpCode: json['otp_code'] as String,
      isVerified: json['is_verified'] as bool? ?? false,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      attempts: json['attempts'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gate_pass_request_id': gatePassRequestId,
      'parent_phone': parentPhone,
      'otp_code': otpCode,
      'is_verified': isVerified,
      'expires_at': expiresAt.toIso8601String(),
      'verified_at': verifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'attempts': attempts,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  bool get canResend => attempts < 3;
}
