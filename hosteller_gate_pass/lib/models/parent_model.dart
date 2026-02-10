class ParentModel {
  final String id;
  final String studentId;
  final String relationship; // 'father', 'mother', 'guardian'
  final bool isPrimaryContact;
  final DateTime createdAt;
  final DateTime updatedAt;

  ParentModel({
    required this.id,
    required this.studentId,
    required this.relationship,
    required this.isPrimaryContact,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ParentModel.fromJson(Map<String, dynamic> json) {
    return ParentModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      relationship: json['relationship'] as String,
      isPrimaryContact: json['is_primary_contact'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'relationship': relationship,
      'is_primary_contact': isPrimaryContact,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
