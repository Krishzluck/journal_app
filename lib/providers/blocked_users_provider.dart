import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class BlockedUser {
  final String id;
  final String username;
  final String? avatarUrl;
  final DateTime blockedAt;

  BlockedUser({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.blockedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'avatarUrl': avatarUrl,
    'blockedAt': blockedAt.toIso8601String(),
  };

  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
    id: json['id'],
    username: json['username'],
    avatarUrl: json['avatarUrl'],
    blockedAt: DateTime.parse(json['blockedAt']),
  );
}

class BlockedUsersProvider extends ChangeNotifier {
  List<BlockedUser> _blockedUsers = [];
  List<BlockedUser> get blockedUsers => _blockedUsers;

  Future<void> loadBlockedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blockedUsersJson = prefs.getStringList('blockedUsers') ?? [];
      _blockedUsers = blockedUsersJson
          .map((json) => BlockedUser.fromJson(jsonDecode(json)))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error loading blocked users: $e');
    }
  }

  Future<void> blockUser(BlockedUser user) async {
    try {
      if (_blockedUsers.any((u) => u.id == user.id)) return;

      // Save to Supabase
      await Supabase.instance.client.from('blocked_users').insert({
        'blocked_user_id': user.id,
        'user_id': Supabase.instance.client.auth.currentUser!.id,
      });

      // Add to local list
      _blockedUsers.add(user);

      // Save to SharedPreferences
      await _saveToPrefs();
      
      notifyListeners();
    } catch (e) {
      print('Error blocking user: $e');
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      // Remove from Supabase
      await Supabase.instance.client
          .from('blocked_users')
          .delete()
          .match({
            'blocked_user_id': userId,
            'user_id': Supabase.instance.client.auth.currentUser!.id,
          });

      // Remove from local list
      _blockedUsers.removeWhere((user) => user.id == userId);

      // Save to SharedPreferences
      await _saveToPrefs();
      
      notifyListeners();
    } catch (e) {
      print('Error unblocking user: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final blockedUsersJson = _blockedUsers
        .map((user) => jsonEncode(user.toJson()))
        .toList();
    await prefs.setStringList('blockedUsers', blockedUsersJson);
  }

  bool isUserBlocked(String userId) {
    return _blockedUsers.any((user) => user.id == userId);
  }

  void clearData() {
    _blockedUsers = [];
    notifyListeners();
  }
} 