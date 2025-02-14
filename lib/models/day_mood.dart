import 'package:journal_app/providers/journal_provider.dart';

class DayMood {
  final DateTime date;
  final List<String> moods;
  final List<JournalEntry> entries;

  DayMood({
    required this.date,
    required this.moods,
    required this.entries,
  });

  factory DayMood.fromEntries(DateTime date, List<JournalEntry> entries) {
    return DayMood(
      date: date,
      moods: entries.map((e) => e.mood).toList(),
      entries: entries,
    );
  }

  String get moodSummary => moods.join(', ');
} 