import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Get user notifications
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => NotificationModel.fromJson(json))
        .toList();
  }
  
  // Get unread count
  Future<int> getUnreadCount(String userId) async {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('read', false);
    
    return (response as List).length;
  }
  
  // Mark as read
  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
  }
  
  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    await _supabase
        .from('notifications')
        .update({'read': true})
        .eq('user_id', userId);
  }
  
  // Subscribe to realtime notifications
  RealtimeChannel subscribeToNotifications({
    required String userId,
    required Function(NotificationModel) onNewNotification,
  }) {
    return _supabase
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            onNewNotification(NotificationModel.fromJson(payload.newRecord));
          },
        )
        .subscribe();
  }
}