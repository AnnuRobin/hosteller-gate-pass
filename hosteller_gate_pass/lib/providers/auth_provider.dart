import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  UserModel? _userProfile;
  bool _isLoading = true;
  
  User? get currentUser => _currentUser;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  
  AuthProvider() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    _currentUser = _authService.currentUser;
    
    if (_currentUser != null) {
      _userProfile = await _authService.getUserProfile(_currentUser!.id);
    }
    
    _isLoading = false;
    notifyListeners();
    
    // Listen to auth changes
    _authService.authStateChanges.listen((data) async {
      _currentUser = data.session?.user;
      if (_currentUser != null) {
        _userProfile = await _authService.getUserProfile(_currentUser!.id);
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }
  
  Future<void> signIn(String email, String password) async {
    await _authService.signIn(email: email, password: password);
  }
  
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? departmentId,
    String? classId,
  }) async {
    await _authService.signUp(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      phone: phone,
      departmentId: departmentId,
      classId: classId,
    );
  }
  
  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _userProfile = null;
    notifyListeners();
  }
}
