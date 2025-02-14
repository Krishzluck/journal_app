import 'package:flutter/material.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:journal_app/models/day_mood.dart';
import 'package:journal_app/screens/journal_details_page.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _firstDay;
  late DateTime _selectedDay;
  Map<DateTime, DayMood> _dayMoods = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _firstDay = authProvider.userProfile?.createdAt ?? DateTime.now();
    _loadUserEntries();
  }

  Future<void> _loadUserEntries() async {
    setState(() => _isLoading = true);
    
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (journalProvider.userEntries.isEmpty) {
      await journalProvider.loadUserEntries(authProvider.userProfile!.id);
    }

    // Group entries by date
    Map<DateTime, List<JournalEntry>> entriesByDate = {};
    for (var entry in journalProvider.userEntries) {
      // Normalize the date when storing
      final date = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );
      
      entriesByDate[date] ??= [];
      entriesByDate[date]!.add(entry);
    }

    // Convert to DayMood objects
    _dayMoods = entriesByDate.map((date, entries) => 
      MapEntry(date, DayMood.fromEntries(date, entries))
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Color _getMoodColor(List<JournalEntry> entries) {
    if (entries.isEmpty) return Colors.transparent;
    
    // Count moods
    int happy = 0, neutral = 0, sad = 0;
    
    for (var entry in entries) {
      switch (entry.mood.toLowerCase()) {
        case 'happy':
        case 'very happy':
        case 'excited':
          happy++;
          break;
        case 'neutral':
          neutral++;
          break;
        case 'sad':
        case 'angry':
        case 'frustrated':
          sad++;
          break;
      }
    }

    // Return dominant mood color
    if (happy >= neutral && happy >= sad) {
      return Colors.green;
    } else if (neutral >= happy && neutral >= sad) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedSelectedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final selectedDayMood = _dayMoods[normalizedSelectedDate];

    return Scaffold(
      appBar: AppBar(
        title: Text('Mood Calendar'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: _firstDay,
                  lastDay: DateTime.now().add(Duration(days: 30)),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.sunday,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: true,
                    outsideTextStyle: TextStyle(color: Colors.grey[400]),
                    weekendTextStyle: TextStyle(color: Colors.red[300]),
                  ),
                  onPageChanged: (focusedDay) {
                    setState(() => _focusedDay = focusedDay);
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      final normalizedDate = DateTime(date.year, date.month, date.day);
                      final dayMood = _dayMoods[normalizedDate];
                      if (dayMood == null) return null;

                      // Count unique moods
                      final Set<String> uniqueMoods = {};
                      for (var mood in dayMood.moods) {
                        if (mood.toLowerCase().contains('happy') || mood.toLowerCase() == 'excited') {
                          uniqueMoods.add('happy');
                        } else if (mood.toLowerCase() == 'neutral') {
                          uniqueMoods.add('neutral');
                        } else {
                          uniqueMoods.add('sad');
                        }
                      }

                      return Positioned(
                        bottom: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (uniqueMoods.contains('happy'))
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 2),
                                height: 6,
                                width: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                ),
                              ),
                            if (uniqueMoods.contains('neutral'))
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 2),
                                height: 6,
                                width: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.yellow,
                                ),
                              ),
                            if (uniqueMoods.contains('sad'))
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 2),
                                height: 6,
                                width: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                ),
                const SizedBox(height: 8),
                // Mood indicators legend
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem('Happy', Colors.green),
                      _buildLegendItem('Neutral', Colors.yellow),
                      _buildLegendItem('Sad', Colors.red),
                    ],
                  ),
                ),
                Divider(height: 1),
                // Selected day entries
                if (selectedDayMood != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                      child: Text(
                        DateFormat('MMMM d, y').format(_selectedDay),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: selectedDayMood.entries.length,
                      itemBuilder: (context, index) {
                        final entry = selectedDayMood.entries[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => JournalDetailsPage(entry: entry),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: moodColors[entry.mood],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        entry.mood,
                                        style: TextStyle(
                                          color: moodColors[entry.mood],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    entry.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    entry.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else
                  Expanded(
                    child: Center(
                      child: Text(
                        'No entries for ${DateFormat('MMMM d, y').format(_selectedDay)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }

  void _showDayMoodDialog(BuildContext context, DayMood dayMood) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DateFormat('MMMM d, y').format(dayMood.date)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Moods: ${dayMood.moodSummary}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              ...dayMood.entries.map((entry) => ListTile(
                title: Text(entry.title),
                subtitle: Text(entry.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: moodColors[entry.mood],
                    shape: BoxShape.circle,
                  ),
                ),
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
} 