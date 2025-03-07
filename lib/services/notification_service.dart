import 'dart:convert';
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
        print('Received notification response with payload: ${details.payload}');
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
    Map<String, dynamic> data = {};
    
    if (payload != null && payload.isNotEmpty) {
      print('Raw payload: $payload');
      
      // For the specific format: {reference_id: 75e244c9-44fa-4a90-9a8d-198bdf936c85, type: comment}
      if (payload.contains('reference_id:') && payload.contains('type:')) {
        // Extract reference_id
        final referenceIdRegex = RegExp(r'reference_id:\s*([\w-]+)');
        final referenceIdMatch = referenceIdRegex.firstMatch(payload);
        if (referenceIdMatch != null && referenceIdMatch.groupCount >= 1) {
          final referenceId = referenceIdMatch.group(1);
          if (referenceId != null) {
            data['reference_id'] = referenceId;
          }
        }
        
        // Extract type
        final typeRegex = RegExp(r'type:\s*(\w+)');
        final typeMatch = typeRegex.firstMatch(payload);
        if (typeMatch != null && typeMatch.groupCount >= 1) {
          final type = typeMatch.group(1);
          if (type != null) {
            data['type'] = type;
          }
        }
        
        print('Extracted data from payload: $data');
      } else {
        // Try to decode as JSON as a fallback
        try {
          data = Map<String, dynamic>.from(jsonDecode(payload));
          print('Decoded JSON notification payload: $data');
        } catch (e) {
          print('Failed to parse payload as JSON: $e');
        }
      }
    } else if (message != null) {
      data = message.data;
    }
    
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
  
  // Method to create a notification in the database
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? referenceId,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'reference_id': referenceId,
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }
  
  // Create a comment notification
  Future<void> createCommentNotification({
    required String postOwnerId,
    required String commenterName,
    required String postTitle,
    required String postId,
  }) async {
    // Don't create notification if commenter is the post owner
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == postOwnerId) return;
    
    await createNotification(
      userId: postOwnerId,
      title: 'New Comment',
      body: '$commenterName commented on your post "$postTitle"',
      type: 'comment',
      referenceId: postId,
    );
  }
  
  // Create a new post notification for all followers
  Future<void> createNewPostNotifications({
    required String postId,
    required String postTitle,
    required String authorName,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;
    
    try {
      // Get all followers of the current user
      final followersData = await _supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', currentUserId);
      
      final followerIds = followersData
          .map<String>((item) => item['follower_id'] as String)
          .toList();
      
      // Create a notification for each follower
      for (final followerId in followerIds) {
        await createNotification(
          userId: followerId,
          title: 'New Post',
          body: '$authorName shared a new post: "$postTitle"',
          type: 'new_journal',
          referenceId: postId,
        );
      }
    } catch (e) {
      print('Error creating new post notifications: $e');
    }
  }
  
  // Create a follow notification
  Future<void> createFollowNotification({
    required String targetUserId,
    required String followerName,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;
    
    await createNotification(
      userId: targetUserId,
      title: 'New Follower',
      body: '$followerName started following you',
      type: 'follow',
      referenceId: currentUserId,
    );
  }
} 