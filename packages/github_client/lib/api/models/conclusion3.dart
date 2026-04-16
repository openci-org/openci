// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// The summary conclusion for all check runs that are part of the check suite. This value will be `null` until the check run has completed.
@JsonEnum()
enum Conclusion3 {
  @JsonValue('success')
  success('success'),
  @JsonValue('failure')
  failure('failure'),
  @JsonValue('neutral')
  neutral('neutral'),
  @JsonValue('cancelled')
  cancelled('cancelled'),
  @JsonValue('timed_out')
  timedOut('timed_out'),
  @JsonValue('action_required')
  actionRequired('action_required'),
  @JsonValue('stale')
  stale('stale'),

  /// The name has been replaced because it contains a keyword. Original name: `null`.
  @JsonValue('null')
  valueNull('null'),
  @JsonValue('skipped')
  skipped('skipped'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const Conclusion3(this.json);

  factory Conclusion3.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<Conclusion3> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
