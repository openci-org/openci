// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'advanced_security.freezed.dart';
part 'advanced_security.g.dart';

@Freezed()
abstract class AdvancedSecurity with _$AdvancedSecurity {
  const factory AdvancedSecurity({
    /// Can be `enabled` or `disabled`.
    @JsonKey(name: 'Status')
    String? status,
  }) = _AdvancedSecurity;
  
  factory AdvancedSecurity.fromJson(Map<String, Object?> json) => _$AdvancedSecurityFromJson(json);
}
