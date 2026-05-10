import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

/// Thin service layer for HOD-specific data queries.
/// Wraps Supabase directly to keep an organised, minimal footprint.
class HodManagementService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // ── Students ─────────────────────────────────────────────────────────────

  /// Fetch all students in [departmentId], ordered by semester then name.
  Future<List<UserModel>> getDepartmentStudents(String departmentId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('role', 'student')
        .eq('department_id', departmentId)
        .order('semester', ascending: true)
        .order('full_name', ascending: true);

    return (response as List).map((j) => UserModel.fromJson(j)).toList();
  }

  // ── Faculty (Advisors) ────────────────────────────────────────────────────

  /// Fetch all advisors assigned to [departmentId].
  Future<List<UserModel>> getDepartmentFaculty(String departmentId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('role', 'advisor')
        .eq('department_id', departmentId)
        .order('full_name', ascending: true);

    return (response as List).map((j) => UserModel.fromJson(j)).toList();
  }

  /// Create a new advisor in the HOD's department using the
  /// hod_create_faculty RPC (SECURITY DEFINER, bypasses admin-only check).
  Future<void> createFaculty({
    required String email,
    required String password,
    required String fullName,
    required String departmentId,
    String? phone,
    String? classId,
  }) async {
    await _supabase.rpc('hod_create_faculty', params: {
      'p_email': email,
      'p_password': password,
      'p_full_name': fullName,
      'p_phone': phone,
      'p_department_id': departmentId,
      'p_class_id': classId,
    });
  }


  /// Delete (remove) a faculty member from the public.users table.
  /// Uses the admin_delete_user RPC if available, otherwise falls back to a
  /// direct delete (which only removes the public record, not auth.users).
  Future<void> deleteFaculty(String facultyId) async {
    try {
      await _supabase.rpc('admin_delete_user', params: {
        'p_user_id': facultyId,
      });
    } catch (_) {
      // Fallback: delete from public.users only
      await _supabase.from('users').delete().eq('id', facultyId);
    }
  }
}
