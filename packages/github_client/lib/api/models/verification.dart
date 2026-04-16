// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'verification.freezed.dart';
part 'verification.g.dart';

@Freezed()
abstract class Verification with _$Verification {
  const factory Verification({
    bool? verified,
    String? reason,
    String? signature,
    String? payload,
    @JsonKey(name: 'verified_at')
    String? verifiedAt,
  }) = _Verification;
  
  factory Verification.fromJson(Map<String, Object?> json) => _$VerificationFromJson(json);
}
