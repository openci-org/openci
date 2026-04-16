// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_permissions.dart';
import 'installation_token_repository_selection.dart';
import 'repository.dart';

part 'installation_token.freezed.dart';
part 'installation_token.g.dart';

/// Authentication token for a GitHub App installed on a user or org.
@Freezed()
abstract class InstallationToken with _$InstallationToken {
  const factory InstallationToken({
    required String token,
    @JsonKey(name: 'expires_at') required String expiresAt,
    AppPermissions? permissions,
    @JsonKey(name: 'repository_selection')
    InstallationTokenRepositorySelection? repositorySelection,
    List<Repository>? repositories,
    @JsonKey(name: 'single_file') String? singleFile,
    @JsonKey(name: 'has_multiple_single_files') bool? hasMultipleSingleFiles,
    @JsonKey(name: 'single_file_paths') List<String>? singleFilePaths,
  }) = _InstallationToken;

  factory InstallationToken.fromJson(Map<String, Object?> json) =>
      _$InstallationTokenFromJson(json);
}
