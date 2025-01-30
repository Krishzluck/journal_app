import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:journal_app/common/image_constants.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:journal_app/screens/journal_entry_page.dart';
import 'package:journal_app/screens/settings_screen.dart';
import 'package:journal_app/widgets/journal_post_card.dart';
import 'package:provider/provider.dart';
import 'package:journal_app/providers/theme_provider.dart';
import 'package:journal_app/widgets/user_avatar.dart';
import 'package:journal_app/screens/profile_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JournalProvider>(context, listen: false).loadGlobalEntries();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: themeProvider.currentIndex == 0 ? AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Row(
            children: [
              Image.asset(
                ImageConstants.appLogo,
                height: 32,
                width: 32,
              ),
              SizedBox(width: 8),
              Text('Journal App'),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
              child: UserAvatar(
                imageUrl: authProvider.userProfile?.avatarUrl,
                radius: 16,
              ),
            ),
          ),
        ],
      ) : null,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: [
          KeepAlivePage(child: HomeTab()),
          Container(), // Empty container for journal entry tab
          KeepAlivePage(child: SettingsPage()),
        ],
        onPageChanged: (index) {
          themeProvider.setCurrentIndex(index);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: themeProvider.currentIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => JournalEntryPage()),
            );
          } else {
            _pageController.jumpToPage(index);
          }
        },
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 32),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 32),
            label: '',
          ),
        ],
      ),
    );
  }
}

// Create a new HomeTab widget to hold the current home screen content
class HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final journalProvider = Provider.of<JournalProvider>(context);
    
    return Theme.of(context).platform == TargetPlatform.iOS
        ? CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () => journalProvider.loadGlobalEntries(),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = journalProvider.globalEntries[index];
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
                  childCount: journalProvider.globalEntries.length,
                ),
              ),
            ],
          )
        : RefreshIndicator(
            onRefresh: () => journalProvider.loadGlobalEntries(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: journalProvider.globalEntries.length,
              itemBuilder: (context, index) {
                final entry = journalProvider.globalEntries[index];
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
            ),
          );
  }
}

// Add this KeepAlivePage widget
class KeepAlivePage extends StatefulWidget {
  final Widget child;

  const KeepAlivePage({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _KeepAlivePageState createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}