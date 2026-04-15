// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_search_index_status2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CodeSearchIndexStatus2 _$CodeSearchIndexStatus2FromJson(
  Map<String, dynamic> json,
) => _CodeSearchIndexStatus2(
  lexicalSearchOk: json['lexical_search_ok'] as bool?,
  lexicalCommitSha: json['lexical_commit_sha'] as String?,
);

Map<String, dynamic> _$CodeSearchIndexStatus2ToJson(
  _CodeSearchIndexStatus2 instance,
) => <String, dynamic>{
  'lexical_search_ok': instance.lexicalSearchOk,
  'lexical_commit_sha': instance.lexicalCommitSha,
};
