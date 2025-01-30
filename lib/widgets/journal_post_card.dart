import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:journal_app/screens/journal_details_page.dart';
import 'package:journal_app/screens/user_profile_page.dart';
import 'package:journal_app/widgets/user_avatar.dart';

class JournalPostCard extends StatelessWidget {
  final JournalEntry entry;
  final String username;
  final String? avatarUrl;
  final VoidCallback? onMenuPressed;

  const JournalPostCard({
    Key? key,
    required this.entry,
    required this.username,
    this.avatarUrl,
    this.onMenuPressed,
  }) : super(key: key);

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays < 1) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (difference.inDays < 7) {
      return DateFormat('E').format(dateTime) + ' at ' + DateFormat('h:mm a').format(dateTime);
    } else {
      return DateFormat('MMM d').format(dateTime) + ' at ' + DateFormat('h:mm a').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JournalDetailsPage(entry: entry),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfilePage(userId: entry.userId),
                          ),
                        );
                      },
                      child: UserAvatar(
                        imageUrl: avatarUrl,
                        radius: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfilePage(userId: entry.userId),
                                ),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context).style,
                                children: [
                                  TextSpan(
                                    text: username,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: ' is feeling '),
                                  TextSpan(
                                    text: entry.mood,
                                    style: TextStyle(
                                      color: moodColors[entry.mood],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            _formatDateTime(entry.createdAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onMenuPressed != null)
                      IconButton(
                        icon: Icon(Icons.more_vert),
                        onPressed: onMenuPressed,
                        color: Colors.grey[600],
                      ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  entry.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  entry.content.split('\n').map((line) => line.trim()).join('\n').trimRight(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[300]
                        : Colors.grey[800],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey[200],
        ),
      ],
    );
  }
}

