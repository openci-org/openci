import 'dart:io';

import 'package:meta/meta.dart';
import 'package:openci_server/github/create_github_client.dart';
import 'package:openci_server/github/github_connection_exception.dart';

Future<GitHubUser> fetchGitHubUser({
  required String accessToken,
  Map<String, String>? environment,
  @visibleForTesting Duration timeout = const Duration(seconds: 10),
}) async {
  final github = createGitHubClient(
    accessToken: accessToken,
    environment: environment,
  );
  try {
    return await github
        .getJSON<Map<String, dynamic>, GitHubUser>(
          '/user',
          statusCode: HttpStatus.ok,
          fail: (response) => throw GitHubConnectionException.fromResponse(
            response,
            message: 'Failed to fetch GitHub user',
          ),
          convert: _readUser,
        )
        .timeout(timeout);
  } on GitHubConnectionException {
    rethrow;
  } catch (_) {
    // Response bodies and transport errors may contain private information.
    throw const HttpException('Failed to fetch GitHub user');
  } finally {
    github.dispose();
  }
}

GitHubUser _readUser(Map<String, dynamic> data) {
  // CurrentUser.fromJson truncates fractional IDs, so validate the raw value.
  final id = data['id'];
  final login = data['login'];
  if (id is! int || id <= 0 || login is! String || login.trim().isEmpty) {
    throw const FormatException('Invalid GitHub user');
  }
  return GitHubUser(id: id, login: login);
}

class GitHubUser {
  const GitHubUser({required this.id, required this.login});

  final int id;
  final String login;
}
