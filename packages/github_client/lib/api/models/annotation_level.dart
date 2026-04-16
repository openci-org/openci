// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// The level of the annotation.
@JsonEnum()
enum AnnotationLevel {
  @JsonValue('notice')
  notice('notice'),
  @JsonValue('warning')
  warning('warning'),
  @JsonValue('failure')
  failure('failure'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const AnnotationLevel(this.json);

  factory AnnotationLevel.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<AnnotationLevel> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
