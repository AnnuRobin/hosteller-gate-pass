import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/parent_otp_model.dart';

class ParentOtpService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Generate and send OTP to parent
  Future<Map<String, dynamic>> generateOtp({
    required String gatePassRequestId,
    required String parentPhone,
  }) async {
    try {
      final response = await _supabase.rpc('create_parent_otp', params: {
        'p_gate_pass_request_id': gatePassRequestId,
        'p_parent_phone': parentPhone,
      });

      if (response != null && response.isNotEmpty) {
        return {
          'otp_code': response[0]['otp_code'],
          'expires_at': DateTime.parse(response[0]['expires_at']),
        };
      }
      
      throw Exception('Failed to generate OTP');
    } catch (e) {
      print('Error generating OTP: $e');
      rethrow;
    }
  }

  // Verify OTP
  Future<bool> verifyOtp({
    required String gatePassRequestId,
    required String otpCode,
  }) async {
    try {
      final response = await _supabase.rpc('verify_parent_otp', params: {
        'p_gate_pass_request_id': gatePassRequestId,
        'p_otp_code': otpCode,
      });

      return response as bool;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  // Get OTP details for a gate pass request
  Future<ParentOtpModel?> getOtpForRequest(String gatePassRequestId) async {
    try {
      final response = await _supabase
          .from('parent_otps')
          .select()
          .eq('gate_pass_request_id', gatePassRequestId)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      return ParentOtpModel.fromJson(response);
    } catch (e) {
      print('Error fetching OTP: $e');
      return null;
    }
  }

  // Resend OTP (generates new one)
  Future<Map<String, dynamic>> resendOtp({
    required String gatePassRequestId,
    required String parentPhone,
  }) async {
    return await generateOtp(
      gatePassRequestId: gatePassRequestId,
      parentPhone: parentPhone,
    );
  }

  // Check if OTP exists and is valid
  Future<bool> hasValidOtp(String gatePassRequestId) async {
    try {
      final otp = await getOtpForRequest(gatePassRequestId);
      if (otp == null) return false;
      
      return !otp.isExpired && !otp.isVerified;
    } catch (e) {
      return false;
    }
  }

  // Manually approve (for parent using app)
  Future<bool> approveByParent({
    required String gatePassRequestId,
    String? remarks,
  }) async {
    try {
      await _supabase.from('gate_pass_requests').update({
        'parent_approval_status': 'approved',
        'parent_approved_at': DateTime.now().toIso8601String(),
        'parent_remarks': remarks,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', gatePassRequestId);

      return true;
    } catch (e) {
      print('Error approving request: $e');
      return false;
    }
  }

  // Reject by parent
  Future<bool> rejectByParent({
    required String gatePassRequestId,
    String? remarks,
  }) async {
    try {
      await _supabase.from('gate_pass_requests').update({
        'parent_approval_status': 'rejected',
        'parent_remarks': remarks,
        'status': 'rejected',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', gatePassRequestId);

      return true;
    } catch (e) {
      print('Error rejecting request: $e');
      return false;
    }
  }
}
