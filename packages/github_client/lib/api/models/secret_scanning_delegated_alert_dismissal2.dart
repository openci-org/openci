// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'status2.dart';

part 'secret_scanning_delegated_alert_dismissal2.freezed.dart';
part 'secret_scanning_delegated_alert_dismissal2.g.dart';

@Freezed()
abstract class SecretScanningDelegatedAlertDismissal2 with _$SecretScanningDelegatedAlertDismissal2 {
  const factory SecretScanningDelegatedAlertDismissal2({
    @JsonKey(name: 'Status')
    Status2? status,
  }) = _SecretScanningDelegatedAlertDismissal2;
  
  factory SecretScanningDelegatedAlertDismissal2.fromJson(Map<String, Object?> json) => _$SecretScanningDelegatedAlertDismissal2FromJson(json);
}
