import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:journal_app/screens/journal_entry_page.dart';
import 'package:journal_app/screens/user_profile_page.dart';
import 'package:provider/provider.dart';

class JournalDetailsPage extends StatelessWidget {
  final JournalEntry entry;

  JournalDetailsPage({required this.entry});

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d \'at\' h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final journalProvider = Provider.of<JournalProvider>(context);
    final isCurrentUserEntry = authProvider.userProfile?.id == entry.userId;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Theme.of(context).platform == TargetPlatform.iOS
                ? Icons.arrow_back_ios
                : Icons.arrow_back,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: FutureBuilder<UserProfile?>(
          future: authProvider.getUserProfile(entry.userId),
          builder: (context, snapshot) {
            final userProfile = snapshot.data;
            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(userId: entry.userId),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: userProfile?.avatarUrl != null
                        ? CachedNetworkImageProvider(userProfile!.avatarUrl!)
                        : null,
                    child: userProfile?.avatarUrl == null
                        ? Icon(Icons.person, size: 20)
                        : null,
                  ),
                  SizedBox(width: 12),
                  Text(
                    userProfile?.username ?? 'User',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          if (isCurrentUserEntry)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JournalEntryPage(entry: entry),
                    ),
                  );
                } else if (value == 'delete') {
                  _showDeleteConfirmationDialog(context);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          entry.content,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: moodColors[entry.mood]?.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                entry.mood,
                                style: TextStyle(
                                  color: moodColors[entry.mood],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              _formatDateTime(entry.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[600]),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FutureBuilder<List<Comment>>(
                      future: journalProvider.getCommentsForEntry(entry.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Error loading comments');
                        }
                        final comments = snapshot.data ?? [];
                        return Column(
                          children: comments.map((comment) => CommentWidget(comment: comment)).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AddCommentWidget(entryId: entry.id),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
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
                Provider.of<JournalProvider>(context, listen: false).deleteEntry(entry.id);
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to the previous screen
              },
            ),
          ],
        );
      },
    );
  }
}

class CommentWidget extends StatelessWidget {
  final Comment comment;

  CommentWidget({required this.comment});

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d \'at\' h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: comment.userAvatarUrl != null
                    ? CachedNetworkImageProvider(comment.userAvatarUrl!)
                    : null,
                child: comment.userAvatarUrl == null
                    ? Icon(Icons.person, size: 24)
                    : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  comment.userName ?? 'User',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 4),
          Text(
            comment.content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 4),
          Text(
            _formatDateTime(comment.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class AddCommentWidget extends StatefulWidget {
  final String entryId;

  AddCommentWidget({required this.entryId});

  @override
  _AddCommentWidgetState createState() => _AddCommentWidgetState();
}

class _AddCommentWidgetState extends State<AddCommentWidget> {
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CommonTextField(
            controller: _commentController,
            hintText: 'Write a comment...',
          ),
        ),
        IconButton(
          icon: Icon(Icons.send),
          onPressed: () async {
            if (_commentController.text.trim().isNotEmpty) {
              await Provider.of<JournalProvider>(context, listen: false)
                  .addComment(widget.entryId, _commentController.text.trim());
              _commentController.clear();
              setState(() {});
            }
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

class CommonTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const CommonTextField({Key? key, required this.controller, required this.hintText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}