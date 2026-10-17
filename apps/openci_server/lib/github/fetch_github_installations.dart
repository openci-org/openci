import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/github/create_github_client.dart';
import 'package:openci_server/github/github_connection_exception.dart';

part 'fetch_github_installations.freezed.dart';

const _perPage = 100;
const _maxPages = 10;

Future<List<GitHubInstallation>> fetchGitHubInstallations({
  required String accessToken,
  Map<String, String>? environment,
  @visibleForTesting Duration timeout = const Duration(seconds: 10),
}) async {
  final github = createGitHubClient(
    accessToken: accessToken,
    environment: environment,
  );
  try {
    return await _fetchPages(github, timeout);
  } on GitHubConnectionException {
    rethrow;
  } catch (_) {
    throw const HttpException('Failed to fetch GitHub installations');
  } finally {
    github.dispose();
  }
}

Future<List<GitHubInstallation>> _fetchPages(
  GitHub github,
  Duration timeout,
) async {
  final stopwatch = Stopwatch()..start();
  final installations = <GitHubInstallation>[];
  final ids = <int>{};
  int? totalCount;

  for (var page = 1; page <= _maxPages; page++) {
    final remaining = timeout - stopwatch.elapsed;
    if (remaining <= Duration.zero) throw TimeoutException('GitHub timeout');
    // Avoid the package's automatic wait until the rate limit resets.
    if ((github.rateLimitRemaining ?? 1) <= 0) {
      throw const HttpException('GitHub rate limit reached');
    }
    final result = await _fetchPage(github, page, remaining);
    if (totalCount != null && totalCount != result.totalCount) {
      throw const FormatException('GitHub installation count changed');
    }
    totalCount = result.totalCount;
    for (final installation in result.installations) {
      if (!ids.add(installation.id)) {
        throw const FormatException('Duplicate GitHub installation');
      }
      installations.add(installation);
    }
    if (installations.length == totalCount && !result.hasNext) {
      return List.unmodifiable(installations);
    }
    if (installations.length >= totalCount ||
        result.installations.length != _perPage) {
      throw const FormatException('Incomplete GitHub installation list');
    }
  }
  throw const FormatException('GitHub installation limit exceeded');
}

Future<_InstallationPage> _fetchPage(
  GitHub github,
  int page,
  Duration timeout,
) async {
  // Build page URLs ourselves; never follow a URL from the Link header.
  final response = await github
      .request(
        'GET',
        '/user/installations',
        params: {'per_page': _perPage, 'page': page},
        headers: {
          'Accept': v3ApiMimeType,
          'X-GitHub-Api-Version': github.version,
        },
        statusCode: HttpStatus.ok,
        fail: (response) => throw GitHubConnectionException.fromResponse(
          response,
          message: 'Failed to fetch GitHub installations',
        ),
      )
      .timeout(timeout);
  return _readPage(response);
}

_InstallationPage _readPage(http.Response response) {
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final totalCount = data['total_count'];
  final items = data['installations'];
  if (totalCount is! int ||
      totalCount < 0 ||
      totalCount > _perPage * _maxPages ||
      items is! List ||
      items.length > _perPage) {
    throw const FormatException('Invalid GitHub installation page');
  }
  final link = response.headers['link'];
  return _InstallationPage(
    totalCount: totalCount,
    installations: items
        .map((item) => _readInstallation(item as Map<String, dynamic>))
        .toList(),
    hasNext: link != null && parseLinkHeader(link).containsKey('next'),
  );
}

GitHubInstallation _readInstallation(Map<String, dynamic> data) {
  final account = data['account'] as Map<String, dynamic>;
  final type = account['type'];
  final login = account['login'];
  final suspended = data['suspended_at'];
  final suspendedAt = suspended is String ? DateTime.tryParse(suspended) : null;
  if ((type != 'User' && type != 'Organization') ||
      login is! String ||
      login.trim().isEmpty ||
      !data.containsKey('suspended_at') ||
      (suspended != null && suspendedAt == null)) {
    throw const FormatException(
      'Invalid GitHub installation account or status',
    );
  }
  return GitHubInstallation(
    id: _readId(data['id']),
    appId: _readId(data['app_id']),
    accountId: _readId(account['id']),
    accountType: type as String,
    accountLogin: login,
    suspendedAt: suspendedAt?.toUtc(),
  );
}

int _readId(Object? value) {
  if (value is! int || value <= 0) {
    throw const FormatException('Invalid GitHub installation or account ID');
  }
  return value;
}

@freezed
abstract class _InstallationPage with _$InstallationPage {
  const factory _InstallationPage({
    required int totalCount,
    required List<GitHubInstallation> installations,
    required bool hasNext,
  }) = _InstallationPageData;
}

@freezed
abstract class GitHubInstallation with _$GitHubInstallation {
  const factory GitHubInstallation({
    required int id,
    required int appId,
    required int accountId,
    required String accountType,
    required String accountLogin,
    required DateTime? suspendedAt,
  }) = _GitHubInstallation;
}
