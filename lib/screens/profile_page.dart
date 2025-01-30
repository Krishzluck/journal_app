import 'package:flutter/material.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:journal_app/screens/edit_profile_page.dart';
import 'package:journal_app/screens/journal_entry_page.dart';
import 'package:journal_app/widgets/custom_button.dart';
import 'package:journal_app/widgets/journal_post_card.dart';
import 'package:journal_app/widgets/user_avatar.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userProfile != null) {
        Provider.of<JournalProvider>(context, listen: false)
            .loadUserEntries(authProvider.userProfile!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final journalProvider = Provider.of<JournalProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                UserAvatar(
                  imageUrl: authProvider.userProfile?.avatarUrl,
                  radius: 50,
                ),
                SizedBox(height: 16),
                Text(
                  authProvider.userProfile?.username ?? 'User',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: 140,
                    child: CustomButton(
                      text: 'Edit Profile',
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditProfilePage()),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
          child: ListView.builder(
            itemCount: journalProvider.userEntries.length,
            itemBuilder: (context, index) {
              final entry = journalProvider.userEntries[index];
              return JournalPostCard(
                entry: entry,
                username: authProvider.userProfile?.username ?? 'User',
                avatarUrl: authProvider.userProfile?.avatarUrl,
                onMenuPressed: () => _showEntryOptions(context, entry),
              );
            },
          ),
        ),
        ],
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

