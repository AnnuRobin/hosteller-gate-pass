import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class StudentManagementService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Fetch unique hostel names from the users table
  Future<List<String>> getHostels() async {
    try {
      // Fetch all non-null hostel names
      final response = await _supabase
          .from('users')
          .select('hostel_name')
          .not('hostel_name', 'is', null);
      
      // Filter unique non-empty names in Dart
      final hostels = (response as List)
          .map((row) => row['hostel_name'].toString().trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();
      
      hostels.sort();
      
      // Fallback defaults if table is empty
      if (hostels.isEmpty) {
        return ['St Marys', 'St Thomas'];
      }
      
      return hostels;
    } catch (e) {
      print('Error fetching hostels: $e');
      return ['St Marys', 'St Thomas'];
    }
  }

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

    // Convert semester from String (S1, S2, etc.) to int (1, 2, etc.)
    int? semesterNumber;
    if (semester != null && semester.isNotEmpty) {
      semesterNumber = int.tryParse(semester.replaceFirst('S', ''));
    }

    // Get current advisor info (still useful for context, but IDs are passed to the function)
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Not authenticated');

    final advisorData = await _supabase
        .from('users')
        .select('department_id, class_id')
        .eq('id', currentUserId)
        .single();
    
    final effectiveDepartmentId = advisorData['department_id'] as String;
    final effectiveClassId = advisorData['class_id'] as String;

    try {
      print('🚀 Invoking Edge Function: create-student');
      
      final response = await _supabase.functions.invoke(
        'create-student',
        body: {
          'email': email.trim().toLowerCase(),
          'password': password,
          'fullName': fullName.trim(),
          'phone': phone,
          'hostelName': hostelName,
          'roomNo': roomNo,
          'semester': semesterNumber,
          'section': section,
          'homeAddress': homeAddress,
          'parentPhone': parentPhone,
          'departmentId': effectiveDepartmentId,
          'class_id': effectiveClassId,
        },
      );

      print('✅ Function response received: ${response.status}');
      print('📊 Response data: ${response.data}');
      
      final data = response.data;
      if (data == null || (data is Map && data['success'] != true)) {
        final errorMsg = data?['message'] ?? 'Unknown error from Edge Function';
        print('❌ FAILED: $errorMsg');
        throw Exception(errorMsg);
      }

      print('✅ Student created successfully via Edge Function!');
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
