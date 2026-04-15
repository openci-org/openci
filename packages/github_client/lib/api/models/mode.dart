// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// The bypass mode for the reviewer
@JsonEnum()
enum Mode {
  @JsonValue('ALWAYS')
  always('ALWAYS'),
  @JsonValue('EXEMPT')
  exempt('EXEMPT'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const Mode(this.json);

  factory Mode.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<Mode> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
