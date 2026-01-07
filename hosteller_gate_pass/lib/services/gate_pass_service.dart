import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/gate_pass_model.dart';

class GatePassService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Create gate pass request
  Future<GatePassModel> createRequest({
    required String studentId,
    required String classId,
    required String departmentId,
    required String reason,
    required String destination,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final response = await _supabase
        .from('gate_pass_requests')
        .insert({
          'student_id': studentId,
          'class_id': classId,
          'department_id': departmentId,
          'reason': reason,
          'destination': destination,
          'from_date': fromDate.toIso8601String(),
          'to_date': toDate.toIso8601String(),
        })
        .select()
        .single();
    
    // Create notification for advisor
    await _createNotification(
      classId: classId,
      passRequestId: response['id'],
      title: 'New Gate Pass Request',
      message: 'A new gate pass request requires your approval',
      type: 'request_created',
    );
    
    return GatePassModel.fromJson(response);
  }
  
  // Get student's requests
  Future<List<GatePassModel>> getStudentRequests(String studentId) async {
    final response = await _supabase
        .from('gate_pass_requests')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => GatePassModel.fromJson(json))
        .toList();
  }
  
  // Get requests for advisor (by class)
  Future<List<GatePassModel>> getAdvisorRequests({
  required String classId,
  required String departmentId,
}) async {
  final response = await Supabase.instance.client
      .from('gate_pass_requests')
      .select()
      .eq('class_id', classId)
      .eq('department_id', departmentId)
      .order('created_at', ascending: false);

  return response
      .map<GatePassModel>((json) => GatePassModel.fromJson(json))
      .toList();
}

  
  // Get requests for HOD (by department)
  Future<List<GatePassModel>> getHodRequests(String departmentId) async {
    final response = await _supabase
        .from('gate_pass_requests')
        .select()
        .eq('department_id', departmentId)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => GatePassModel.fromJson(json))
        .toList();
  }
  
  // Update request (student edit)
  Future<void> updateRequest({
    required String requestId,
    String? reason,
    String? destination,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final updates = <String, dynamic>{};
    if (reason != null) updates['reason'] = reason;
    if (destination != null) updates['destination'] = destination;
    if (fromDate != null) updates['from_date'] = fromDate.toIso8601String();
    if (toDate != null) updates['to_date'] = toDate.toIso8601String();
    
    await _supabase
        .from('gate_pass_requests')
        .update(updates)
        .eq('id', requestId);
  }
  
  // Delete request
  Future<void> deleteRequest(String requestId) async {
    await _supabase
        .from('gate_pass_requests')
        .delete()
        .eq('id', requestId);
  }
  
  // Advisor approve/reject
  Future<void> advisorAction({
    required String requestId,
    required String advisorId,
    required bool approved,
    String? remarks,
  }) async {
    // Get request details first
    final request = await _supabase
        .from('gate_pass_requests')
        .select('student_id, department_id')
        .eq('id', requestId)
        .single();
    
    await _supabase
        .from('gate_pass_requests')
        .update({
          'advisor_status': approved ? 'approved' : 'rejected',
          'status': approved ? 'advisor_approved' : 'rejected',
          'advisor_id': advisorId,
          'advisor_approved_at': DateTime.now().toIso8601String(),
          'advisor_remarks': remarks,
          'parent_notified': approved, // Notify parent if approved
        })
        .eq('id', requestId);
    
    // Notify student
    await _supabase.from('notifications').insert({
      'user_id': request['student_id'],
      'pass_request_id': requestId,
      'title': approved ? 'Request Approved by Advisor' : 'Request Rejected',
      'message': approved
          ? 'Your gate pass request has been approved by your class advisor'
          : 'Your gate pass request has been rejected by your class advisor',
      'type': approved ? 'request_approved' : 'request_rejected',
    });
    
    // If approved, notify HOD
    if (approved) {
      await _createNotificationForHOD(
        departmentId: request['department_id'],
        passRequestId: requestId,
      );
    }
  }
  
  // HOD approve/reject
  Future<void> hodAction({
    required String requestId,
    required String hodId,
    required bool approved,
    String? remarks,
  }) async {
    // Get request details first
    final request = await _supabase
        .from('gate_pass_requests')
        .select('student_id')
        .eq('id', requestId)
        .single();
    
    await _supabase
        .from('gate_pass_requests')
        .update({
          'hod_status': approved ? 'approved' : 'rejected',
          'status': approved ? 'approved' : 'rejected',
          'hod_id': hodId,
          'hod_approved_at': DateTime.now().toIso8601String(),
          'hod_remarks': remarks,
        })
        .eq('id', requestId);
    
    // Notify student
    await _supabase.from('notifications').insert({
      'user_id': request['student_id'],
      'pass_request_id': requestId,
      'title': approved ? 'Request Fully Approved' : 'Request Rejected by HOD',
      'message': approved
          ? 'Your gate pass request has been fully approved. You can now use it.'
          : 'Your gate pass request has been rejected by the HOD',
      'type': approved ? 'request_approved' : 'request_rejected',
    });
  }
  
  // Get single request
  Future<GatePassModel> getRequest(String requestId) async {
    final response = await _supabase
        .from('gate_pass_requests')
        .select()
        .eq('id', requestId)
        .single();
    
    return GatePassModel.fromJson(response);
  }
  
  // Subscribe to realtime changes
  RealtimeChannel subscribeToRequests({
    String? studentId,
    String? classId,
    String? departmentId,
    required Function(GatePassModel) onInsert,
    required Function(GatePassModel) onUpdate,
    required Function(String) onDelete,
  }) {
    var query = _supabase
        .channel('gate_pass_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'gate_pass_requests',
          callback: (payload) {
            onInsert(GatePassModel.fromJson(payload.newRecord));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'gate_pass_requests',
          callback: (payload) {
            onUpdate(GatePassModel.fromJson(payload.newRecord));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'gate_pass_requests',
          callback: (payload) {
            onDelete(payload.oldRecord['id'] as String);
          },
        );
    
    return query.subscribe();
  }
  
  // Helper to create notification for advisor
  Future<void> _createNotification({
    required String classId,
    required String passRequestId,
    required String title,
    required String message,
    required String type,
  }) async {
    // Get advisor ID from class
    final classData = await _supabase
        .from('classes')
        .select('advisor_id')
        .eq('id', classId)
        .single();
    
    if (classData['advisor_id'] != null) {
      await _supabase.from('notifications').insert({
        'user_id': classData['advisor_id'],
        'pass_request_id': passRequestId,
        'title': title,
        'message': message,
        'type': type,
      });
    }
  }
  
  // Helper to create notification for HOD
  Future<void> _createNotificationForHOD({
    required String departmentId,
    required String passRequestId,
  }) async {
    // Get HOD ID from department
    final deptData = await _supabase
        .from('departments')
        .select('hod_id')
        .eq('id', departmentId)
        .single();
    
    if (deptData['hod_id'] != null) {
      await _supabase.from('notifications').insert({
        'user_id': deptData['hod_id'],
        'pass_request_id': passRequestId,
        'title': 'New Gate Pass Request',
        'message': 'A gate pass request approved by advisor needs your approval',
        'type': 'request_created',
      });
    }
  }
}