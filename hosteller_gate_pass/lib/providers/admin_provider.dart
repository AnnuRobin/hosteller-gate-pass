import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/user_model.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _service = AdminService();
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get users by role
  List<UserModel> getUsersByRole(String role) {
    return _users.where((user) => user.role == role).toList();
  }

  // Load all users
  Future<void> loadAllUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _service.getAllUsers();
    } catch (e) {
      _errorMessage = 'Error loading users: $e';
      debugPrint(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load users by role
  Future<void> loadUsersByRole(String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _service.getUsersByRole(role);
    } catch (e) {
      _errorMessage = 'Error loading users: $e';
      debugPrint(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Search users
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      await loadAllUsers();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _service.searchUsers(query);
    } catch (e) {
      _errorMessage = 'Error searching users: $e';
      debugPrint(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Create user
  Future<bool> createUser({
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
      await _service.createUser(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phone: phone,
        departmentId: departmentId,
        classId: classId,
        semester: semester,
        section: section,
        homeAddress: homeAddress,
      );
      await loadAllUsers();
      return true;
    } catch (e) {
      _errorMessage = 'Error creating user: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  // Update user
  Future<bool> updateUser({
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
      await _service.updateUser(
        userId: userId,
        fullName: fullName,
        phone: phone,
        role: role,
        departmentId: departmentId,
        classId: classId,
        semester: semester,
        section: section,
        homeAddress: homeAddress,
      );
      await loadAllUsers();
      return true;
    } catch (e) {
      _errorMessage = 'Error updating user: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      await _service.deleteUser(userId);
      await loadAllUsers();
      return true;
    } catch (e) {
      _errorMessage = 'Error deleting user: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  // Reset user password
  Future<bool> resetUserPassword(String userId, String newPassword) async {
    try {
      await _service.resetUserPassword(userId, newPassword);
      return true;
    } catch (e) {
      _errorMessage = 'Error resetting password: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  // Get audit logs
  Future<List<Map<String, dynamic>>> getAuditLogs({int limit = 50}) async {
    try {
      return await _service.getAuditLogs(limit: limit);
    } catch (e) {
      debugPrint('Error fetching audit logs: $e');
      return [];
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
