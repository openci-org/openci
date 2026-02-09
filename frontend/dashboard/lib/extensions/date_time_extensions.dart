import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String toFormattedDate() {
    final month = DateFormat('MMMM').format(this);
    final day = this.day;
    return '$month $day${ordinalSuffix(day)}';
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
