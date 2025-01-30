import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:journal_app/screens/journal_entry_page.dart';
import 'package:journal_app/widgets/journal_post_card.dart';
import 'package:provider/provider.dart';

class UserProfilePage extends StatelessWidget {
  final String userId;

  UserProfilePage({required this.userId});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final journalProvider = Provider.of<JournalProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
      ),
      body: FutureBuilder<UserProfile?>(
        future: authProvider.getUserProfile(userId),
        builder: (context, userProfileSnapshot) {
          if (userProfileSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (userProfileSnapshot.hasError) {
            return Center(child: Text('Error loading user profile'));
          }
          final userProfile = userProfileSnapshot.data;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: userProfile?.avatarUrl != null
                          ? CachedNetworkImageProvider(userProfile!.avatarUrl!)
                          : null,
                      child: userProfile?.avatarUrl == null
                          ? Icon(Icons.person, size: 50)
                          : null,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '@${userProfile?.username ?? ''}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<JournalEntry>>(
                  future: journalProvider.getUserPublicEntries(userId),
                  builder: (context, entriesSnapshot) {
                    if (entriesSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (entriesSnapshot.hasError) {
                      return Center(child: Text('Error loading entries'));
                    }
                    final entries = entriesSnapshot.data ?? [];

                    return ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return JournalPostCard(
                          entry: entry,
                          username: userProfile?.username ?? 'User',
                          avatarUrl: userProfile?.avatarUrl,
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
}

