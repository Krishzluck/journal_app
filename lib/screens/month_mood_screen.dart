import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:provider/provider.dart';
import 'package:journal_app/screens/journal_details_page.dart';
import 'package:journal_app/widgets/user_avatar.dart';
import 'dart:math' as math;
import 'package:journal_app/widgets/shimmer_loading.dart';

class MonthMoodScreen extends StatefulWidget {
  @override
  _MonthMoodScreenState createState() => _MonthMoodScreenState();
}

class _MonthMoodScreenState extends State<MonthMoodScreen> {
  Map<String, int> _moodCounts = {};
  List<JournalEntry> _monthEntries = [];
  String _dominantMood = '';
  int _totalMinutes = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userProfile != null) {
      await Provider.of<JournalProvider>(context, listen: false)
          .loadUserEntries(authProvider.userProfile!.id);
      _loadMonthData();
    }
    
    setState(() => _isLoading = false);
  }

  void _loadMonthData() async{
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    _monthEntries = journalProvider.userEntries.where((entry) {
      return entry.createdAt.isAfter(startOfMonth) && 
             entry.createdAt.isBefore(endOfMonth.add(Duration(days: 1)));
    }).toList();

    // Calculate mood counts
    _moodCounts = {};
    for (var entry in _monthEntries) {
      _moodCounts[entry.mood] = (_moodCounts[entry.mood] ?? 0) + 1;
    }

    // Find dominant mood
    int maxCount = 0;
    _moodCounts.forEach((mood, count) {
      if (count > maxCount) {
        maxCount = count;
        _dominantMood = mood;
      }
    });

    _totalMinutes = _monthEntries.length * 45; // Assuming 45 minutes per entry

    setState(() {});
  }

  List<MoodPercentage> _getMoodPercentages() {
    final total = _moodCounts.values.fold(0, (sum, count) => sum + count);
    
    List<MoodPercentage> percentages = _moodCounts.entries.map((entry) {
      return MoodPercentage(
        entry.key,
        (entry.value / total) * 100,
        entry.value,
      );
    }).toList();

    // Sort by percentage in descending order
    percentages.sort((a, b) => b.percentage.compareTo(a.percentage));
    
    return percentages;
  }

  @override
  Widget build(BuildContext context) {
    Widget emptyState = Center(
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
            'No Journals This Month',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start writing to see your monthly mood overview',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );

    Widget mainContent = _monthEntries.isEmpty 
        ? LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.sizeOf(context).height * .5,
                  child: emptyState,
                ),
              );
            },
          )
        : Column(
            children: [
              SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CustomPaint(
                    painter: MoodGraphPainter(_moodCounts),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Monthly Mood',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_dominantMood.isNotEmpty)
                            Text(_dominantMood,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: moodColors[_dominantMood],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _getMoodPercentages().map((moodData) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: moodColors[moodData.mood],
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            moodData.mood,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Spacer(),
                          Text(
                            '${moodData.percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                itemCount: _monthEntries.length,
                itemBuilder: (context, index) {
                  final entry = _monthEntries[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: moodColors[entry.mood],
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(entry.title),
                      subtitle: Text(
                        entry.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JournalDetailsPage(entry: entry),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          );

    Widget content = _isLoading 
      ? ShimmerLoading(child: MoodGraphShimmer())
      : mainContent;

    return Scaffold(
      appBar: AppBar(
        title: Text('Month Overview'),
      ),
      body: Theme.of(context).platform == TargetPlatform.iOS
          ? CustomScrollView(
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: _loadData,
                ),
                SliverToBoxAdapter(
                  child: content,
                ),
              ],
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _monthEntries.isEmpty
                  ? content
                  : SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: content,
                    ),
            ),
    );
  }
}

class MoodGraphPainter extends CustomPainter {
  final Map<String, int> moodCounts;

  MoodGraphPainter(this.moodCounts);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    double startAngle = -math.pi / 2;
    final total = moodCounts.values.fold(0, (sum, count) => sum + count);

    moodCounts.forEach((mood, count) {
      final sweepAngle = 2 * math.pi * count / total;
      
      final paint = Paint()
        ..color = moodColors[mood] ?? Colors.grey
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class MoodPercentage {
  final String mood;
  final double percentage;
  final int count;

  MoodPercentage(this.mood, this.percentage, this.count);
}