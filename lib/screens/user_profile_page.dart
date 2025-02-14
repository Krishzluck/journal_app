import 'package:flutter/material.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:journal_app/screens/journal_entry_page.dart';
import 'package:journal_app/widgets/journal_post_card.dart';
import 'package:journal_app/widgets/user_avatar.dart';
import 'package:provider/provider.dart';
import 'package:journal_app/providers/blocked_users_provider.dart';
import 'package:journal_app/widgets/shimmer_loading.dart';
import 'package:journal_app/providers/follow_provider.dart';
import 'package:journal_app/widgets/custom_button.dart';
import 'package:journal_app/screens/following_list_screen.dart';
import 'package:journal_app/screens/followers_list_screen.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  UserProfilePage({required this.userId});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final followProvider = Provider.of<FollowProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    await journalProvider.loadUserEntries(widget.userId);
    if (authProvider.userProfile != null) {
      await followProvider.loadFollowData(authProvider.userProfile!.id);
    }
    setState(() => _isInitialLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final journalProvider = Provider.of<JournalProvider>(context);
    final blockedUsersProvider = Provider.of<BlockedUsersProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<UserProfile?>(
          future: Provider.of<AuthProvider>(context, listen: false)
              .getUserProfile(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text('${snapshot.data!.username}');
            }
            return Text('Profile');
          },
        ),
        actions: [
          if (widget.userId != Provider.of<AuthProvider>(context).userProfile?.id)
            FutureBuilder<UserProfile?>(
              future: Provider.of<AuthProvider>(context, listen: false)
                  .getUserProfile(widget.userId),
              builder: (context, snapshot) {
                final userProfile = snapshot.data;
                final blockedUsersProvider = Provider.of<BlockedUsersProvider>(context);
                final isBlocked = blockedUsersProvider.isUserBlocked(widget.userId);

                return PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'block',
                      child: ListTile(
                        leading: Icon(
                          isBlocked ? Icons.block_outlined : Icons.block,
                          color: isBlocked ? Colors.grey : Colors.red,
                        ),
                        title: Text(
                          isBlocked ? 'Unblock User' : 'Block User',
                          style: TextStyle(
                            color: isBlocked ? Colors.grey : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'block') {
                      if (isBlocked) {
                        blockedUsersProvider.unblockUser(widget.userId);
                      } else if (userProfile != null) {
                        _blockUser(context, userProfile);
                      }
                    }
                  },
                );
              },
            ),
        ],
      ),
      body: _isInitialLoading
          ? ShimmerLoading(child: UserProfileShimmer())
          : FutureBuilder<UserProfile?>(
        future: authProvider.getUserProfile(widget.userId),
        builder: (context, userProfileSnapshot) {
          if (userProfileSnapshot.hasError) {
            return Center(child: Text('Error loading profile'));
          }
          final userProfile = userProfileSnapshot.data;
          if (userProfile == null) {
            return Center(child: Text('User not found'));
          }

          return Column(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                      SizedBox(height: 8),
                      Row(
                        children: [
                          // Left side: Avatar only (removed username)
                          Column(
                            children: [
                              UserAvatar(
                                imageUrl: userProfile.avatarUrl,
                      radius: 50,
                              ),
                            ],
                          ),
                          SizedBox(width: 24),
                          // Right side: Stats and Follow Button
                          Expanded(
                            child: Column(
                              children: [
                                Consumer2<FollowProvider, AuthProvider>(
                                  builder: (context, followProvider, authProvider, _) {
                                    final isFollowing = followProvider.isFollowing(widget.userId);
                                    final isFollower = followProvider.followerIds.contains(widget.userId);
                                    
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: isFollowing ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => FollowingListScreen(
                                                  userId: widget.userId,
                                                ),
                                              ),
                                            );
                                          } : () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('You need to follow this user to see their following list'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              FutureBuilder<int>(
                                                future: followProvider.getFollowingCount(widget.userId),
                                                builder: (context, snapshot) {
                                                  return Text(
                                                    snapshot.hasData ? snapshot.data.toString() : '0',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                },
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Following',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 24),
                                        GestureDetector(
                                          onTap: isFollowing ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => FollowersListScreen(
                                                  userId: widget.userId,
                                                ),
                                              ),
                                            );
                                          } : () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('You need to follow this user to see their followers list'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              FutureBuilder<int>(
                                                future: followProvider.getFollowerCount(widget.userId),
                                                builder: (context, snapshot) {
                                                  return Text(
                                                    snapshot.hasData ? snapshot.data.toString() : '0',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                },
                                              ),
                                              SizedBox(height: 4),
                    Text(
                                                'Followers',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                SizedBox(height: 12),
                                _buildFollowButton(context, userProfile),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<JournalEntry>>(
                  future: journalProvider.getUserPublicEntries(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: 5,
                        itemBuilder: (context, index) => 
                          ShimmerLoading(child: JournalCardShimmer()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error loading journals'));
                    }

                    final entries = snapshot.data ?? [];
                    if (entries.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No Public Journals',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return journalProvider.isLoading
                        ? ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: 5,
                            itemBuilder: (context, index) => 
                              ShimmerLoading(child: JournalCardShimmer()),
                          )
                        : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return JournalPostCard(
                          entry: entry,
                                username: userProfile.username,
                                avatarUrl: userProfile.avatarUrl,
                          onMenuPressed: entry.userId == authProvider.userProfile?.id
                              ? () => _showEntryOptions(context, entry)
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _blockUser(BuildContext context, UserProfile userProfile) {
    final blockedUsersProvider = Provider.of<BlockedUsersProvider>(context, listen: false);
    blockedUsersProvider.blockUser(
      BlockedUser(
        id: widget.userId,
        username: userProfile.username,
        avatarUrl: userProfile.avatarUrl,
        blockedAt: DateTime.now(),
      ),
    );
  }

  void _showEntryOptions(BuildContext context, JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JournalEntryPage(entry: entry),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(context, entry);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, JournalEntry entry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Entry'),
          content: Text('Are you sure you want to delete this entry?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Provider.of<JournalProvider>(context, listen: false)
                    .deleteEntry(entry.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFollowButton(BuildContext context, UserProfile userProfile) {
    final followProvider = Provider.of<FollowProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.userProfile?.id;

    if (currentUserId == null || currentUserId == userProfile.id) {
      return SizedBox.shrink();
    }

    final isFollowing = followProvider.isFollowing(userProfile.id);

    return SizedBox(
      width: 140,
      child: CustomButton(
        text: isFollowing ? 'Unfollow' : 'Follow',
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        onPressed: () {
          if (isFollowing) {
            followProvider.unfollowUser(currentUserId, userProfile.id);
          } else {
            followProvider.followUser(currentUserId, userProfile.id);
          }
        },
      ),
    );
  }
}

