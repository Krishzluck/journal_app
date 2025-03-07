import 'package:flutter/material.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:journal_app/providers/theme_provider.dart';
import 'package:journal_app/screens/calendar_screen.dart';
import 'package:journal_app/screens/auth_page.dart';
import 'package:journal_app/screens/saved_journals_screen.dart';
import 'package:journal_app/screens/blocked_users_screen.dart';
import 'package:journal_app/screens/notifications_screen.dart';
import 'package:journal_app/providers/notification_provider.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Mood Calendar'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CalendarScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.bookmark),
            title: Text('Saved Journals'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SavedJournalsScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.brightness_6),
            title: Text('Theme'),
            trailing: Text(
              _getThemeModeName(Provider.of<ThemeProvider>(context).themeMode),
              style: TextStyle(color: Colors.grey[600]),
            ),
            onTap: () => _showThemeModeBottomSheet(context),
          ),
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              return ListTile(
                leading: Icon(Icons.notifications),
                title: Text('Notifications'),
                trailing: notificationProvider.unreadCount > 0
                  ? Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        notificationProvider.unreadCount.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    )
                  : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationsScreen()),
                  );
                },
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.block),
            title: Text('Blocked Users'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BlockedUsersScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
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
              onPressed: () async {
                // Reset to home tab
                Provider.of<ThemeProvider>(context, listen: false).resetCurrentIndex();
                // Sign out
                await Provider.of<AuthProvider>(context, listen: false).signOut(context);
                // Navigate to auth page
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => AuthPage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _getThemeModeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemeModeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  'Choose Theme',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.brightness_5),
                title: Text('Light'),
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.light);
                  Navigator.pop(context);
                },
                trailing: themeProvider.themeMode == ThemeMode.light
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
              ),
              ListTile(
                leading: Icon(Icons.brightness_4),
                title: Text('Dark'),
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.dark);
                  Navigator.pop(context);
                },
                trailing: themeProvider.themeMode == ThemeMode.dark
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
              ),
              ListTile(
                leading: Icon(Icons.brightness_6),
                title: Text('System'),
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.system);
                  Navigator.pop(context);
                },
                trailing: themeProvider.themeMode == ThemeMode.system
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
              ),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

