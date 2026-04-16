// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_scanning_delegated_bypass_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SecretScanningDelegatedBypassOptions
_$SecretScanningDelegatedBypassOptionsFromJson(Map<String, dynamic> json) =>
    _SecretScanningDelegatedBypassOptions(
      reviewers: (json['reviewers'] as List<dynamic>?)
          ?.map((e) => Reviewers.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SecretScanningDelegatedBypassOptionsToJson(
  _SecretScanningDelegatedBypassOptions instance,
) => <String, dynamic>{'reviewers': instance.reviewers};
