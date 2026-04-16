// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/app_installations_installation_id_access_tokens_request_body.dart';
import '../models/installation_token.dart';

part 'apps_client.g.dart';

@RestApi()
abstract class AppsClient {
  factory AppsClient(Dio dio, {String? baseUrl}) = _AppsClient;

  /// Create an Installation access token for an app.
  ///
  /// Creates an Installation access token that enables a GitHub App to make authenticated API requests for the app's Installation on an organization or individual account. Installation tokens expire one hour from the time you create them. Using an expired token produces a Status code of `401 - Unauthorized`, and requires creating a new Installation token. By default the Installation token has access to all repositories that the Installation can access.
  ///
  /// Optionally, you can use the `repositories` or `repository_ids` body parameters to specify individual repositories that the Installation access token can access. If you don't use `repositories` or `repository_ids` to grant access to specific repositories, the Installation access token will have access to all repositories that the Installation was granted access to. The Installation access token cannot be granted access to repositories that the Installation was not granted access to. Up to 500 repositories can be listed in this manner.
  ///
  /// Optionally, use the `permissions` body parameter to specify the permissions that the Installation access token should have. If `permissions` is not specified, the Installation access token will have all of the permissions that were granted to the app. The Installation access token cannot be granted permissions that the app was not granted.
  ///
  /// You must use a [JWT](https://docs.github.com/apps/building-github-apps/authenticating-with-github-apps/#authenticating-as-a-github-app) to access this endpoint.
  ///
  /// [installationId] - The unique identifier of the installation.
  @POST('/app/installations/{installation_id}/access_tokens')
  Future<InstallationToken> appsCreateInstallationAccessToken({
    @Path('installation_id') required int installationId,
    @Body() AppInstallationsInstallationIdAccessTokensRequestBody? body,
  });
}
