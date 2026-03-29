import 'package:dashboard/i18n/strings.g.dart';
import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String toFormattedDate() {
    return DateFormat.MMMd().format(this);
  }

  String toTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      final s = difference.inSeconds;
      return s == 1
          ? t.timeAgo.secsAgo(count: s)
          : t.timeAgo.secsAgoPlural(count: s);
    } else if (difference.inMinutes < 60) {
      final m = difference.inMinutes;
      return m == 1
          ? t.timeAgo.minsAgo(count: m)
          : t.timeAgo.minsAgoPlural(count: m);
    } else if (difference.inHours < 24) {
      final h = difference.inHours;
      return t.timeAgo.hoursAgo(count: h);
    } else if (difference.inDays < 30) {
      final d = difference.inDays;
      return t.timeAgo.daysAgo(count: d);
    } else {
      final months = (difference.inDays / 30).floor();
      return t.timeAgo.monthsAgo(count: months);
    }
  }
}
