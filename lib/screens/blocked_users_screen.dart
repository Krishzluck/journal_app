import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:journal_app/providers/blocked_users_provider.dart';
import 'package:journal_app/widgets/user_avatar.dart';

class BlockedUsersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blocked Users'),
      ),
      body: Consumer<BlockedUsersProvider>(
        builder: (context, blockedUsersProvider, child) {
          if (blockedUsersProvider.blockedUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.block_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No Blocked Users',
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

          return ListView.builder(
            itemCount: blockedUsersProvider.blockedUsers.length,
            itemBuilder: (context, index) {
              final user = blockedUsersProvider.blockedUsers[index];
              return ListTile(
                leading: UserAvatar(
                  imageUrl: user.avatarUrl,
                  radius: 20,
                ),
                title: Text(user.username),
                trailing: TextButton(
                  onPressed: () => blockedUsersProvider.unblockUser(user.id),
                  child: Text(
                    'Unblock',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 