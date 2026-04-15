// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'status2.dart';

part 'advanced_security2.freezed.dart';
part 'advanced_security2.g.dart';

@Freezed()
abstract class AdvancedSecurity2 with _$AdvancedSecurity2 {
  const factory AdvancedSecurity2({
    @JsonKey(name: 'Status')
    Status2? status,
  }) = _AdvancedSecurity2;
  
  factory AdvancedSecurity2.fromJson(Map<String, Object?> json) => _$AdvancedSecurity2FromJson(json);
}
