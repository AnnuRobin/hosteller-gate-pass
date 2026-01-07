import 'package:flutter/material.dart';
import '../services/gate_pass_service.dart';
import '../models/gate_pass_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GatePassProvider with ChangeNotifier {
  final GatePassService _service = GatePassService();
  List<GatePassModel> _requests = [];
  bool _isLoading = false;
  RealtimeChannel? _subscription;
  
  List<GatePassModel> get requests => _requests;
  bool get isLoading => _isLoading;
  
  // Get pending requests
  List<GatePassModel> get pendingRequests =>
      _requests.where((r) => r.status == 'pending').toList();
  
  // Get approved requests
  List<GatePassModel> get approvedRequests =>
      _requests.where((r) => r.status == 'approved').toList();
  
  // Get rejected requests
  List<GatePassModel> get rejectedRequests =>
      _requests.where((r) => r.status == 'rejected').toList();
  
  Future<void> loadStudentRequests(String studentId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _requests = await _service.getStudentRequests(studentId);
      _setupRealtimeSubscription(studentId: studentId);
    } catch (e) {
      print('Error loading requests: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
 Future<void> loadAdvisorRequests({
  required String classId,
  required String departmentId,
}) async {
  _isLoading = true;
  notifyListeners();

  try {
    _requests = await _service.getAdvisorRequests(
      classId: classId,
      departmentId: departmentId,
    );

    _setupRealtimeSubscription(
      classId: classId,
      departmentId: departmentId,
    );
  } catch (e) {
    debugPrint('Error loading advisor requests: $e');
  }

  _isLoading = false;
  notifyListeners();
}

  
  Future<void> loadHodRequests(String departmentId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _requests = await _service.getHodRequests(departmentId);
      _setupRealtimeSubscription(departmentId: departmentId);
    } catch (e) {
      print('Error loading requests: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> createRequest({
    required String studentId,
    required String classId,
    required String departmentId,
    required String reason,
    required String destination,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    await _service.createRequest(
      studentId: studentId,
      classId: classId,
      departmentId: departmentId,
      reason: reason,
      destination: destination,
      fromDate: fromDate,
      toDate: toDate,
    );
  }
  
  Future<void> updateRequest({
    required String requestId,
    String? reason,
    String? destination,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    await _service.updateRequest(
      requestId: requestId,
      reason: reason,
      destination: destination,
      fromDate: fromDate,
      toDate: toDate,
    );
  }
  
  Future<void> deleteRequest(String requestId) async {
    await _service.deleteRequest(requestId);
    _requests.removeWhere((r) => r.id == requestId);
    notifyListeners();
  }
  
  Future<void> advisorAction({
    required String requestId,
    required String advisorId,
    required bool approved,
    String? remarks,
  }) async {
    await _service.advisorAction(
      requestId: requestId,
      advisorId: advisorId,
      approved: approved,
      remarks: remarks,
    );
  }
  
  Future<void> hodAction({
    required String requestId,
    required String hodId,
    required bool approved,
    String? remarks,
  }) async {
    await _service.hodAction(
      requestId: requestId,
      hodId: hodId,
      approved: approved,
      remarks: remarks,
    );
  }
  
  void _setupRealtimeSubscription({
    String? studentId,
    String? classId,
    String? departmentId,
  }) {
    _subscription?.unsubscribe();
    
    _subscription = _service.subscribeToRequests(
      studentId: studentId,
      classId: classId,
      departmentId: departmentId,
      onInsert: (request) {
        _requests.insert(0, request);
        notifyListeners();
      },
      onUpdate: (request) {
        final index = _requests.indexWhere((r) => r.id == request.id);
        if (index != -1) {
          _requests[index] = request;
          notifyListeners();
        }
      },
      onDelete: (id) {
        _requests.removeWhere((r) => r.id == id);
        notifyListeners();
      },
    );
  }
  
  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}
