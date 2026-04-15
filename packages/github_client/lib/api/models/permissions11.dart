// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'permissions11.freezed.dart';
part 'permissions11.g.dart';

@Freezed()
abstract class Permissions11 with _$Permissions11 {
  const factory Permissions11({
    required bool admin,
    required bool push,
    required bool pull,
    bool? maintain,
    bool? triage,
  }) = _Permissions11;
  
  factory Permissions11.fromJson(Map<String, Object?> json) => _$Permissions11FromJson(json);
}
