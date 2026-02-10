class BatchModel {
  final String departmentId;
  final String departmentName;
  final int semester;
  final String section;
  final int studentCount;

  BatchModel({
    required this.departmentId,
    required this.departmentName,
    required this.semester,
    required this.section,
    required this.studentCount,
  });

  String get displayName => 'Semester $semester $departmentName $section';
  
  String get batchCode => 'S${semester}_${section.toUpperCase()}';

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      departmentId: json['department_id'] as String,
      departmentName: json['department_name'] as String,
      semester: json['semester'] as int,
      section: json['section'] as String,
      studentCount: json['student_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'department_id': departmentId,
      'department_name': departmentName,
      'semester': semester,
      'section': section,
      'student_count': studentCount,
    };
  }
}
