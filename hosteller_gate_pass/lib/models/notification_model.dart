class NotificationModel {
  final String id;
  final String userId;
  final String? passRequestId;
  final String title;
  final String message;
  final String type;
  final bool read;
  final DateTime createdAt;
  
  NotificationModel({
    required this.id,
    required this.userId,
    this.passRequestId,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
  });
  
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      passRequestId: json['pass_request_id'] as String?,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      read: json['read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'pass_request_id': passRequestId,
      'title': title,
      'message': message,
      'type': type,
      'read': read,
      'created_at': createdAt.toIso8601String(),
    };
  }
}