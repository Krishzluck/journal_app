import 'package:flutter/material.dart';
import 'package:journal_app/models/notification.dart';
import 'package:journal_app/providers/notification_provider.dart';
import 'package:journal_app/screens/journal_details_page.dart';
import 'package:journal_app/screens/user_profile_page.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false).markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchNotifications(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            child: ListView.builder(
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return NotificationTile(notification: notification);
              },
            ),
          );
        },
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final UserNotification notification;

  const NotificationTile({
    Key? key,
    required this.notification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _handleNotificationTap(context);
        if (!notification.isRead) {
          Provider.of<NotificationProvider>(context, listen: false)
              .markAsRead(notification.id);
        }
      },
      child: Container(
        color: notification.isRead ? null : Colors.blue.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(notification.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    IconData iconData;
    
    switch (notification.type) {
      case 'comment':
        iconData = Icons.comment;
        break;
      case 'follow':
        iconData = Icons.person_add;
        break;
      case 'like':
        iconData = Icons.favorite;
        break;
      case 'new_journal':
        iconData = Icons.article;
        break;
      case 'month_mood':
        iconData = Icons.calendar_today;
        break;
      default:
        iconData = Icons.notifications;
    }
    
    return CircleAvatar(
      backgroundColor: _getColorForType(notification.type),
      radius: 20,
      child: Icon(iconData, color: Colors.white),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'comment':
        return Colors.blue;
      case 'follow':
        return Colors.green;
      case 'like':
        return Colors.red;
      case 'new_journal':
        return Colors.purple;
      case 'month_mood':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _handleNotificationTap(BuildContext context) async {
    switch (notification.type) {
      case 'comment':
      case 'like':
      case 'new_journal':
        if (notification.referenceId != null) {
          final journalProvider = Provider.of<JournalProvider>(context, listen: false);
          final entry = await journalProvider.getJournalEntry(notification.referenceId!);
          if (entry != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JournalDetailsPage(entry: entry),
              ),
            );
          }
        }
        break;
      case 'follow':
        if (notification.referenceId != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfilePage(userId: notification.referenceId!),
            ),
          );
        }
        break;
    }
  }
}
