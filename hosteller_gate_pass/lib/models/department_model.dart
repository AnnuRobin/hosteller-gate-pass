class DepartmentModel {
  final String id;
  final String name;
  final String? hodId;
  final DateTime createdAt;
  
  DepartmentModel({
    required this.id,
    required this.name,
    this.hodId,
    required this.createdAt,
  });
  
  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      hodId: json['hod_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hod_id': hodId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}