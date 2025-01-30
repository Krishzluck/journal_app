import 'package:flutter/material.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _firstDay;
  Map<DateTime, List<JournalEntry>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _firstDay = authProvider.userProfile?.createdAt ?? DateTime.now();
    _loadUserEntries();
  }

  Future<void> _loadUserEntries() async {
    setState(() => _isLoading = true);
    
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Load user entries if not already loaded
    if (journalProvider.userEntries.isEmpty) {
      await journalProvider.loadUserEntries(authProvider.userProfile!.id);
    }

    // Group entries by date
    _events = {};
    for (var entry in journalProvider.userEntries) {
      final date = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );
      
      if (_events[date] == null) {
        _events[date] = [];
      }
      _events[date]!.add(entry);
    }
    
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
                      final dayEvents = _events[date] ?? [];
                      if (dayEvents.isEmpty) return null;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 35), // Push dots to bottom
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getMoodColor(dayEvents),
                            ),
                            width: 6,
                            height: 6,
                          ),
                        ],
                      );
                    },
                  ),
                  selectedDayPredicate: (day) {
                    return _events.containsKey(day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    final entries = _events[selectedDay] ?? [];
                    if (entries.isNotEmpty) {
                      _showEntriesDialog(context, selectedDay, entries);
                    }
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

  void _showEntriesDialog(BuildContext context, DateTime date, List<JournalEntry> entries) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DateFormat('MMMM d, y').format(date)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.map((entry) => ListTile(
              title: Text(entry.title),
              subtitle: Text('Mood: ${entry.mood}'),
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getMoodColor([entry]),
                  shape: BoxShape.circle,
                ),
              ),
            )).toList(),
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