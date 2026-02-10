import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/parent_model.dart';
import '../models/user_model.dart';

class ParentService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get parents for a student
  Future<List<ParentModel>> getParentsForStudent(String studentId) async {
    try {
      final response = await _supabase
          .from('parents')
          .select()
          .eq('student_id', studentId);
      
      return (response as List)
          .map((parent) => ParentModel.fromJson(parent))
          .toList();
    } catch (e) {
      print('Error fetching parents: $e');
      return [];
    }
  }

  // Get parent details with user info
  Future<Map<String, dynamic>?> getParentWithUserInfo(String parentId) async {
    try {
      final response = await _supabase
          .from('parents')
          .select('*, user:id(full_name, email, phone)')
          .eq('id', parentId)
          .single();
      
      return response;
    } catch (e) {
      print('Error fetching parent info: $e');
      return null;
    }
  }

  // Get students for a parent
  Future<List<UserModel>> getStudentsForParent(String parentId) async {
    try {
      final response = await _supabase
          .from('parents')
          .select('student:student_id(*)')
          .eq('id', parentId);
      
      return (response as List)
          .map((item) => UserModel.fromJson(item['student']))
          .toList();
    } catch (e) {
      print('Error fetching students: $e');
      return [];
    }
  }

  // Link parent to student
  Future<void> linkParentToStudent({
    required String parentId,
    required String studentId,
    required String relationship,
    bool isPrimaryContact = false,
  }) async {
    try {
      await _supabase.from('parents').insert({
        'id': parentId,
        'student_id': studentId,
        'relationship': relationship,
        'is_primary_contact': isPrimaryContact,
      });
    } catch (e) {
      print('Error linking parent to student: $e');
      rethrow;
    }
  }

  // Update parent-student relationship
  Future<void> updateParentRelationship({
    required String parentId,
    required String studentId,
    String? relationship,
    bool? isPrimaryContact,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (relationship != null) updates['relationship'] = relationship;
      if (isPrimaryContact != null) updates['is_primary_contact'] = isPrimaryContact;

      await _supabase
          .from('parents')
          .update(updates)
          .eq('id', parentId)
          .eq('student_id', studentId);
    } catch (e) {
      print('Error updating parent relationship: $e');
      rethrow;
    }
  }

  // Remove parent-student link
  Future<void> unlinkParentFromStudent({
    required String parentId,
    required String studentId,
  }) async {
    try {
      await _supabase
          .from('parents')
          .delete()
          .eq('id', parentId)
          .eq('student_id', studentId);
    } catch (e) {
      print('Error unlinking parent: $e');
      rethrow;
    }
  }

  // Get primary parent for student
  Future<Map<String, dynamic>?> getPrimaryParent(String studentId) async {
    try {
      final response = await _supabase
          .from('parents')
          .select('*, user:id(full_name, email, phone)')
          .eq('student_id', studentId)
          .eq('is_primary_contact', true)
          .single();
      
      return response;
    } catch (e) {
      print('Error fetching primary parent: $e');
      return null;
    }
  }
}
