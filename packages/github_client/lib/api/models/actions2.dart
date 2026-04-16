// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'actions2.freezed.dart';
part 'actions2.g.dart';

@Freezed()
abstract class Actions2 with _$Actions2 {
  const factory Actions2({
    /// The text to be displayed on a button in the web UI. The maximum size is 20 characters.
    @JsonKey(name: 'Label') required String label,

    /// A short explanation of what this action would do. The maximum size is 40 characters.
    required String description,

    /// A reference for the action on the integrator's system. The maximum size is 20 characters.
    required String identifier,
  }) = _Actions2;

  factory Actions2.fromJson(Map<String, Object?> json) =>
      _$Actions2FromJson(json);
}
