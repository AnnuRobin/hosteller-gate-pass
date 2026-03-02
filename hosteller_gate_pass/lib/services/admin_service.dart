import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class AdminService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get all users
  Future<List<UserModel>> getAllUsers() async {
    final response = await _supabase
        .from('users')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((user) => UserModel.fromJson(user))
        .toList();
  }

  // Get users by role
  Future<List<UserModel>> getUsersByRole(String role) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('role', role)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((user) => UserModel.fromJson(user))
        .toList();
  }

  // Search users by name or email
  Future<List<UserModel>> searchUsers(String query) async {
    final response = await _supabase
        .from('users')
        .select()
        .or('full_name.ilike.%$query%,email.ilike.%$query%')
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((user) => UserModel.fromJson(user))
        .toList();
  }

  // Create new user (admin only)
  Future<void> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? departmentId,
    String? classId,
    int? semester,
    String? section,
    String? homeAddress,
    String? hostelName,
    String? roomNo,
  }) async {
    try {
      // Call Supabase RPC function to create user
      final response = await _supabase.rpc('admin_create_user', params: {
        'p_email': email,
        'p_password': password,
        'p_full_name': fullName,
        'p_role': role,
        'p_phone': phone,
        'p_department_id': departmentId,
        'p_class_id': classId,
        'p_semester': semester,
        'p_section': section,
        'p_home_address': homeAddress,
        'p_hostel_name': hostelName,
        'p_room_no': roomNo,
      });

      print('User created successfully: $response');
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Update user
  Future<void> updateUser({
    required String userId,
    String? fullName,
    String? phone,
    String? role,
    String? departmentId,
    String? classId,
    int? semester,
    String? section,
    String? homeAddress,
    String? hostelName,
    String? roomNo,
  }) async {
    try {
      await _supabase.rpc('admin_update_user', params: {
        'p_user_id': userId,
        'p_full_name': fullName,
        'p_phone': phone,
        'p_role': role,
        'p_department_id': departmentId,
        'p_class_id': classId,
        'p_semester': semester,
        'p_section': section,
        'p_home_address': homeAddress,
        'p_hostel_name': hostelName,
        'p_room_no': roomNo,
      });

      print('User updated successfully');
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _supabase.rpc('admin_delete_user', params: {
        'p_user_id': userId,
      });

      print('User deleted successfully');
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // Reset user password
  Future<void> resetUserPassword(String userId, String newPassword) async {
    try {
      await _supabase.rpc('admin_reset_password', params: {
        'p_user_id': userId,
        'p_new_password': newPassword,
      });

      print('Password reset successfully');
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }

  // Get audit logs
  Future<List<Map<String, dynamic>>> getAuditLogs({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('admin_audit_log')
          .select('*, admin:admin_id(full_name, email), target:target_user_id(full_name, email)')
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching audit logs: $e');
      return [];
    }
  }

  // Private method to log admin actions
  Future<void> _logAdminAction(
    String action,
    String targetUserId,
    Map<String, dynamic> details,
  ) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        await _supabase.from('admin_audit_log').insert({
          'admin_id': currentUser.id,
          'action': action,
          'target_user_id': targetUserId,
          'details': details,
        });
      }
    } catch (e) {
      print('Error logging admin action: $e');
    }
  }

  // Bulk create students
  Future<Map<String, dynamic>> bulkCreateStudents({
    required List<Map<String, dynamic>> students,
    required String departmentId,
    String? classId,
    required int semester,
    required String section,
  }) async {
    try {
      final response = await _supabase.rpc('admin_bulk_create_students', params: {
        'p_students': students,
        'p_department_id': departmentId,
        'p_class_id': classId,
        'p_semester': semester,
        'p_section': section,
      });

      print('Bulk creation response: $response');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error bulk creating students: $e');
      rethrow;
    }
  }

}
