import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:journal_app/widgets/journal_post_card.dart';

class SavedJournalsScreen extends StatefulWidget {
  @override
  _SavedJournalsScreenState createState() => _SavedJournalsScreenState();
}

class _SavedJournalsScreenState extends State<SavedJournalsScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<JournalProvider>(context, listen: false).loadSavedJournals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Journals'),
      ),
      body: Consumer<JournalProvider>(
        builder: (context, journalProvider, child) {
          if (journalProvider.savedEntries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No Saved Journals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Save journals to read them later',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: journalProvider.savedEntries.length,
            itemBuilder: (context, index) {
              final entry = journalProvider.savedEntries[index];
              return FutureBuilder<UserProfile?>(
                future: Provider.of<AuthProvider>(context, listen: false)
                    .getUserProfile(entry.userId),
                builder: (context, snapshot) {
                  final userProfile = snapshot.data;
                  return JournalPostCard(
                    entry: entry,
                    username: userProfile?.username ?? 'User',
                    avatarUrl: userProfile?.avatarUrl,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 