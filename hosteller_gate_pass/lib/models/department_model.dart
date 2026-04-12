class DepartmentModel {
  final String id;
  final String name;
  final String? departmentCode;
  final String? hodId;
  final DateTime createdAt;
  
  DepartmentModel({
    required this.id,
    required this.name,
    this.departmentCode,
    this.hodId,
    required this.createdAt,
  });
  
  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      departmentCode: json['department_code'] as String?,
      hodId: json['hod_id'] as String?,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'department_code': departmentCode,
      'hod_id': hodId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}