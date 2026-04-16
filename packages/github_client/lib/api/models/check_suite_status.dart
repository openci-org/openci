// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// The phase of the lifecycle that the check suite is currently in. Statuses of waiting, requested, and pending are reserved for GitHub Actions check suites.
@JsonEnum()
enum CheckSuiteStatus {
  @JsonValue('queued')
  queued('queued'),
  @JsonValue('in_progress')
  inProgress('in_progress'),
  @JsonValue('completed')
  completed('completed'),
  @JsonValue('waiting')
  waiting('waiting'),
  @JsonValue('requested')
  requested('requested'),
  @JsonValue('pending')
  pending('pending'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const CheckSuiteStatus(this.json);

  factory CheckSuiteStatus.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<CheckSuiteStatus> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
