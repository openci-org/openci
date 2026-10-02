import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';

import 'github_service.dart';

/// Fetches a complete diff for a stored webhook, or an indeterminate result.
Future<ChangedFilesResult> fetchChangedFiles({
  required String eventType,
  required String payload,
  Map<String, String>? environment,
  http.Client? client,
  Duration timeout = const Duration(seconds: 30),
}) async {
  String? baseSha;
  String? headSha;
  ChangedFilesResult incomplete(String reason) => ChangedFilesResult(
    paths: const [],
    baseSha: baseSha,
    headSha: headSha,
    isComplete: false,
    reason: reason,
  );

  final httpClient = client ?? http.Client();
  try {
    final data = jsonDecode(payload);
    if (eventType == 'pull_request') {
      if (data case {
        'pull_request': {
          'base': {'sha': final String base},
          'head': {'sha': final String head},
        },
      }) {
        baseSha = base;
        headSha = head;
      }
    } else if (eventType == 'push') {
      if (data case {'before': final String base, 'after': final String head}) {
        baseSha = base;
        headSha = head;
      }
      if (data case {'deleted': true}) return incomplete('branch_deleted');
      if (data case {'created': true}) return incomplete('new_branch');
      if (baseSha == '0' * 40) return incomplete('new_branch');
      if (data case {'forced': true}) return incomplete('force_push');
      if (data case {'created': false, 'deleted': false, 'forced': false}) {
        // Only a normal push can provide a reliable before/after diff.
      } else {
        return incomplete('invalid_webhook');
      }
    } else {
      return incomplete('unsupported_event');
    }

    if (!_isSha(baseSha) || !_isSha(headSha)) {
      return incomplete('invalid_webhook');
    }
    if (data case {
      'repository': {
        'owner': {'login': final String owner},
        'name': final String repo,
      },
      'installation': {'id': final int installationId},
    } when owner.isNotEmpty && repo.isNotEmpty && installationId > 0) {
      final env = {...environment ?? Platform.environment};
      final baseUrl = env['GITHUB_API_BASE_URL'];
      if (baseUrl == null || baseUrl.isEmpty) {
        return incomplete('github_not_configured');
      }
      env['GITHUB_API_BASE_URL'] = baseUrl.replaceFirst(RegExp(r'/+$'), '');
      final apiUri = Uri.tryParse(env['GITHUB_API_BASE_URL']!);
      if (apiUri == null ||
          !{'https', 'http'}.contains(apiUri.scheme) ||
          apiUri.host.isEmpty ||
          apiUri.hasQuery ||
          apiUri.hasFragment) {
        return incomplete('github_not_configured');
      }
      final fetcher = _ChangedFilesFetcher(httpClient, env, timeout);
      final paths = await fetcher.fetch(
        eventType: eventType,
        data: data,
        owner: owner,
        repo: repo,
        installationId: installationId,
        baseSha: baseSha!,
        headSha: headSha!,
      );
      return ChangedFilesResult(
        paths: paths,
        baseSha: baseSha,
        headSha: headSha,
        isComplete: true,
      );
    }
    return incomplete('invalid_webhook');
  } on _Indeterminate catch (e) {
    return incomplete(e.reason);
  } on TimeoutException {
    return incomplete('github_timeout');
  } on FormatException {
    return incomplete('invalid_response');
  } on TypeError {
    return incomplete('invalid_response');
  } on http.ClientException {
    return incomplete('github_unavailable');
  } on IOException {
    return incomplete('github_unavailable');
  } on StateError {
    return incomplete('github_not_configured');
  } finally {
    if (client == null) httpClient.close();
  }
}

class _ChangedFilesFetcher {
  _ChangedFilesFetcher(this.client, this.environment, this.timeout);

  final http.Client client;
  final Map<String, String> environment;
  final Duration timeout;
  final Stopwatch stopwatch = Stopwatch()..start();
  late Map<String, String> headers;
  late String repositoryUrl;

  Future<T> _withinDeadline<T>(Future<T> Function() request) {
    final remaining = timeout - stopwatch.elapsed;
    if (remaining <= Duration.zero) throw TimeoutException('GitHub deadline');
    return request().timeout(remaining);
  }

  Future<List<String>> fetch({
    required String eventType,
    required dynamic data,
    required String owner,
    required String repo,
    required int installationId,
    required String baseSha,
    required String headSha,
  }) async {
    if (eventType == 'push' && baseSha == headSha) return const [];
    final int? number = data['number'] is int ? data['number'] as int : null;
    if (eventType == 'pull_request' && (number == null || number <= 0)) {
      throw const _Indeterminate('invalid_webhook');
    }
    final String token;
    try {
      token = await _withinDeadline(
        () => GitHubService.getInstallationToken(
          installationIdStr: installationId.toString(),
          environment: environment,
          client: client,
        ),
      );
    } on HttpException {
      throw const _Indeterminate('github_authentication_failed');
    }
    if (token.isEmpty) throw const _Indeterminate('invalid_response');
    headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'OpenCI-Server',
    };
    repositoryUrl =
        '${environment['GITHUB_API_BASE_URL']}/repos/'
        '${Uri.encodeComponent(owner)}/${Uri.encodeComponent(repo)}';
    return eventType == 'pull_request'
        ? _pullRequest(number!, baseSha, headSha)
        : _push(baseSha, headSha);
  }

  Future<http.Response> _get(String path) async {
    final response = await _withinDeadline(
      () => client.get(Uri.parse('$repositoryUrl/$path'), headers: headers),
    );
    if (response.statusCode != HttpStatus.ok) {
      throw _Indeterminate('github_http_${response.statusCode}');
    }
    return response;
  }

  Future<({int count, String? updatedAt})> _snapshot(
    int number,
    String baseSha,
    String headSha,
  ) async {
    final data = jsonDecode((await _get('pulls/$number')).body);
    if (data case {
      'base': {'sha': final String base},
      'head': {'sha': final String head},
      'changed_files': final int count,
    } when count >= 0) {
      if (base != baseSha || head != headSha) {
        throw const _Indeterminate('sha_mismatch');
      }
      return (count: count, updatedAt: data['updated_at'] as String?);
    }
    throw const _Indeterminate('invalid_response');
  }

  Future<List<String>> _pullRequest(
    int number,
    String baseSha,
    String headSha,
  ) async {
    final snapshot = await _snapshot(number, baseSha, headSha);
    // GitHub caps PR files at 3,000. Treat the boundary as indeterminate too.
    if (snapshot.count >= 3000) throw const _Indeterminate('file_limit');
    final paths = <String>{};
    final filenames = <String>{};
    var count = 0;
    for (var page = 1; ; page++) {
      final response = await _get(
        'pulls/$number/files?per_page=100&page=$page',
      );
      final files = jsonDecode(response.body);
      final remaining = snapshot.count - count;
      final expected = remaining > 100 ? 100 : remaining;
      if (files is! List || files.length != expected) {
        throw const _Indeterminate('truncated_response');
      }
      _addPaths(files, paths, filenames);
      count += files.length;
      final current = await _snapshot(number, baseSha, headSha);
      if (current != snapshot) {
        throw const _Indeterminate('pull_request_updated');
      }
      if (count == snapshot.count) {
        if (RegExp(
          r'rel\s*=\s*"next"',
        ).hasMatch(response.headers['link'] ?? '')) {
          throw const _Indeterminate('truncated_response');
        }
        return paths.toList()..sort();
      }
    }
  }

  Future<List<String>> _push(String baseSha, String headSha) async {
    // No paging parameters: GitHub includes the comparison's final commit even
    // when its commit list is capped at 250. Files are capped at 300.
    final data = jsonDecode((await _get('compare/$baseSha...$headSha')).body);
    if (data case {
      'base_commit': {'sha': final String base},
      'merge_base_commit': {'sha': final String mergeBase},
      'status': final String status,
      'commits': final List commits,
      'files': final List files,
    }) {
      if (base != baseSha) throw const _Indeterminate('sha_mismatch');
      if (status != 'ahead' || mergeBase != baseSha) {
        throw const _Indeterminate('non_fast_forward');
      }
      if (commits.isEmpty ||
          commits.last is! Map ||
          commits.last['sha'] != headSha) {
        throw const _Indeterminate('sha_mismatch');
      }
      if (files.length >= 300) throw const _Indeterminate('file_limit');
      final paths = <String>{};
      _addPaths(files, paths, <String>{});
      return paths.toList()..sort();
    }
    throw const _Indeterminate('invalid_response');
  }

  void _addPaths(List files, Set<String> paths, Set<String> filenames) {
    for (final file in files) {
      if (file case {
        'filename': final String name,
        'status': final String status,
      } when _isPath(name)) {
        if (!{
          'added',
          'removed',
          'modified',
          'renamed',
          'copied',
          'changed',
          'unchanged',
        }.contains(status)) {
          throw const _Indeterminate('invalid_response');
        }
        if (!filenames.add(name)) {
          throw const _Indeterminate('truncated_response');
        }
        paths.add(name);
        final previous = file['previous_filename'];
        if (status == 'renamed' || previous != null) {
          if (previous is! String || !_isPath(previous)) {
            throw const _Indeterminate('invalid_response');
          }
          paths.add(previous);
        }
      } else {
        throw const _Indeterminate('invalid_response');
      }
    }
  }
}

bool _isSha(String? sha) =>
    sha != null && RegExp(r'^[0-9a-f]{40}$').hasMatch(sha) && sha != '0' * 40;

bool _isPath(String path) =>
    path.isNotEmpty &&
    !path.contains('\u0000') &&
    path
        .split('/')
        .every((part) => part.isNotEmpty && part != '.' && part != '..');

class _Indeterminate implements Exception {
  const _Indeterminate(this.reason);

  final String reason;
}
