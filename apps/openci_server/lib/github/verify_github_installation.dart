import 'dart:io';

import 'package:meta/meta.dart';
import 'package:openci_server/github/create_github_client.dart';
import 'package:openci_server/github/fetch_github_installations.dart';
import 'package:openci_server/github/fetch_github_user.dart';
import 'package:openci_server/github/github_connection_exception.dart';

Future<GitHubInstallation?> verifyGitHubInstallation({
  required String accessToken,
  required int installationId,
  int? expectedGitHubUserId,
  @visibleForTesting Map<String, String>? environment,
  @visibleForTesting Duration membershipTimeout = const Duration(seconds: 10),
}) async {
  if (installationId <= 0) {
    throw ArgumentError('A positive GitHub installation ID is required');
  }
  final env = environment ?? Platform.environment;
  final appId = _readAppId(env);

  // The supplied ID selects a candidate; GitHub supplies the identity and facts.
  final user = await fetchGitHubUser(
    accessToken: accessToken,
    environment: env,
  );
  if (expectedGitHubUserId != null && user.id != expectedGitHubUserId) {
    return null;
  }
  final installations = await fetchGitHubInstallations(
    accessToken: accessToken,
    environment: env,
  );
  final installation = installations
      .where((candidate) => candidate.id == installationId)
      .firstOrNull;
  if (installation == null) return null;

  final canConnect = await _canConnectInstallation(
    accessToken: accessToken,
    userId: user.id,
    appId: appId,
    installation: installation,
    environment: env,
    timeout: membershipTimeout,
  );
  return canConnect ? installation : null;
}

Future<List<GitHubInstallation>> fetchGitHubConnectionCandidates({
  required String accessToken,
  Map<String, String>? environment,
  @visibleForTesting Duration membershipTimeout = const Duration(seconds: 10),
}) async {
  final env = environment ?? Platform.environment;
  final appId = _readAppId(env);
  final user = await fetchGitHubUser(
    accessToken: accessToken,
    environment: env,
  );
  final installations = await fetchGitHubInstallations(
    accessToken: accessToken,
    environment: env,
  );
  final candidates = <GitHubInstallation>[];
  for (final installation in installations) {
    final canConnect = await _canConnectInstallation(
      accessToken: accessToken,
      userId: user.id,
      appId: appId,
      installation: installation,
      environment: env,
      timeout: membershipTimeout,
    );
    if (canConnect) candidates.add(installation);
  }
  return List.unmodifiable(candidates);
}

int _readAppId(Map<String, String> environment) {
  final appId = int.tryParse(
    environment['GITHUB_APP_ID']?.trim() ?? '',
    radix: 10,
  );
  if (appId == null || appId <= 0) {
    throw StateError('GITHUB_APP_ID must be a positive integer');
  }
  return appId;
}

Future<bool> _canConnectInstallation({
  required String accessToken,
  required int userId,
  required int appId,
  required GitHubInstallation installation,
  required Map<String, String> environment,
  required Duration timeout,
}) async {
  if (installation.appId != appId || installation.suspendedAt != null) {
    return false;
  }

  if (installation.accountType == 'User') {
    return installation.accountId == userId;
  }
  if (installation.accountType != 'Organization') return false;

  return _isOrganizationAdmin(
    accessToken: accessToken,
    userId: userId,
    installation: installation,
    environment: environment,
    timeout: timeout,
  );
}

Future<bool> _isOrganizationAdmin({
  required String accessToken,
  required int userId,
  required GitHubInstallation installation,
  required Map<String, String> environment,
  required Duration timeout,
}) async {
  final github = createGitHubClient(
    accessToken: accessToken,
    environment: environment,
  );
  try {
    final org = Uri.encodeComponent(installation.accountLogin);
    final membership = await github
        .getJSON<Map<String, dynamic>, Map<String, dynamic>>(
          '/user/memberships/orgs/$org',
          statusCode: HttpStatus.ok,
          fail: (response) => throw GitHubConnectionException.fromResponse(
            response,
            message: 'Failed to verify GitHub organization membership',
          ),
        )
        .timeout(timeout);
    return _isActiveAdmin(membership, userId, installation.accountId);
  } on GitHubConnectionException {
    rethrow;
  } catch (_) {
    throw const HttpException(
      'Failed to verify GitHub organization membership',
    );
  } finally {
    github.dispose();
  }
}

bool _isActiveAdmin(Map<String, dynamic> data, int userId, int organizationId) {
  final user = data['user'];
  final organization = data['organization'];
  return data['state'] == 'active' &&
      data['role'] == 'admin' &&
      user is Map<String, dynamic> &&
      user['id'] is int &&
      user['id'] == userId &&
      organization is Map<String, dynamic> &&
      organization['id'] is int &&
      organization['id'] == organizationId;
}
