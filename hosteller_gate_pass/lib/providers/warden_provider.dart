import 'package:flutter/material.dart';
import '../services/gate_pass_service.dart';
import '../models/gate_pass_model.dart';

class WardenProvider with ChangeNotifier {
  final GatePassService _service = GatePassService();
  List<GatePassModel> _requests = [];
  bool _isLoading = false;

  List<GatePassModel> get requests => _requests;
  bool get isLoading => _isLoading;

  // Get pending requests (HOD approved, waiting for warden)
  List<GatePassModel> get pendingWardenRequests => _requests
      .where((r) => r.hodStatus == 'approved' && r.wardenStatus == 'pending')
      .toList();

  // Get completed requests
  List<GatePassModel> get completedRequests =>
      _requests.where((r) => r.finalStatus != null).toList();

  // Get active passes (warden approved but not returned)
  List<GatePassModel> get activePassess => _requests
      .where((r) => r.wardenStatus == 'approved' && r.entryTime == null)
      .toList();

  Future<void> loadWardenRequests() async {
    _isLoading = true;
    notifyListeners();

    try {
      _requests = await _service.getWardenRequests();
    } catch (e) {
      debugPrint('Error loading warden requests: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Warden action - final approval and setting exit time
  Future<void> wardenApprove({
    required String requestId,
    required String wardenId,
    DateTime? exitTime,
  }) async {
    await _service.wardenAction(
      requestId: requestId,
      wardenId: wardenId,
      approved: true,
      exitTime: exitTime ?? DateTime.now(),
    );
    // Reload requests after action
    await loadWardenRequests();
  }

  // Warden action - denial
  Future<void> wardenReject({
    required String requestId,
    required String wardenId,
    String? remarks,
  }) async {
    await _service.wardenAction(
      requestId: requestId,
      wardenId: wardenId,
      approved: false,
      remarks: remarks,
    );
    // Reload requests after action
    await loadWardenRequests();
  }

  // Record student entry time
  Future<void> recordEntryTime({
    required String requestId,
    DateTime? entryTime,
  }) async {
    await _service.recordEntryTime(
      requestId: requestId,
      entryTime: entryTime ?? DateTime.now(),
    );
    // Reload requests after action
    await loadWardenRequests();
  }

  // Update final status (granted or denied)
  Future<void> updateFinalStatus({
    required String requestId,
    required String finalStatus,
    String? remarks,
  }) async {
    await _service.updateFinalStatus(
      requestId: requestId,
      finalStatus: finalStatus,
      remarks: remarks,
    );
    // Reload requests after action
    await loadWardenRequests();
  }
}
