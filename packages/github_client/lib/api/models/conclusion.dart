// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// **Required if you provide `completed_at` or a `status` of `completed`**. The final conclusion of the check. .
/// **Note:** Providing `conclusion` will automatically set the `status` parameter to `completed`. You cannot change a check run conclusion to `stale`, only GitHub can set this.
@JsonEnum()
enum Conclusion {
  @JsonValue('action_required')
  actionRequired('action_required'),
  @JsonValue('cancelled')
  cancelled('cancelled'),
  @JsonValue('failure')
  failure('failure'),
  @JsonValue('neutral')
  neutral('neutral'),
  @JsonValue('success')
  success('success'),
  @JsonValue('skipped')
  skipped('skipped'),
  @JsonValue('stale')
  stale('stale'),
  @JsonValue('timed_out')
  timedOut('timed_out'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const Conclusion(this.json);

  factory Conclusion.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<Conclusion> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
