// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// The current Status of the check run. Can be `queued`, `in_progress`, or `completed`.
@JsonEnum()
enum Status7 {
  @JsonValue('queued')
  queued('queued'),
  @JsonValue('in_progress')
  inProgress('in_progress'),
  @JsonValue('completed')
  completed('completed'),
  @JsonValue('waiting')
  waiting('waiting'),
  @JsonValue('pending')
  pending('pending'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const Status7(this.json);

  factory Status7.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<Status7> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
