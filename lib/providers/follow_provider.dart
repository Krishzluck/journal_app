import 'package:flutter/foundation.dart';
import 'package:journal_app/main.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

class FollowProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<String> _followingIds = [];
  List<String> _followerIds = [];

  List<String> get followingIds => _followingIds;
  List<String> get followerIds => _followerIds;

  bool isFollowing(String userId) => _followingIds.contains(userId);

  Future<void> loadFollowData(String userId) async {
    try {
      // Load following
      final followingData = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);
      
      _followingIds = followingData
          .map<String>((item) => item['following_id'] as String)
          .toList();

      // Load followers
      final followerData = await _supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId);
      
      _followerIds = followerData
          .map<String>((item) => item['follower_id'] as String)
          .toList();

      notifyListeners();
    } catch (e) {
      print('Error loading follow data: $e');
    }
  }

  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      await _supabase.from('follows').insert({
        'follower_id': currentUserId,
        'following_id': targetUserId,
      });

      _followingIds.add(targetUserId);
      
      // Reload entries after following
      final journalProvider = Provider.of<JournalProvider>(
        navigatorKey.currentContext!, 
        listen: false
      );
      await journalProvider.loadFollowingEntries(currentUserId, _followingIds);
      
      notifyListeners();
    } catch (e) {
      print('Error following user: $e');
    }
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      await _supabase
          .from('follows')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId);

      _followingIds.remove(targetUserId);
      
      // Reload entries after unfollowing
      final journalProvider = Provider.of<JournalProvider>(
        navigatorKey.currentContext!, 
        listen: false
      );
      await journalProvider.loadFollowingEntries(currentUserId, _followingIds);
      
      notifyListeners();
    } catch (e) {
      print('Error unfollowing user: $e');
    }
  }

  Future<List<UserProfile>> getFollowingUsers(String userId) async {
    try {
      final data = await _supabase
          .from('follows')
          .select('''
            following_id,
            following:profiles!following_id(*)
          ''')
          .eq('follower_id', userId);
      
      print('Following data: $data'); // Debug print
      
      if (data == null || (data as List).isEmpty) {
        return [];
      }

      return data.map<UserProfile>((item) {
        final profileData = item['following'] as Map<String, dynamic>;
        return UserProfile.fromJson(profileData);
      }).toList();
    } catch (e) {
      print('Error getting following users: $e');
      rethrow; // This will help us see the full error
    }
  }

  Future<List<UserProfile>> getFollowerUsers(String userId) async {
    try {
      // First get the follower IDs
      final data = await _supabase
          .from('follows')
          .select('''
            follower_id,
            profiles!follows_follower_id_fkey(
              id,
              email,
              username,
              avatar_url,
              created_at
            )
          ''')
          .eq('following_id', userId);
      
      print('Raw follower data: $data'); // Debug print
      
      if (data == null || (data as List).isEmpty) {
        return [];
      }

      return data.map<UserProfile>((item) {
        try {
          final profileData = item['profiles'] as Map<String, dynamic>;
          return UserProfile.fromJson(profileData);
        } catch (e) {
          print('Error parsing follower data: $e');
          print('Profile data being parsed: ${item['profiles']}');
          rethrow;
        }
      }).toList();
    } catch (e) {
      print('Error getting follower users: $e');
      rethrow;
    }
  }

  Future<int> getFollowingCount(String userId) async {
    final data = await _supabase
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);
    return (data as List).length;
  }

  Future<int> getFollowerCount(String userId) async {
    final data = await _supabase
        .from('follows')
        .select('follower_id')
        .eq('following_id', userId);
    return (data as List).length;
  }
} 