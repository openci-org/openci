import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String toFormattedDate() {
    final month = DateFormat('MMMM').format(this);
    final day = this.day;
    return '$month $day${ordinalSuffix(day)}';
  }

  String toTimeAgoEn() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      final s = difference.inSeconds;
      return '$s${s == 1 ? 'sec' : 'secs'} ago';
    } else if (difference.inMinutes < 60) {
      final m = difference.inMinutes;
      return '$m${m == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      final h = difference.inHours;
      return '$h${h == 1 ? 'h' : 'h'} ago';
    } else if (difference.inDays < 30) {
      final d = difference.inDays;
      return '$d${d == 1 ? 'd' : 'd'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months${months == 1 ? 'm' : 'm'} ago';
    }
  }
}

String ordinalSuffix(int day) {
  if (day >= 11 && day <= 13) return 'th';
  return switch (day % 10) {
    1 => 'st',
    2 => 'nd',
    3 => 'rd',
    _ => 'th',
  };
}
