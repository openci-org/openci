// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'diff_entry_status.dart';

part 'diff_entry.freezed.dart';
part 'diff_entry.g.dart';

/// Diff Entry
@Freezed()
abstract class DiffEntry with _$DiffEntry {
  const factory DiffEntry({
    required String? sha,
    required String filename,
    @JsonKey(name: 'Status')
    required DiffEntryStatus status,
    required int additions,
    required int deletions,
    required int changes,
    @JsonKey(name: 'blob_url')
    required String blobUrl,
    @JsonKey(name: 'raw_url')
    required String rawUrl,
    @JsonKey(name: 'contents_url')
    required String contentsUrl,
    String? patch,
    @JsonKey(name: 'previous_filename')
    String? previousFilename,
  }) = _DiffEntry;
  
  factory DiffEntry.fromJson(Map<String, Object?> json) => _$DiffEntryFromJson(json);
}
