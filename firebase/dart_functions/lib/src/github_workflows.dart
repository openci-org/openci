import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';

import 'planning_event.dart';

class GitHubWorkflows {
  GitHubWorkflows({
    required this.client,
    required this.apiBaseUrl,
    required this.appJwt,
    bool allowLocalHttp = false,
  }) {
    final uri = Uri.parse(apiBaseUrl);
    if (uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.scheme != 'https' &&
            !(allowLocalHttp &&
                uri.scheme == 'http' &&
                ['localhost', '127.0.0.1'].contains(uri.host)))) {
      throw ArgumentError('GitHub API requires HTTPS');
    }
  }

  final http.Client client;
  final String apiBaseUrl;
  final String Function() appJwt;

  static String signAppJwt(String appId, String privateKey) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return JWT({
      'iat': now - 60,
      'exp': now + 540,
      'iss': appId,
    }).sign(RSAPrivateKey(privateKey), algorithm: JWTAlgorithm.RS256);
  }

  Future<http.Response> _request(
    String method,
    String path,
    String token, {
    Map<String, String>? query,
    Map<String, Object?>? body,
  }) {
    final uri = Uri.parse(
      '${apiBaseUrl.replaceFirst(RegExp(r'/+$'), '')}/$path',
    ).replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..followRedirects = false
      ..headers.addAll({
        'authorization': 'Bearer $token',
        'accept': 'application/vnd.github+json',
        'user-agent': 'OpenCI-BuildJobPlanner',
        'content-type': 'application/json',
      });
    if (body != null) request.body = jsonEncode(body);
    return client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 15));
  }

  Object? _json(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('GitHub request failed');
    }
    return jsonDecode(response.body);
  }

  Future<List<OpenCIFile>> fetch(PlanningEvent event) async {
    final webhook = event.webhook;
    final auth = _json(
      await _request(
        'POST',
        'app/installations/${webhook.installationId}/access_tokens',
        appJwt(),
        body: {
          'repository_ids': [event.repositoryId],
          'permissions': {'contents': 'read'},
        },
      ),
    );
    if (auth is! Map<String, dynamic> ||
        auth['token'] is! String ||
        (auth['token'] as String).isEmpty) {
      throw StateError('GitHub token is unavailable');
    }
    final token = auth['token'] as String;
    final repoPath =
        'repos/${Uri.encodeComponent(webhook.owner)}/${Uri.encodeComponent(webhook.repo)}';
    final repository = _json(await _request('GET', repoPath, token));
    if (repository is! Map<String, dynamic> ||
        repository['id'] != event.repositoryId ||
        repository['owner'] is! Map<String, dynamic> ||
        (repository['owner'] as Map<String, dynamic>)['id'] != event.ownerId) {
      throw const InvalidPlanningInput('invalid_payload');
    }
    // Verify access to the immutable commit before treating a directory 404 as
    // an empty plan. Permission errors must remain retryable.
    _json(
      await _request(
        'GET',
        '$repoPath/git/commits/${webhook.commitSha}',
        token,
      ),
    );
    final query = {'ref': webhook.commitSha};
    final directory = await _request(
      'GET',
      '$repoPath/contents/openci',
      token,
      query: query,
    );
    if (directory.statusCode == 404) return [];
    final entries = _json(directory);
    if (entries is! List<Object?>) return [];
    final sources = entries
        .whereType<Map<String, dynamic>>()
        .where(
          (entry) =>
              entry['type'] == 'file' &&
              entry['name'] is String &&
              (entry['name'] as String).endsWith('.dart'),
        )
        .toList();
    if (sources.length > 100 ||
        sources.any((entry) => entry['size'] is! int) ||
        sources.fold<int>(0, (sum, entry) => sum + (entry['size'] as int)) >
            1024 * 1024) {
      throw const InvalidPlanningInput('invalid_workflow');
    }
    final files = <OpenCIFile>[];
    var totalBytes = 0;
    for (var offset = 0; offset < sources.length; offset += 4) {
      final batch = await Future.wait(
        sources.skip(offset).take(4).map((entry) async {
          final name = entry['name'] as String;
          if (name.contains('/') || name.contains(r'\')) {
            throw const InvalidPlanningInput('invalid_workflow');
          }
          final path = 'openci/$name';
          final data = _json(
            await _request(
              'GET',
              '$repoPath/contents/openci/${Uri.encodeComponent(name)}',
              token,
              query: query,
            ),
          );
          if (data is! Map<String, dynamic> ||
              data['type'] != 'file' ||
              data['encoding'] != 'base64' ||
              data['content'] is! String) {
            throw const InvalidPlanningInput('invalid_workflow');
          }
          try {
            final bytes = base64Decode(
              (data['content'] as String).replaceAll(RegExp(r'\s'), ''),
            );
            totalBytes += bytes.length;
            if (totalBytes > 1024 * 1024) {
              throw const InvalidPlanningInput('invalid_workflow');
            }
            return OpenCIFile(
              name: name,
              path: path,
              content: utf8.decode(bytes),
            );
          } on FormatException {
            throw const InvalidPlanningInput('invalid_workflow');
          }
        }),
      );
      files.addAll(batch);
    }
    return files;
  }
}
