// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'code_search_index_status2.freezed.dart';
part 'code_search_index_status2.g.dart';

@Freezed()
abstract class CodeSearchIndexStatus2 with _$CodeSearchIndexStatus2 {
  const factory CodeSearchIndexStatus2({
    @JsonKey(name: 'lexical_search_ok')
    bool? lexicalSearchOk,
    @JsonKey(name: 'lexical_commit_sha')
    String? lexicalCommitSha,
  }) = _CodeSearchIndexStatus2;
  
  factory CodeSearchIndexStatus2.fromJson(Map<String, Object?> json) => _$CodeSearchIndexStatus2FromJson(json);
}
