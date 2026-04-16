// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'code_security.freezed.dart';
part 'code_security.g.dart';

@Freezed()
abstract class CodeSecurity with _$CodeSecurity {
  const factory CodeSecurity({
    /// Can be `enabled` or `disabled`.
    @JsonKey(name: 'Status') String? status,
  }) = _CodeSecurity;

  factory CodeSecurity.fromJson(Map<String, Object?> json) =>
      _$CodeSecurityFromJson(json);
}
