// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_permissions.dart';

part 'app_installations_installation_id_access_tokens_request_body.freezed.dart';
part 'app_installations_installation_id_access_tokens_request_body.g.dart';

@Freezed()
abstract class AppInstallationsInstallationIdAccessTokensRequestBody with _$AppInstallationsInstallationIdAccessTokensRequestBody {
  const factory AppInstallationsInstallationIdAccessTokensRequestBody({
    /// List of Repository names that the token should have access to
    List<String>? repositories,

    /// List of Repository IDs that the token should have access to
    @JsonKey(name: 'repository_ids')
    List<int>? repositoryIds,
    AppPermissions? permissions,
  }) = _AppInstallationsInstallationIdAccessTokensRequestBody;
  
  factory AppInstallationsInstallationIdAccessTokensRequestBody.fromJson(Map<String, Object?> json) => _$AppInstallationsInstallationIdAccessTokensRequestBodyFromJson(json);
}
