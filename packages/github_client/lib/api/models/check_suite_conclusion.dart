// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum CheckSuiteConclusion {
  @JsonValue('success')
  success('success'),
  @JsonValue('failure')
  failure('failure'),
  @JsonValue('neutral')
  neutral('neutral'),
  @JsonValue('cancelled')
  cancelled('cancelled'),
  @JsonValue('skipped')
  skipped('skipped'),
  @JsonValue('timed_out')
  timedOut('timed_out'),
  @JsonValue('action_required')
  actionRequired('action_required'),
  @JsonValue('startup_failure')
  startupFailure('startup_failure'),
  @JsonValue('stale')
  stale('stale'),
  /// The name has been replaced because it contains a keyword. Original name: `null`.
  @JsonValue('null')
  valueNull('null'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const CheckSuiteConclusion(this.json);

  factory CheckSuiteConclusion.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<CheckSuiteConclusion> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
