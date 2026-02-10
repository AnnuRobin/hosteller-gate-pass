import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/department_model.dart';
import '../models/user_model.dart';
import '../models/batch_model.dart';

class DepartmentService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get all departments
  Future<List<DepartmentModel>> getAllDepartments() async {
    try {
      final response = await _supabase
          .from('departments')
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((dept) => DepartmentModel.fromJson(dept))
          .toList();
    } catch (e) {
      print('Error fetching departments: $e');
      rethrow;
    }
  }

  // Get department by ID
  Future<DepartmentModel?> getDepartmentById(String departmentId) async {
    try {
      final response = await _supabase
          .from('departments')
          .select()
          .eq('id', departmentId)
          .single();

      return DepartmentModel.fromJson(response);
    } catch (e) {
      print('Error fetching department: $e');
      return null;
    }
  }

  // Get all students in a department
  Future<List<UserModel>> getStudentsByDepartment(String departmentId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'student')
          .eq('department_id', departmentId)
          .order('semester', ascending: true)
          .order('section', ascending: true)
          .order('full_name', ascending: true);

      return (response as List)
          .map((user) => UserModel.fromJson(user))
          .toList();
    } catch (e) {
      print('Error fetching students by department: $e');
      rethrow;
    }
  }

  // Get batches (semester + section groupings) in a department
  Future<List<BatchModel>> getBatchesInDepartment(String departmentId) async {
    try {
      // Get department info
      final department = await getDepartmentById(departmentId);
      if (department == null) {
        throw Exception('Department not found');
      }

      // Get all students in the department
      final students = await getStudentsByDepartment(departmentId);

      // Group students by semester and section
      final Map<String, BatchModel> batchMap = {};

      for (var student in students) {
        if (student.semester != null && student.section != null) {
          final key = '${student.semester}_${student.section}';
          
          if (batchMap.containsKey(key)) {
            // Increment count
            final existing = batchMap[key]!;
            batchMap[key] = BatchModel(
              departmentId: departmentId,
              departmentName: department.name,
              semester: student.semester!,
              section: student.section!,
              studentCount: existing.studentCount + 1,
            );
          } else {
            // Create new batch
            batchMap[key] = BatchModel(
              departmentId: departmentId,
              departmentName: department.name,
              semester: student.semester!,
              section: student.section!,
              studentCount: 1,
            );
          }
        }
      }

      // Convert to list and sort
      final batches = batchMap.values.toList();
      batches.sort((a, b) {
        final semesterCompare = a.semester.compareTo(b.semester);
        if (semesterCompare != 0) return semesterCompare;
        return a.section.compareTo(b.section);
      });

      return batches;
    } catch (e) {
      print('Error fetching batches: $e');
      rethrow;
    }
  }

  // Get students in a specific batch
  Future<List<UserModel>> getStudentsByBatch({
    required String departmentId,
    required int semester,
    required String section,
  }) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'student')
          .eq('department_id', departmentId)
          .eq('semester', semester)
          .eq('section', section)
          .order('full_name', ascending: true);

      return (response as List)
          .map((user) => UserModel.fromJson(user))
          .toList();
    } catch (e) {
      print('Error fetching students by batch: $e');
      rethrow;
    }
  }

  // Get department statistics
  Future<Map<String, int>> getDepartmentStatistics(String departmentId) async {
    try {
      final students = await getStudentsByDepartment(departmentId);
      final batches = await getBatchesInDepartment(departmentId);

      return {
        'total_students': students.length,
        'total_batches': batches.length,
      };
    } catch (e) {
      print('Error fetching department statistics: $e');
      return {'total_students': 0, 'total_batches': 0};
    }
  }

  // Get all departments with student counts
  Future<List<Map<String, dynamic>>> getDepartmentsWithCounts() async {
    try {
      final departments = await getAllDepartments();
      final List<Map<String, dynamic>> departmentsWithCounts = [];

      for (var dept in departments) {
        final students = await getStudentsByDepartment(dept.id);
        departmentsWithCounts.add({
          'department': dept,
          'student_count': students.length,
        });
      }

      return departmentsWithCounts;
    } catch (e) {
      print('Error fetching departments with counts: $e');
      rethrow;
    }
  }
}
