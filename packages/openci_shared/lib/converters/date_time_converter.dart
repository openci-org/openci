import 'package:json_annotation/json_annotation.dart';

class DateTimeConverter implements JsonConverter<DateTime, dynamic> {
  const DateTimeConverter();

  @override
  DateTime fromJson(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value != null && value is! bool) {
      try {
        final seconds = (value as dynamic).seconds as int;
        final nanoseconds = (value as dynamic).nanoseconds as int;
        return DateTime.fromMicrosecondsSinceEpoch(
          seconds * 1000000 + nanoseconds ~/ 1000,
          isUtc: true,
        );
      } catch (_) {}
    }
    throw ArgumentError(
      'Invalid type for DateTime conversion: ${value.runtimeType}',
    );
  }

  @override
  dynamic toJson(DateTime date) => date.toIso8601String();
}
