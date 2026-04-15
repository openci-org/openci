// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commit2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Commit2 _$Commit2FromJson(Map<String, dynamic> json) => _Commit2(
  url: json['url'] as String,
  author: json['author'] == null
      ? null
      : NullableGitUser.fromJson(json['author'] as Map<String, dynamic>),
  committer: json['committer'] == null
      ? null
      : NullableGitUser.fromJson(json['committer'] as Map<String, dynamic>),
  message: json['message'] as String,
  commentCount: (json['comment_count'] as num).toInt(),
  tree: Tree.fromJson(json['tree'] as Map<String, dynamic>),
  verification: json['Verification'] == null
      ? null
      : Verification.fromJson(json['Verification'] as Map<String, dynamic>),
);

Map<String, dynamic> _$Commit2ToJson(_Commit2 instance) => <String, dynamic>{
  'url': instance.url,
  'author': instance.author,
  'committer': instance.committer,
  'message': instance.message,
  'comment_count': instance.commentCount,
  'tree': instance.tree,
  'Verification': instance.verification,
};
