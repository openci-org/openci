// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'changed_files_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangedFilesResult _$ChangedFilesResultFromJson(Map<String, dynamic> json) =>
    ChangedFilesResult(
      paths: (json['paths'] as List<dynamic>).map((e) => e as String).toList(),
      isComplete: json['isComplete'] as bool,
      baseSha: json['baseSha'] as String?,
      headSha: json['headSha'] as String?,
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$ChangedFilesResultToJson(ChangedFilesResult instance) =>
    <String, dynamic>{
      'paths': instance.paths,
      'baseSha': instance.baseSha,
      'headSha': instance.headSha,
      'isComplete': instance.isComplete,
      'reason': instance.reason,
    };
