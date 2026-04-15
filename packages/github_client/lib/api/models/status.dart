// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// The current Status of the check run. Only GitHub Actions can set a Status of `waiting`, `pending`, or `requested`.
@JsonEnum()
enum Status {
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

  const Status(this.json);

  factory Status.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<Status> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
