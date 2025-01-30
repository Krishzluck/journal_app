import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:journal_app/screens/journal_entry_page.dart';
import 'package:journal_app/screens/profile_page.dart';
import 'package:journal_app/screens/settings_screen.dart';
import 'package:journal_app/widgets/journal_post_card.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JournalProvider>(context, listen: false).loadGlobalEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final journalProvider = Provider.of<JournalProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Journal App'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(authProvider.userProfile?.username ?? 'User'),
              accountEmail: Text(authProvider.userProfile?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage: authProvider.userProfile?.avatarUrl != null
                    ? CachedNetworkImageProvider(authProvider.userProfile!.avatarUrl!)
                    : null,
                child: authProvider.userProfile?.avatarUrl == null
                    ? Icon(Icons.person)
                    : null,
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () => _showLogoutDialog(context),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: journalProvider.globalEntries.length,
        itemBuilder: (context, index) {
          final entry = journalProvider.globalEntries[index];
          return FutureBuilder<UserProfile?>(
            future: authProvider.getUserProfile(entry.userId),
            builder: (context, snapshot) {
              final userProfile = snapshot.data;
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => JournalEntryPage()),
        ),
        child: Icon(Icons.add),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<AuthProvider>(context, listen: false).signOut();
              },
            ),
          ],
        );
      },
    );
  }
}