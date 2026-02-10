import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/staff_auth_service.dart';
import '../models/user_model.dart';

class StaffAuthProvider with ChangeNotifier {
  final StaffAuthService _authService = StaffAuthService();
  
  User? _currentUser;
  UserModel? _userProfile;
  StaffCredentials? _staffCredentials;
  String? _sessionToken;
  DateTime? _sessionExpiresAt;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  UserModel? get userProfile => _userProfile;
  StaffCredentials? get staffCredentials => _staffCredentials;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null && _sessionToken != null;
  bool get isSessionValid => _sessionExpiresAt != null && 
                              _sessionExpiresAt!.isAfter(DateTime.now());

  // Role checks
  bool get isAdmin => _userProfile?.role == 'admin';
  bool get isWarden => _userProfile?.role == 'warden';
  bool get isHOD => _userProfile?.role == 'hod';

  StaffAuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = _authService.currentUser;

      if (_currentUser != null) {
        _userProfile = await _authService.getUserProfile(_currentUser!.id);
        _staffCredentials = await _authService.getStaffCredentials(_currentUser!.id);
      }
    } catch (e) {
      print('Initialization error: $e');
      _errorMessage = 'Failed to initialize authentication';
    }

    _isLoading = false;
    notifyListeners();

    // Listen to auth state changes
    _authService.authStateChanges.listen((data) async {
      _currentUser = data.session?.user;
      if (_currentUser != null) {
        _userProfile = await _authService.getUserProfile(_currentUser!.id);
        _staffCredentials = await _authService.getStaffCredentials(_currentUser!.id);
      } else {
        _userProfile = null;
        _staffCredentials = null;
        _sessionToken = null;
        _sessionExpiresAt = null;
      }
      notifyListeners();
    });
  }

  // Staff login
  Future<bool> staffLogin({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.staffLogin(
        username: username,
        email: email,
        password: password,
        role: role,
      );

      _currentUser = response.user;
      _userProfile = response.userProfile;
      _sessionToken = response.sessionToken;
      _sessionExpiresAt = response.expiresAt;
      _staffCredentials = await _authService.getStaffCredentials(response.user.id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Warden login
  Future<bool> wardenLogin({
    required String username,
    required String email,
    required String password,
  }) async {
    return await staffLogin(
      username: username,
      email: email,
      password: password,
      role: 'warden',
    );
  }

  // HOD login
  Future<bool> hodLogin({
    required String username,
    required String email,
    required String password,
  }) async {
    return await staffLogin(
      username: username,
      email: email,
      password: password,
      role: 'hod',
    );
  }

  // Admin login
  Future<bool> adminLogin({
    required String username,
    required String email,
    required String password,
  }) async {
    return await staffLogin(
      username: username,
      email: email,
      password: password,
      role: 'admin',
    );
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_sessionToken != null) {
        await _authService.staffLogout(_sessionToken!);
      }

      _currentUser = null;
      _userProfile = null;
      _staffCredentials = null;
      _sessionToken = null;
      _sessionExpiresAt = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Logout failed: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Validate current session
  Future<bool> validateSession() async {
    if (_sessionToken == null) return false;

    try {
      final isValid = await _authService.validateSession(_sessionToken!);
      if (!isValid) {
        await logout();
      }
      return isValid;
    } catch (e) {
      print('Session validation error: $e');
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Helper to get user-friendly error messages
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('invalid credentials')) {
      return 'Invalid username or password';
    } else if (errorString.contains('inactive account')) {
      return 'Your account has been deactivated. Please contact admin.';
    } else if (errorString.contains('network')) {
      return 'Network error. Please check your connection.';
    } else if (errorString.contains('timeout')) {
      return 'Request timeout. Please try again.';
    } else {
      return 'Login failed. Please try again.';
    }
  }
}
