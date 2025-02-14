import 'package:flutter/material.dart';
import 'package:journal_app/main.dart';
import 'package:journal_app/providers/blocked_users_provider.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:journal_app/providers/follow_provider.dart';

class UserProfile {
  final String id;
  final String email;
  String username;
  String? avatarUrl;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
    );
  }
}

class AuthProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadUserProfileFromPrefs();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await _loadUserProfile();
    }
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user != null) {
        await _loadUserProfile();
      } else {
        _userProfile = null;
        await _clearUserProfileFromPrefs();
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserProfileFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userProfileJson = prefs.getString('userProfile');
    if (userProfileJson != null) {
      _userProfile = UserProfile.fromJson(json.decode(userProfileJson));
      notifyListeners();
    }
  }

  Future<void> _saveUserProfileToPrefs() async {
    if (_userProfile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userProfile', json.encode(_userProfile!.toJson()));
    }
  }

  Future<void> _clearUserProfileFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userProfile');
  }

  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      if (response != null) {
        _userProfile = UserProfile(
          id: user.id,
          email: user.email!,
          username: response['username'],
          avatarUrl: response['avatar_url'],
          createdAt: DateTime.parse(user.createdAt),
        );
        await _saveUserProfileToPrefs();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> updateProfile({String? username, String? avatarUrl}) async {
    _isLoading = true;
    notifyListeners();
    if (_userProfile == null) return;

    final updates = {
      if (username != null) 'username': username,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };

    try {
      await Supabase.instance.client
          .from('profiles')
          .upsert({'id': _userProfile!.id, ...updates});

      if (username != null) _userProfile!.username = username;
      _userProfile!.avatarUrl = avatarUrl ?? _userProfile!.avatarUrl;
      await _saveUserProfileToPrefs();
      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadProfilePicture(String filePath) async {
    try {
      final fileName = '${_userProfile!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      final fileExt = filePath.split('.').last;

      final response = await Supabase.instance.client.storage
          .from('profile-pictures')
          .uploadBinary(fileName, fileBytes, fileOptions: FileOptions(contentType: 'image/$fileExt'));

      if (response != null) {
        final String publicUrl = Supabase.instance.client.storage
            .from('profile-pictures')
            .getPublicUrl(fileName);
        return publicUrl;
      }
    } catch (e) {
      print('Error uploading profile picture: $e');
    }
    return null;
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await _loadUserProfile();
      }
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String username) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await Supabase.instance.client.from('profiles').insert({
          'id': response.user!.id,
          'username': username,
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
        });
        await _loadUserProfile();
      } else {
        throw Exception('Failed to create user');
      }
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      _userProfile = null;

      // Clear providers
      Provider.of<JournalProvider>(context, listen: false).clearData();
      Provider.of<BlockedUsersProvider>(context, listen: false).clearData();

      // Clear SharedPreferences except theme
      final prefs = await SharedPreferences.getInstance();
      final themeMode = prefs.getString('themeMode');
      await prefs.clear();
      if (themeMode != null) {
        await prefs.setString('themeMode', themeMode);
      }

      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  Future<bool> isUsernameTaken(String username) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('username', username)
          .single();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      if (response != null) {
        return UserProfile(
          id: userId,
          email: response['email'] ?? '',
          username: response['username'] ?? '',
          avatarUrl: response['avatar_url'],
          createdAt: DateTime.parse(response['created_at']),
        );
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    return currentUser != null;
  }

  Future<void> loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
        _userProfile = UserProfile.fromJson(data);
        
        // Load follow data after getting user profile
        await Provider.of<FollowProvider>(navigatorKey.currentContext!, listen: false)
            .loadFollowData(_userProfile!.id);
            
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }
}

