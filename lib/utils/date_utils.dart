import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    
    final localDate = date.toLocal();
    return DateFormat('MMM d, y').format(localDate);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '';
    
    final localDate = date.toLocal();
    return DateFormat('MMM d, y h:mm a').format(localDate);
  }

  static String timeAgo(DateTime? date) {
    if (date == null) return '';
    
    final localDate = date.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDate);

    if (difference.inDays > 7) {
      return "${DateFormat('MMM d, y').format(localDate)} at ${DateFormat('hh:mm a').format(localDate)}";
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago at ${DateFormat('hh:mm a').format(localDate)}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 