// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'permissions10.freezed.dart';
part 'permissions10.g.dart';

@Freezed()
abstract class Permissions10 with _$Permissions10 {
  const factory Permissions10({
    required bool admin,
    required bool pull,
    required bool push,
    bool? triage,
    bool? maintain,
  }) = _Permissions10;

  factory Permissions10.fromJson(Map<String, Object?> json) =>
      _$Permissions10FromJson(json);
}
