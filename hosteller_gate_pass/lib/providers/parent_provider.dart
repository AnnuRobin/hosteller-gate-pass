import 'package:flutter/material.dart';
import '../services/parent_service.dart';
import '../services/parent_otp_service.dart';
import '../services/gate_pass_service.dart';
import '../models/parent_model.dart';
import '../models/user_model.dart';
import '../models/gate_pass_model.dart';

class ParentProvider with ChangeNotifier {
  final ParentService _parentService = ParentService();
  final ParentOtpService _otpService = ParentOtpService();
  final GatePassService _gatePassService = GatePassService();
  
  List<UserModel> _students = [];
  List<GatePassModel> _gatePassRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get students => _students;
  List<GatePassModel> get gatePassRequests => _gatePassRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get pending requests requiring parent approval
  List<GatePassModel> get pendingApprovals => _gatePassRequests
      .where((r) => r.parentApprovalStatus == 'pending')
      .toList();

  // Get approved requests
  List<GatePassModel> get approvedRequests => _gatePassRequests
      .where((r) => r.parentApprovalStatus == 'approved')
      .toList();

  // Load students for parent
  Future<void> loadStudents(String parentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _students = await _parentService.getStudentsForParent(parentId);
    } catch (e) {
      _errorMessage = 'Error loading students: $e';
      debugPrint(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load gate pass requests for parent's students
  Future<void> loadGatePassRequests(String parentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get all students for this parent
      final students = await _parentService.getStudentsForParent(parentId);
      
      // Get gate pass requests for each student
      List<GatePassModel> allRequests = [];
      for (var student in students) {
        final requests = await _gatePassService.getStudentRequests(student.id);
        allRequests.addAll(requests);
      }
      
      _gatePassRequests = allRequests;
    } catch (e) {
      _errorMessage = 'Error loading gate pass requests: $e';
      debugPrint(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Approve gate pass request
  Future<bool> approveRequest({
    required String requestId,
    String? remarks,
  }) async {
    try {
      final success = await _otpService.approveByParent(
        gatePassRequestId: requestId,
        remarks: remarks,
      );
      
      if (success) {
        // Reload requests
        final parentId = _students.isNotEmpty ? _students.first.id : '';
        if (parentId.isNotEmpty) {
          await loadGatePassRequests(parentId);
        }
      }
      
      return success;
    } catch (e) {
      _errorMessage = 'Error approving request: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  // Reject gate pass request
  Future<bool> rejectRequest({
    required String requestId,
    String? remarks,
  }) async {
    try {
      final success = await _otpService.rejectByParent(
        gatePassRequestId: requestId,
        remarks: remarks,
      );
      
      if (success) {
        // Reload requests
        final parentId = _students.isNotEmpty ? _students.first.id : '';
        if (parentId.isNotEmpty) {
          await loadGatePassRequests(parentId);
        }
      }
      
      return success;
    } catch (e) {
      _errorMessage = 'Error rejecting request: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
