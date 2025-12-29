import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service = NotificationService();
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  RealtimeChannel? _subscription;
  
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  
  Future<void> loadNotifications(String userId) async {
    try {
      _notifications = await _service.getUserNotifications(userId);
      _unreadCount = await _service.getUnreadCount(userId);
      _setupRealtimeSubscription(userId);
    } catch (e) {
      print('Error loading notifications: $e');
    }
    notifyListeners();
  }
  
  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = NotificationModel(
        id: _notifications[index].id,
        userId: _notifications[index].userId,
        passRequestId: _notifications[index].passRequestId,
        title: _notifications[index].title,
        message: _notifications[index].message,
        type: _notifications[index].type,
        read: true,
        createdAt: _notifications[index].createdAt,
      );
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      notifyListeners();
    }
  }
  
  Future<void> markAllAsRead(String userId) async {
    await _service.markAllAsRead(userId);
    _notifications = _notifications.map((n) => NotificationModel(
      id: n.id,
      userId: n.userId,
      passRequestId: n.passRequestId,
      title: n.title,
      message: n.message,
      type: n.type,
      read: true,
      createdAt: n.createdAt,
    )).toList();
    _unreadCount = 0;
    notifyListeners();
  }
  
  void _setupRealtimeSubscription(String userId) {
    _subscription?.unsubscribe();
    
    _subscription = _service.subscribeToNotifications(
      userId: userId,
      onNewNotification: (notification) {
        _notifications.insert(0, notification);
        _unreadCount++;
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