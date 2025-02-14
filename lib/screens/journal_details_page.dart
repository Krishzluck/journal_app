import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:journal_app/screens/journal_entry_page.dart';
import 'package:journal_app/screens/profile_page.dart';
import 'package:journal_app/screens/user_profile_page.dart';
import 'package:provider/provider.dart';
import 'package:journal_app/widgets/user_avatar.dart';

class JournalDetailsPage extends StatefulWidget {
  final JournalEntry entry;

  JournalDetailsPage({required this.entry});

  @override
  _JournalDetailsPageState createState() => _JournalDetailsPageState();
}

class _JournalDetailsPageState extends State<JournalDetailsPage> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final comments = await Provider.of<JournalProvider>(context, listen: false)
          .getCommentsForEntry(widget.entry.id);
      
      // Sort comments by date (newest first)
      comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading comments: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment(String text) async {
    if (text.trim().isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    
    // Hide keyboard
    FocusScope.of(context).unfocus();

    final newComment = Comment(
      id: DateTime.now().toString(),
      journalEntryId: widget.entry.id,
      userId: authProvider.userProfile!.id,
      content: text.trim(),
      createdAt: DateTime.now(),
      userAvatarUrl: authProvider.userProfile?.avatarUrl,
      userName: authProvider.userProfile?.username,
    );

    // Optimistically add comment to local list
    setState(() {
      _comments.insert(0, newComment);
    });

    try {
      // Add comment to database
      final savedComment = await journalProvider.addComment(
        widget.entry.id,
        text.trim(),
      );

      // Update local list with actual comment data
      setState(() {
        final index = _comments.indexWhere((c) => c.id == newComment.id);
        if (index != -1) {
          _comments[index] = savedComment;
        }
      });
    } catch (e) {
      print('Error adding comment: $e');
      // Remove optimistically added comment on error
      setState(() {
        _comments.removeWhere((c) => c.id == newComment.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment')),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d \'at\' h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final journalProvider = Provider.of<JournalProvider>(context);
    final isCurrentUserEntry = authProvider.userProfile?.id == widget.entry.userId;

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
          future: authProvider.getUserProfile(widget.entry.userId),
          builder: (context, snapshot) {
            final userProfile = snapshot.data;
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(userId: widget.entry.userId),
                ),
              ),
              child: Row(
                children: [
                  UserAvatar(
                    imageUrl: userProfile?.avatarUrl,
                    radius: 20,
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
                      builder: (context) => JournalEntryPage(entry: widget.entry),
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator.adaptive(
                onRefresh: _loadComments,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.entry.title,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              widget.entry.content,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: moodColors[widget.entry.mood]?.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    widget.entry.mood,
                                    style: TextStyle(
                                      color: moodColors[widget.entry.mood],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  _formatDateTime(widget.entry.createdAt),
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
                          future: journalProvider.getCommentsForEntry(widget.entry.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Text('Error loading comments');
                            }
                            final comments = snapshot.data ?? [];
                            return Column(
                              children: comments.map((comment) => CommentWidget(entry: widget.entry,comment: comment)).toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AddCommentWidget(
                entryId: widget.entry.id,
                onCommentAdded: _addComment,
              ),
            ),
          ],
        ),
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
                Provider.of<JournalProvider>(context, listen: false).deleteEntry(widget.entry.id);
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
  final JournalEntry entry;
  final VoidCallback? onDelete;

  CommentWidget({
    required this.comment, 
    required this.entry, 
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).userProfile?.id;
    final isCurrentUserComment = currentUserId == comment.userId;
    final isEntryOwner = entry.userId == currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _navigateToProfile(context),
                child: UserAvatar(
                  imageUrl: comment.userAvatarUrl,
                  radius: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToProfile(context),
                  child: Text(
                    comment.userName ?? 'User',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (isCurrentUserComment || isEntryOwner)
                IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () => _showCommentOptions(context),
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

  void _showCommentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Comment'),
          content: Text('Are you sure you want to delete this comment?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await Provider.of<JournalProvider>(context, listen: false)
                      .deleteComment(comment.id);
                  if (onDelete != null) onDelete!();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete comment')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d \'at\' h:mm a').format(dateTime);
  }

  void _navigateToProfile(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).userProfile?.id;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => currentUserId == comment.userId 
            ? ProfilePage() 
            : UserProfilePage(userId: comment.userId),
      ),
    );
  }
}

class AddCommentWidget extends StatefulWidget {
  final String entryId;
  final Function(String) onCommentAdded;

  AddCommentWidget({
    required this.entryId,
    required this.onCommentAdded,
  });

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
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.send),
          onPressed: () {
            if (_commentController.text.trim().isNotEmpty) {
              widget.onCommentAdded(_commentController.text);
              _commentController.clear();
            }
          },
        ),
      ],
    );
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