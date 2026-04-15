// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diff_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DiffEntry _$DiffEntryFromJson(Map<String, dynamic> json) => _DiffEntry(
  sha: json['sha'] as String?,
  filename: json['filename'] as String,
  status: DiffEntryStatus.fromJson(json['Status'] as String),
  additions: (json['additions'] as num).toInt(),
  deletions: (json['deletions'] as num).toInt(),
  changes: (json['changes'] as num).toInt(),
  blobUrl: json['blob_url'] as String,
  rawUrl: json['raw_url'] as String,
  contentsUrl: json['contents_url'] as String,
  patch: json['patch'] as String?,
  previousFilename: json['previous_filename'] as String?,
);

Map<String, dynamic> _$DiffEntryToJson(_DiffEntry instance) =>
    <String, dynamic>{
      'sha': instance.sha,
      'filename': instance.filename,
      'Status': _$DiffEntryStatusEnumMap[instance.status]!,
      'additions': instance.additions,
      'deletions': instance.deletions,
      'changes': instance.changes,
      'blob_url': instance.blobUrl,
      'raw_url': instance.rawUrl,
      'contents_url': instance.contentsUrl,
      'patch': instance.patch,
      'previous_filename': instance.previousFilename,
    };

const _$DiffEntryStatusEnumMap = {
  DiffEntryStatus.added: 'added',
  DiffEntryStatus.removed: 'removed',
  DiffEntryStatus.modified: 'modified',
  DiffEntryStatus.renamed: 'renamed',
  DiffEntryStatus.copied: 'copied',
  DiffEntryStatus.changed: 'changed',
  DiffEntryStatus.unchanged: 'unchanged',
  DiffEntryStatus.$unknown: r'$unknown',
};
