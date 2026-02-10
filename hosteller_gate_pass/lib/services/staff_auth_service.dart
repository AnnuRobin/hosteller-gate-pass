import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class StaffAuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Staff login with username and password
  Future<StaffLoginResponse> staffLogin({
    required String username,
    required String email,
    required String password,
    required String role, // 'warden', 'hod', or 'admin'
  }) async {
    try {
      // Step 1: Authenticate with Supabase Auth
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Authentication failed');
      }

      // Step 2: Verify staff credentials and role
      final staffData = await _supabase.rpc(
        'verify_staff_login',
        params: {
          'p_username': username,
          'p_role': role,
        },
      );

      if (staffData == null || (staffData as List).isEmpty) {
        // Invalid credentials or inactive account
        await _supabase.auth.signOut();
        throw Exception('Invalid credentials or inactive account');
      }

      final staff = (staffData as List).first;

      // Step 3: Create login session
      final sessionData = await _supabase.rpc(
        'create_login_session',
        params: {
          'p_user_id': authResponse.user!.id,
          'p_role': role,
          'p_ip_address': null, // You can get this from device
          'p_user_agent': 'Flutter App',
        },
      );

      final session = (sessionData as List).first;

      // Step 4: Get full user profile
      final userProfile = await getUserProfile(authResponse.user!.id);

      return StaffLoginResponse(
        user: authResponse.user!,
        userProfile: userProfile,
        sessionToken: session['session_token'],
        expiresAt: DateTime.parse(session['expires_at']),
      );
    } catch (e) {
      print('Staff login error: $e');
      rethrow;
    }
  }

  // Validate session token
  Future<bool> validateSession(String sessionToken) async {
    try {
      final result = await _supabase.rpc(
        'validate_session_token',
        params: {'p_session_token': sessionToken},
      );

      if (result == null || (result as List).isEmpty) {
        return false;
      }

      final sessionData = (result as List).first;
      return sessionData['is_valid'] == true;
    } catch (e) {
      print('Session validation error: $e');
      return false;
    }
  }

  // Staff logout
  Future<void> staffLogout(String sessionToken) async {
    try {
      // Invalidate session in database
      await _supabase.rpc(
        'logout_session',
        params: {'p_session_token': sessionToken},
      );

      // Sign out from Supabase Auth
      await _supabase.auth.signOut();
    } catch (e) {
      print('Logout error: $e');
      rethrow;
    }
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

  // Get staff credentials info
  Future<StaffCredentials?> getStaffCredentials(String userId) async {
    try {
      final response = await _supabase
          .from('staff_credentials')
          .select()
          .eq('user_id', userId)
          .single();

      return StaffCredentials.fromJson(response);
    } catch (e) {
      print('Error getting staff credentials: $e');
      return null;
    }
  }

  // Check if current user has specific role
  Future<bool> hasRole(String role) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      final userProfile = await getUserProfile(currentUser.id);
      return userProfile?.role == role;
    } catch (e) {
      print('Error checking role: $e');
      return false;
    }
  }

  // Get current authenticated user
  User? get currentUser => _supabase.auth.currentUser;

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}

// Response model for staff login
class StaffLoginResponse {
  final User user;
  final UserModel? userProfile;
  final String sessionToken;
  final DateTime expiresAt;

  StaffLoginResponse({
    required this.user,
    required this.userProfile,
    required this.sessionToken,
    required this.expiresAt,
  });
}

// Staff credentials model
class StaffCredentials {
  final String id;
  final String userId;
  final String username;
  final String role;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  StaffCredentials({
    required this.id,
    required this.userId,
    required this.username,
    required this.role,
    required this.isActive,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StaffCredentials.fromJson(Map<String, dynamic> json) {
    return StaffCredentials(
      id: json['id'],
      userId: json['user_id'],
      username: json['username'],
      role: json['role'],
      isActive: json['is_active'] ?? true,
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'role': role,
      'is_active': isActive,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
