import 'dart:io';

import 'package:openci_server/github/create_github_client.dart';
import 'package:openci_server/github/fetch_github_installations.dart';
import 'package:openci_server/github/fetch_github_user.dart';

Future<GitHubInstallation?> verifyGitHubInstallation({
  required String accessToken,
  required int installationId,
  Map<String, String>? environment,
  Duration membershipTimeout = const Duration(seconds: 10),
}) async {
  if (installationId <= 0) {
    throw ArgumentError('A positive GitHub installation ID is required');
  }
  final env = environment ?? Platform.environment;
  final appId = int.tryParse(env['GITHUB_APP_ID']?.trim() ?? '', radix: 10);
  if (appId == null || appId <= 0) {
    throw StateError('GITHUB_APP_ID must be a positive integer');
  }

  // The supplied ID selects a candidate; GitHub supplies the identity and facts.
  final user = await fetchGitHubUser(
    accessToken: accessToken,
    environment: env,
  );
  final installations = await fetchGitHubInstallations(
    accessToken: accessToken,
    environment: env,
  );
  final installation = installations
      .where((candidate) => candidate.id == installationId)
      .firstOrNull;
  if (installation == null ||
      installation.appId != appId ||
      installation.suspendedAt != null) {
    return null;
  }

  if (installation.accountType == 'User') {
    return installation.accountId == user.id ? installation : null;
  }
  if (installation.accountType != 'Organization') return null;

  final isAdmin = await _isOrganizationAdmin(
    accessToken: accessToken,
    userId: user.id,
    installation: installation,
    environment: env,
    timeout: membershipTimeout,
  );
  return isAdmin ? installation : null;
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
        )
        .timeout(timeout);
    return _isActiveAdmin(membership, userId, installation.accountId);
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
