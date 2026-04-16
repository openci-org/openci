// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_search_index_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CodeSearchIndexStatus _$CodeSearchIndexStatusFromJson(
  Map<String, dynamic> json,
) => _CodeSearchIndexStatus(
  lexicalSearchOk: json['lexical_search_ok'] as bool?,
  lexicalCommitSha: json['lexical_commit_sha'] as String?,
);

Map<String, dynamic> _$CodeSearchIndexStatusToJson(
  _CodeSearchIndexStatus instance,
) => <String, dynamic>{
  'lexical_search_ok': instance.lexicalSearchOk,
  'lexical_commit_sha': instance.lexicalCommitSha,
};
