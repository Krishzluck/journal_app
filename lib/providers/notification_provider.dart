import 'package:flutter/material.dart';
import 'package:journal_app/models/notification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<UserNotification> _notifications = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  List<UserNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  Future<void> fetchNotifications() async {
    if (_supabase.auth.currentUser == null) return;
    
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser!.id;
      
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      
      _notifications = (response as List<dynamic>).map((data) {
        return UserNotification.fromJson(data);
      }).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Failed to fetch notifications: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final notification = _notifications[index];
        _notifications[index] = UserNotification(
          id: notification.id,
          userId: notification.userId,
          title: notification.title,
          body: notification.body,
          type: notification.type,
          referenceId: notification.referenceId,
          createdAt: notification.createdAt,
          isRead: true,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_supabase.auth.currentUser == null) return;
    
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      
      // Update local state
      _notifications = _notifications.map((notification) => 
        UserNotification(
          id: notification.id,
          userId: notification.userId,
          title: notification.title,
          body: notification.body,
          type: notification.type,
          referenceId: notification.referenceId,
          createdAt: notification.createdAt,
          isRead: true,
        )
      ).toList();
      
      notifyListeners();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  int get unreadCount {
    return _notifications.where((notification) => !notification.isRead).length;
  }
}
