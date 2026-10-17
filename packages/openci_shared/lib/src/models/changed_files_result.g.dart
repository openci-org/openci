// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'changed_files_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChangedFilesResult _$ChangedFilesResultFromJson(Map<String, dynamic> json) =>
    _ChangedFilesResult(
      paths: (json['paths'] as List<dynamic>).map((e) => e as String).toList(),
      isComplete: json['isComplete'] as bool,
      baseSha: json['baseSha'] as String?,
      headSha: json['headSha'] as String?,
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$ChangedFilesResultToJson(_ChangedFilesResult instance) =>
    <String, dynamic>{
      'paths': instance.paths,
      'isComplete': instance.isComplete,
      'baseSha': instance.baseSha,
      'headSha': instance.headSha,
      'reason': instance.reason,
    };
