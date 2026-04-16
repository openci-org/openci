// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'nullable_git_user.dart';
import 'tree.dart';
import 'verification.dart';

part 'commit2.freezed.dart';
part 'commit2.g.dart';

@Freezed()
abstract class Commit2 with _$Commit2 {
  const factory Commit2({
    required String url,
    required NullableGitUser? author,
    required NullableGitUser? committer,
    required String message,
    @JsonKey(name: 'comment_count') required int commentCount,
    required Tree tree,
    @JsonKey(name: 'Verification') Verification? verification,
  }) = _Commit2;

  factory Commit2.fromJson(Map<String, Object?> json) =>
      _$Commit2FromJson(json);
}
