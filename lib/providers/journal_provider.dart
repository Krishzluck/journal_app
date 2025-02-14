import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:journal_app/providers/blocked_users_provider.dart';

final Map<String, Color> moodColors = {
  'Happy': Colors.green,
  'Sad': Colors.red,
  'Excited': Colors.green,
  'Frustrated': Colors.red,
  'Neutral': Color(0xFFF0C118),  // Changed to #F0C118
  'Angry': Colors.red,
  'Very Happy': Colors.green,
};

class JournalEntry {
  final String id;
  final String title;
  final String content;
  final String mood;
  final DateTime createdAt;
  final bool isPublic;
  final String userId;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.mood,
    required this.createdAt,
    required this.isPublic,
    required this.userId,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      mood: json['mood'],
      createdAt: DateTime.parse(json['created_at']),
      isPublic: json['is_public'] ?? false,
      userId: json['user_id'],
    );
  }
}

class Comment {
  final String id;
  final String content;
  final String userId;
  final String journalEntryId;
  final DateTime createdAt;
  String? userName;
  String? userAvatarUrl;

  Comment({
    required this.id,
    required this.content,
    required this.userId,
    required this.journalEntryId,
    required this.createdAt,
    this.userName,
    this.userAvatarUrl,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      content: json['content'],
      userId: json['user_id'],
      journalEntryId: json['journal_entry_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class JournalProvider extends ChangeNotifier {
  List<JournalEntry> _globalEntries = [];
  List<JournalEntry> _userEntries = [];
  List<JournalEntry> _savedEntries = [];  // New list for saved entries
  List<JournalEntry> _followingEntries = [];
  List<JournalEntry> _followerEntries = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<JournalEntry> get globalEntries => _globalEntries;
  List<JournalEntry> get userEntries => _userEntries;
  List<JournalEntry> get savedEntries => _savedEntries;
  List<JournalEntry> get followingEntries => _followingEntries;
  List<JournalEntry> get followerEntries => _followerEntries;

  Future<void> loadGlobalEntries(List<BlockedUser> blockedUsers) async {
    try {
      _isLoading = true;
      notifyListeners();

      final blockedUserIds = blockedUsers.map((u) => u.id).toList();

      final response = await Supabase.instance.client
          .from('journal_entries')
          .select()
          .eq('is_public', true)
          .not('user_id', 'in', blockedUserIds)
          .order('created_at', ascending: false);

      _globalEntries = (response as List<dynamic>)
          .map((entry) => JournalEntry.fromJson(entry))
          .toList();
      notifyListeners();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error loading global entries: $e');
    }
  }

  Future<void> loadUserEntries(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('journal_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _userEntries = (response as List<dynamic>)
          .map((entry) => JournalEntry.fromJson(entry))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error loading user entries: $e');
    }
  }

  Future<List<JournalEntry>> getUserPublicEntries(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('journal_entries')
          .select()
          .eq('user_id', userId)
          .eq('is_public', true)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((entry) => JournalEntry.fromJson(entry))
          .toList();
    } catch (e) {
      print('Error loading user public entries: $e');
      return [];
    }
  }

  Future<void> addEntry(String title, String content, String mood, bool isPublic) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client.from('journal_entries').insert({
        'title': title,
        'content': content,
        'mood': mood,
        'is_public': isPublic,
        'user_id': user.id,
      }).select();

      if (response.isNotEmpty) {
        final newEntry = JournalEntry.fromJson(response.first);
        _userEntries.insert(0, newEntry);
        if (isPublic) {
          _globalEntries.insert(0, newEntry);
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error adding entry: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateEntry(String id, String title, String content, String mood, bool isPublic) async {
    _isLoading = true;
    notifyListeners();
    try {
      await Supabase.instance.client.from('journal_entries').update({
        'title': title,
        'content': content,
        'mood': mood,
        'is_public': isPublic,
      }).match({'id': id});

      final userIndex = _userEntries.indexWhere((entry) => entry.id == id);
      final globalIndex = _globalEntries.indexWhere((entry) => entry.id == id);

      if (userIndex != -1) {
        _userEntries[userIndex] = JournalEntry(
          id: id,
          title: title,
          content: content,
          mood: mood,
          createdAt: _userEntries[userIndex].createdAt,
          isPublic: isPublic,
          userId: _userEntries[userIndex].userId,
        );
      }

      if (globalIndex != -1) {
        if (isPublic) {
          _globalEntries[globalIndex] = JournalEntry(
            id: id,
            title: title,
            content: content,
            mood: mood,
            createdAt: _globalEntries[globalIndex].createdAt,
            isPublic: isPublic,
            userId: _globalEntries[globalIndex].userId,
          );
        } else {
          _globalEntries.removeAt(globalIndex);
        }
      } else if (isPublic) {
        _globalEntries.insert(0, _userEntries[userIndex]);
      }

      notifyListeners();
    } catch (e) {
      print('Error updating entry: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await Supabase.instance.client.from('journal_entries').delete().match({'id': id});
      _userEntries.removeWhere((entry) => entry.id == id);
      _globalEntries.removeWhere((entry) => entry.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting entry: $e');
    }
  }

  Future<List<Comment>> getCommentsForEntry(String entryId) async {
    try {
      final response = await Supabase.instance.client
          .from('comments')
          .select('''
          *,
          profiles:user_id (
            username,
            avatar_url
          )
        ''')
          .eq('journal_entry_id', entryId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>).map((commentData) {
        final profiles = commentData['profiles'] as Map<String, dynamic>;
        final comment = Comment.fromJson(commentData);
        comment.userName = profiles['username'];
        comment.userAvatarUrl = profiles['avatar_url'];
        return comment;
      }).toList();
    } catch (e) {
      print('Error loading comments: $e');
      return [];
    }
  }

  Future<Comment> addComment(String entryId, String content) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return Comment.fromJson({});

    try {
      final response = await Supabase.instance.client.from('comments').insert({
        'journal_entry_id': entryId,
        'content': content,
        'user_id': user.id,
      }).select();

      return Comment.fromJson(response[0]);
    } catch (e) {
      print('Error adding comment: $e');
      return Comment.fromJson({});
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await Supabase.instance.client
          .from('comments')
          .delete()
          .eq('id', commentId);
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }

  // Add method to save/unsave journal
  Future<void> toggleSaveJournal(JournalEntry entry) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final isSaved = _savedEntries.any((e) => e.id == entry.id);
      
      if (isSaved) {
        // Remove from saved
        await Supabase.instance.client
            .from('saved_journals')
            .delete()
            .match({
              'user_id': user.id,
              'journal_id': entry.id,
            });
        _savedEntries.removeWhere((e) => e.id == entry.id);
      } else {
        // Add to saved
        await Supabase.instance.client
            .from('saved_journals')
            .insert({
              'user_id': user.id,
              'journal_id': entry.id,
            });
        _savedEntries.add(entry);
      }
      notifyListeners();
    } catch (e) {
      print('Error toggling save journal: $e');
    }
  }

  // Load saved journals
  Future<void> loadSavedJournals() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('saved_journals')
          .select('''
            journal_id,
            journal_entries!inner (*)
          ''')
          .eq('user_id', user.id);

      _savedEntries = (response as List<dynamic>)
          .map((data) => JournalEntry.fromJson(data['journal_entries']))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error loading saved journals: $e');
    }
  }

  Future<void> loadFollowingEntries(String userId, List<String> followingIds) async {
    try {
      final data = await Supabase.instance.client
          .from('journal_entries')
          .select()
          .eq('is_public', true)
          .inFilter('user_id', followingIds)
          .order('created_at', ascending: false);

      _followingEntries = data.map((item) => JournalEntry.fromJson(item)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading following entries: $e');
    }
  }

  Future<void> loadFollowerEntries(String userId, List<String> followerIds) async {
    try {
      final data = await Supabase.instance.client
          .from('journal_entries')
          .select()
          .eq('is_public', true)
          .inFilter('user_id', followerIds)
          .order('created_at', ascending: false);

      _followerEntries = data.map((item) => JournalEntry.fromJson(item)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading follower entries: $e');
    }
  }

  void clearData() {
    _globalEntries = [];
    _userEntries = [];
    _savedEntries = [];
    _followingEntries = [];
    _followerEntries = [];
    notifyListeners();
  }
}

