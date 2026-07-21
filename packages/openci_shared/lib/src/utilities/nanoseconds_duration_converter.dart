import 'package:freezed_annotation/freezed_annotation.dart';

class NanosecondsDurationConverter
    implements JsonConverter<Duration?, dynamic> {
  const NanosecondsDurationConverter();

  @override
  Duration? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is num) {
      return Duration(microseconds: (json / 1000).round());
    }
    return null;
  }

  @override
  dynamic toJson(Duration? object) =>
      object != null ? object.inMicroseconds * 1000 : null;
}
