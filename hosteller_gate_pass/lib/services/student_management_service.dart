import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class StudentManagementService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get all students in advisor's class
  Future<List<UserModel>> getClassStudents() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Get advisor's department and class
    final advisorData = await _supabase
        .from('users')
        .select('department_id, class_id')
        .eq('id', userId)
        .single();

    final departmentId = advisorData['department_id'];
    final classId = advisorData['class_id'];
    if (departmentId == null || classId == null) {
      throw Exception('Advisor not assigned to a department and class');
    }

    // Get all students in that department and class
    final response = await _supabase
        .from('users')
        .select()
        .eq('department_id', departmentId)
        .eq('class_id', classId)
        .eq('role', 'student')
        .order('full_name');

    return (response as List).map((json) => UserModel.fromJson(json)).toList();
  }

  // Add a new student using database function
  Future<void> addStudent({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String departmentId,
    required String classId,
    String? hostelName,
    String? roomNo,
    String? semester,
    String? section,
    String? homeAddress,
    String? parentPhone,
  }) async {
    print('🔍 Starting addStudent...');
    print('  Email: $email');
    print('  Name: $fullName');
    print('  Phone: $phone');

    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('Not authenticated');
    }

    final advisorData = await _supabase
        .from('users')
        .select('department_id, class_id')
        .eq('id', currentUserId)
        .single();

    final advisorDepartmentId = advisorData['department_id'] as String?;
    final advisorClassId = advisorData['class_id'] as String?;

    if (advisorDepartmentId == null || advisorClassId == null) {
      throw Exception('Advisor must be assigned to a department and a class');
    }

    final effectiveDepartmentId = advisorDepartmentId;
    final effectiveClassId = advisorClassId;

    print('  DeptID: $effectiveDepartmentId');
    print('  ClassID: $effectiveClassId');

    // Convert semester from String (S1, S2, etc.) to int (1, 2, etc.)
    int? semesterNumber;
    if (semester != null && semester.isNotEmpty) {
      semesterNumber = int.tryParse(semester.replaceFirst('S', ''));
    }

    try {
      // Call the database function
      final response = await _supabase.rpc('create_student_user', params: {
        'p_email': email,
        'p_password': password,
        'p_full_name': fullName,
        'p_phone': phone,
        'p_department_id': effectiveDepartmentId,
        'p_class_id': effectiveClassId,
        'p_hostel_name': hostelName,
        'p_room_no': roomNo,
        'p_semester': semesterNumber,
        'p_section': section,
        'p_home_address': homeAddress,
        'p_parent_phone': parentPhone,
      });

      print('✅ Function response: $response');

      // Check if response indicates success
      if (response != null && response is Map) {
        if (response['success'] == false) {
          throw Exception(response['message'] ?? 'Failed to create student');
        }
      }

      print('✅ Student created successfully!');
    } catch (e) {
      print('❌ Error in addStudent: $e');

      // Provide more helpful error messages
      if (e.toString().contains('duplicate key')) {
        throw Exception('Email already exists');
      } else if (e.toString().contains('function') &&
          e.toString().contains('does not exist')) {
        throw Exception(
            'Database function not found. Please run the SQL setup script in Supabase.');
      } else if (e.toString().contains('permission denied')) {
        throw Exception(
            'Permission denied. Please grant execute permission to the function.');
      } else {
        rethrow;
      }
    }
  }

  // Update student details
  Future<void> updateStudent({
    required String studentId,
    required String fullName,
    String? phone,
    String? hostelName,
    String? roomNo,
  }) async {
    print('🔍 Updating student: $studentId');

    try {
      await _supabase.from('users').update({
        'full_name': fullName,
        'phone': phone,
        if (hostelName != null) 'hostel_name': hostelName,
        if (roomNo != null) 'room_no': roomNo,
      }).eq('id', studentId);

      print('✅ Student updated successfully!');
    } catch (e) {
      print('❌ Error updating student: $e');
      rethrow;
    }
  }

  // Delete student
  Future<void> deleteStudent(String studentId) async {
    print('🔍 Deleting student: $studentId');

    try {
      // First delete from public.users
      await _supabase.from('users').delete().eq('id', studentId);

      // Try to delete from auth.users using function if available
      try {
        await _supabase.rpc('delete_student_user', params: {
          'p_user_id': studentId,
        });
        print('✅ Deleted from auth.users too');
      } catch (e) {
        print('⚠️ Could not delete from auth.users: $e');
        print('💡 You may need to manually delete from Authentication → Users');
      }

      print('✅ Student deleted from public.users successfully!');
    } catch (e) {
      print('❌ Error deleting student: $e');
      rethrow;
    }
  }
}
