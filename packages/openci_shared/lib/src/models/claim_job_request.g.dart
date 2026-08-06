// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claim_job_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClaimJobRequest _$ClaimJobRequestFromJson(Map<String, dynamic> json) =>
    _ClaimJobRequest(
      vmName: json['vmName'] as String?,
      workerHost: json['workerHost'] as String?,
      maxConcurrentJobs: (json['maxConcurrentJobs'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ClaimJobRequestToJson(_ClaimJobRequest instance) =>
    <String, dynamic>{
      'vmName': instance.vmName,
      'workerHost': instance.workerHost,
      'maxConcurrentJobs': instance.maxConcurrentJobs,
    };
