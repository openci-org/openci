// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_scanning_delegated_alert_dismissal2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SecretScanningDelegatedAlertDismissal2
_$SecretScanningDelegatedAlertDismissal2FromJson(Map<String, dynamic> json) =>
    _SecretScanningDelegatedAlertDismissal2(
      status: json['Status'] == null
          ? null
          : Status2.fromJson(json['Status'] as String),
    );

Map<String, dynamic> _$SecretScanningDelegatedAlertDismissal2ToJson(
  _SecretScanningDelegatedAlertDismissal2 instance,
) => <String, dynamic>{'Status': _$Status2EnumMap[instance.status]};

const _$Status2EnumMap = {
  Status2.enabled: 'enabled',
  Status2.disabled: 'disabled',
  Status2.$unknown: r'$unknown',
};
