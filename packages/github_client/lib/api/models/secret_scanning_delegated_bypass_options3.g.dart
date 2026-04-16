// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_scanning_delegated_bypass_options3.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SecretScanningDelegatedBypassOptions3
_$SecretScanningDelegatedBypassOptions3FromJson(Map<String, dynamic> json) =>
    _SecretScanningDelegatedBypassOptions3(
      reviewers: (json['reviewers'] as List<dynamic>?)
          ?.map((e) => Reviewers3.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SecretScanningDelegatedBypassOptions3ToJson(
  _SecretScanningDelegatedBypassOptions3 instance,
) => <String, dynamic>{'reviewers': instance.reviewers};
