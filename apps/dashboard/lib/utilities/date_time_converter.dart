import 'package:freezed_annotation/freezed_annotation.dart';

class DateTimeConverter implements JsonConverter<DateTime, Object> {
  const DateTimeConverter();

  @override
  DateTime fromJson(Object value) {
    if (value is String) {
      return DateTime.parse(value);
    }
    throw ArgumentError(
      'Invalid type for DateTime conversion: ${value.runtimeType}',
    );
  }

  @override
  Object toJson(DateTime date) => date.toUtc().toIso8601String();
}
