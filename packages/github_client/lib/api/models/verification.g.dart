// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Verification _$VerificationFromJson(Map<String, dynamic> json) =>
    _Verification(
      verified: json['verified'] as bool?,
      reason: json['reason'] as String?,
      signature: json['signature'] as String?,
      payload: json['payload'] as String?,
      verifiedAt: json['verified_at'] as String?,
    );

Map<String, dynamic> _$VerificationToJson(_Verification instance) =>
    <String, dynamic>{
      'verified': instance.verified,
      'reason': instance.reason,
      'signature': instance.signature,
      'payload': instance.payload,
      'verified_at': instance.verifiedAt,
    };
