import 'package:flutter/material.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/providers/blocked_users_provider.dart';
import 'package:journal_app/screens/user_profile_page.dart';
import 'package:journal_app/widgets/common_text_field.dart';
import 'package:journal_app/widgets/user_avatar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class RecentSearch {
  final String id;
  final String username;
  final String? avatarUrl;
  final DateTime searchedAt;

  RecentSearch({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.searchedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'avatarUrl': avatarUrl,
    'searchedAt': searchedAt.toIso8601String(),
  };

  factory RecentSearch.fromJson(Map<String, dynamic> json) => RecentSearch(
    id: json['id'],
    username: json['username'],
    avatarUrl: json['avatarUrl'],
    searchedAt: DateTime.parse(json['searchedAt']),
  );
}

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  List<RecentSearch> _recentSearches = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recentSearches') ?? [];
    setState(() {
      _recentSearches = searches
          .map((s) => RecentSearch.fromJson(jsonDecode(s)))
          .toList()
        ..sort((a, b) => b.searchedAt.compareTo(a.searchedAt));
    });
  }

  Future<void> _saveRecentSearch(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove if already exists
    _recentSearches.removeWhere((s) => s.id == user.id);
    
    // Add to start
    _recentSearches.insert(0, RecentSearch(
      id: user.id,
      username: user.username,
      avatarUrl: user.avatarUrl,
      searchedAt: DateTime.now(),
    ));

    // Keep only last 10 searches
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }

    // Save to prefs
    await prefs.setStringList(
      'recentSearches',
      _recentSearches.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  Future<void> _removeRecentSearch(String userId) async {
    setState(() {
      _recentSearches.removeWhere((search) => search.id == userId);
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'recentSearches',
      _recentSearches.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .ilike('username', '%$query%')
          .limit(20);

      final blockedUserIds = Provider.of<BlockedUsersProvider>(context, listen: false)
          .blockedUsers
          .map((u) => u.id)
          .toList();

      setState(() {
        _searchResults = (response as List<dynamic>)
            .map((data) => UserProfile.fromJson(data))
            .where((user) => !blockedUserIds.contains(user.id))
            .toList();
      });
    } catch (e) {
      print('Error searching users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToProfile(UserProfile user) async {
    await _saveRecentSearch(user);
    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(userId: user.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CommonTextField(
              controller: _searchController,
              labelText: 'Search users',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        _searchUsers('');
                      },
                    )
                  : null,
              onChanged: _searchUsers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _searchController.text.isEmpty
                    ? _recentSearches.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Search Users',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Find people to follow',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _recentSearches.length,
                            itemBuilder: (context, index) {
                              final search = _recentSearches[index];
                              return ListTile(
                                leading: UserAvatar(
                                  imageUrl: search.avatarUrl,
                                  radius: 20,
                                ),
                                title: Text(search.username),
                                trailing: IconButton(
                                  icon: Icon(Icons.close, color: Colors.grey[600]),
                                  onPressed: () => _removeRecentSearch(search.id),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserProfilePage(userId: search.id),
                                    ),
                                  );
                                },
                              );
                            },
                          )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No Users Found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              return ListTile(
                                leading: UserAvatar(
                                  imageUrl: user.avatarUrl,
                                  radius: 20,
                                ),
                                title: Text(user.username),
                                onTap: () => _navigateToProfile(user),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
} 