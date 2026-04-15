// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// The type of the bypass reviewer
@JsonEnum()
enum ReviewerType {
  @JsonValue('TEAM')
  team('TEAM'),
  @JsonValue('ROLE')
  role('ROLE'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const ReviewerType(this.json);

  factory ReviewerType.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<ReviewerType> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
