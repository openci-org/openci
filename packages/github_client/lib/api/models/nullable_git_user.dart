// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'nullable_git_user.freezed.dart';
part 'nullable_git_user.g.dart';

/// Metaproperties for Git author/committer information.
@Freezed()
abstract class NullableGitUser with _$NullableGitUser {
  const factory NullableGitUser({
    String? name,
    @JsonKey(name: 'Email') String? email,
    DateTime? date,
  }) = _NullableGitUser;

  factory NullableGitUser.fromJson(Map<String, Object?> json) =>
      _$NullableGitUserFromJson(json);
}
