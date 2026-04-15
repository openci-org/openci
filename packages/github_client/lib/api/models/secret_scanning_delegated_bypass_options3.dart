// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'reviewers3.dart';

part 'secret_scanning_delegated_bypass_options3.freezed.dart';
part 'secret_scanning_delegated_bypass_options3.g.dart';

@Freezed()
abstract class SecretScanningDelegatedBypassOptions3 with _$SecretScanningDelegatedBypassOptions3 {
  const factory SecretScanningDelegatedBypassOptions3({
    /// The bypass reviewers for secret scanning delegated bypass
    List<Reviewers3>? reviewers,
  }) = _SecretScanningDelegatedBypassOptions3;
  
  factory SecretScanningDelegatedBypassOptions3.fromJson(Map<String, Object?> json) => _$SecretScanningDelegatedBypassOptions3FromJson(json);
}
