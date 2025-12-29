import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Get current user
  User? get currentUser => _supabase.auth.currentUser;
  
  // Sign up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? departmentId,
    String? classId,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    
    if (response.user != null) {
      // Create user profile
      await _supabase.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'role': role,
        'department_id': departmentId,
        'class_id': classId,
      });
    }
    
    return response;
  }
  
  // Sign in
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      
      return UserModel.fromJson(response);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
  
  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    
    await _supabase
        .from('users')
        .update(updates)
        .eq('id', userId);
  }
  
  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
