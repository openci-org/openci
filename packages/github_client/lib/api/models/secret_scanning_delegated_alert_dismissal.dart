// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'secret_scanning_delegated_alert_dismissal.freezed.dart';
part 'secret_scanning_delegated_alert_dismissal.g.dart';

@Freezed()
abstract class SecretScanningDelegatedAlertDismissal with _$SecretScanningDelegatedAlertDismissal {
  const factory SecretScanningDelegatedAlertDismissal({
    /// Can be `enabled` or `disabled`.
    @JsonKey(name: 'Status')
    String? status,
  }) = _SecretScanningDelegatedAlertDismissal;
  
  factory SecretScanningDelegatedAlertDismissal.fromJson(Map<String, Object?> json) => _$SecretScanningDelegatedAlertDismissalFromJson(json);
}
