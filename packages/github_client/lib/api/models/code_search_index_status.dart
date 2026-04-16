// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'code_search_index_status.freezed.dart';
part 'code_search_index_status.g.dart';

@Freezed()
abstract class CodeSearchIndexStatus with _$CodeSearchIndexStatus {
  const factory CodeSearchIndexStatus({
    @JsonKey(name: 'lexical_search_ok') bool? lexicalSearchOk,
    @JsonKey(name: 'lexical_commit_sha') String? lexicalCommitSha,
  }) = _CodeSearchIndexStatus;

  factory CodeSearchIndexStatus.fromJson(Map<String, Object?> json) =>
      _$CodeSearchIndexStatusFromJson(json);
}
