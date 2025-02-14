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
import 'package:journal_app/providers/blocked_users_provider.dart';
import 'package:journal_app/screens/search_screen.dart';
import 'package:journal_app/screens/month_mood_screen.dart';
import 'package:journal_app/widgets/shimmer_loading.dart';
import 'package:journal_app/providers/follow_provider.dart';

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
      final blockedUsersProvider = Provider.of<BlockedUsersProvider>(context, listen: false);
      Provider.of<JournalProvider>(context, listen: false)
          .loadGlobalEntries(blockedUsersProvider.blockedUsers);
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
              Text('Reflection'),
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
          KeepAlivePage(child: SearchScreen()),
          Container(), // Empty container for journal entry tab
          KeepAlivePage(child: MonthMoodScreen()),
          KeepAlivePage(child: SettingsPage()),
        ],
        onPageChanged: (index) {
          themeProvider.setCurrentIndex(index);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: themeProvider.currentIndex,
        onTap: (index) {
          if (index == 2) {
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
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
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
              ),
            ),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final followProvider = Provider.of<FollowProvider>(context, listen: false);
    
    if (authProvider.userProfile != null) {
      await followProvider.loadFollowData(authProvider.userProfile!.id);
      await journalProvider.loadFollowingEntries(
        authProvider.userProfile!.id, 
        followProvider.followingIds
      );
      await journalProvider.loadFollowerEntries(
        authProvider.userProfile!.id, 
        followProvider.followerIds
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
    // Reload data when switching to following/followers tab
    if (index > 0) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 50,
          margin: EdgeInsets.symmetric(vertical: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildSectionButton('Global', 0),
                SizedBox(width: 12),
                _buildSectionButton('Following', 1),
                SizedBox(width: 12),
                _buildSectionButton('Followers', 2),
              ],
            ),
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              KeepAlivePage(child: _buildGlobalFeed()),
              KeepAlivePage(child: _buildFollowingFeed()),
              KeepAlivePage(child: _buildFollowersFeed()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionButton(String label, int index) {
    final isSelected = _selectedIndex == index;
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 36,
      child: TextButton(
        onPressed: () {
          _pageController.animateToPage(
            index,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? primaryColor : (isDark ? Colors.white : Colors.grey[700]!),
              width: 1,
            ),
          ),
          backgroundColor: isSelected ? primaryColor : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
              ? Colors.white 
              : (isDark ? Colors.white : Colors.grey[700]),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalFeed() {
    final journalProvider = Provider.of<JournalProvider>(context);
    
    if (journalProvider.isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => ShimmerLoading(
          child: JournalCardShimmer(),
        ),
      );
    }
    
    if (journalProvider.globalEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No Public Journals Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to share your journal!',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Theme.of(context).platform == TargetPlatform.iOS
        ? CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () => journalProvider.loadGlobalEntries(
                  Provider.of<BlockedUsersProvider>(context, listen: false).blockedUsers
                ),
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
            onRefresh: () => journalProvider.loadGlobalEntries(
              Provider.of<BlockedUsersProvider>(context, listen: false).blockedUsers
            ),
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

  Widget _buildFollowingFeed() {
    final journalProvider = Provider.of<JournalProvider>(context);
    final followProvider = Provider.of<FollowProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (journalProvider.isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => 
          ShimmerLoading(child: JournalCardShimmer()),
      );
    }

    if (followProvider.followingIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Not Following Anyone',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Follow people to see their journals here',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (journalProvider.followingEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No Journals Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'People you follow haven\'t posted any journals',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: journalProvider.followingEntries.length,
      itemBuilder: (context, index) {
        final entry = journalProvider.followingEntries[index];
        return FutureBuilder<UserProfile?>(
          future: authProvider.getUserProfile(entry.userId),
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
  }

  Widget _buildFollowersFeed() {
    final journalProvider = Provider.of<JournalProvider>(context);
    final followProvider = Provider.of<FollowProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (journalProvider.isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => 
          ShimmerLoading(child: JournalCardShimmer()),
      );
    }

    if (journalProvider.followerEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No Journals Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your followers haven\'t posted any journals',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: journalProvider.followerEntries.length,
      itemBuilder: (context, index) {
        final entry = journalProvider.followerEntries[index];
        return FutureBuilder<UserProfile?>(
          future: authProvider.getUserProfile(entry.userId),
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