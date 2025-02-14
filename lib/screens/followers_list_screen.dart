import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/providers/follow_provider.dart';
import 'package:journal_app/screens/user_profile_page.dart';
import 'package:journal_app/screens/profile_page.dart';
import 'package:journal_app/widgets/user_avatar.dart';

class FollowersListScreen extends StatelessWidget {
  final String userId;
  
  const FollowersListScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Followers'),
      ),
      body: FutureBuilder<List<UserProfile>>(
        future: Provider.of<FollowProvider>(context, listen: false)
            .getFollowerUsers(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Error in followers list: ${snapshot.error}');
            return Center(
              child: Text('Error loading followers list'),
            );
          }
          
          final users = snapshot.data ?? [];
          print('Follower users count: ${users.length}'); // Debug print
          
          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No Followers Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your followers will appear here',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              print('Follower user: ${user.username}'); // Debug print
              return ListTile(
                leading: UserAvatar(
                  imageUrl: user.avatarUrl,
                  radius: 20,
                ),
                title: Text(user.username),
                onTap: () {
                  final currentUserId = Provider.of<AuthProvider>(context, listen: false).userProfile?.id;
                  if (currentUserId == user.id) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(userId: user.id),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
} 