import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:journal_app/main.dart';  // For navigatorKey
import 'package:journal_app/screens/journal_details_page.dart';
import 'package:journal_app/screens/user_profile_page.dart';
import 'package:journal_app/screens/month_mood_screen.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:provider/provider.dart';

// This needs to be outside the class as a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages here
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Get FCM token
    String? token = await _fcm.getToken();
    if (token != null) {
      await saveDeviceToken(token);
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen(saveDeviceToken);

    // Set the background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(null, payload: details.payload);
      },
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Show local notification when app is in foreground
    log("FOREGROUND :- $message");
    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  void _handleNotificationTap(RemoteMessage? message, {String? payload}) {
    // Handle navigation based on notification type
    final data = message?.data ?? {};
    final type = data['type'];
    final referenceId = data['reference_id'];

    switch (type) {
      case 'comment':
        navigateToPost(referenceId);
        break;
      case 'new_journal':
        navigateToPost(referenceId);
        break;
      case 'follow':
        navigateToUserProfile(referenceId);
        break;
      case 'month_mood':
        navigateToMonthMood();
        break;
    }
  }

  Future<void> saveDeviceToken(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // First try to delete any existing token for this user
      await _supabase
        .from('device_tokens')
        .delete()
        .match({
          'user_id': userId,
          'device_token': token,
        });

      // Then insert the new token
      await _supabase.from('device_tokens').insert({
        'user_id': userId,
        'device_token': token,
      });
    } catch (e) {
      print('Error saving device token: $e');
    }
  }

  void navigateToPost(String postId) async {
    // Get the journal entry
    final journalProvider = Provider.of<JournalProvider>(
      navigatorKey.currentContext!,
      listen: false
    );
    
    final entry = await journalProvider.getJournalEntry(postId);
    if (entry != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => JournalDetailsPage(entry: entry),
        ),
      );
    }
  }

  void navigateToUserProfile(String userId) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => UserProfilePage(userId: userId),
      ),
    );
  }

  void navigateToMonthMood() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => MonthMoodScreen(),
      ),
    );
  }
} 