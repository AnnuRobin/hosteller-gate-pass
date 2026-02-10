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
  }) async {
    try {
      // Create auth user using admin API
      final authResponse = await _supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
        ),
      );

      if (authResponse.user != null) {
        // Create user profile
        await _supabase.from('users').insert({
          'id': authResponse.user!.id,
          'email': email,
          'full_name': fullName,
          'phone': phone,
          'role': role,
          'department_id': departmentId,
          'class_id': classId,
          'semester': semester,
          'section': section,
          'home_address': homeAddress,
          'email_verified': true, // Auto-verify for admin-created users
          'email_verified_at': DateTime.now().toIso8601String(),
        });

        // Log admin action
        await _logAdminAction('create_user', authResponse.user!.id, {
          'email': email,
          'role': role,
        });
      }
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
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (role != null) updates['role'] = role;
      if (departmentId != null) updates['department_id'] = departmentId;
      if (classId != null) updates['class_id'] = classId;
      if (semester != null) updates['semester'] = semester;
      if (section != null) updates['section'] = section;
      if (homeAddress != null) updates['home_address'] = homeAddress;

      if (updates.isNotEmpty) {
        await _supabase
            .from('users')
            .update(updates)
            .eq('id', userId);

        // Log admin action
        await _logAdminAction('update_user', userId, updates);
      }
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      // Delete from users table (this will cascade to related records)
      await _supabase
          .from('users')
          .delete()
          .eq('id', userId);

      // Delete auth user
      await _supabase.auth.admin.deleteUser(userId);

      // Log admin action
      await _logAdminAction('delete_user', userId, {});
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // Reset user password
  Future<void> resetUserPassword(String userId, String newPassword) async {
    try {
      await _supabase.auth.admin.updateUserById(
        userId,
        attributes: AdminUserAttributes(password: newPassword),
      );

      // Log admin action
      await _logAdminAction('reset_password', userId, {});
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
}
