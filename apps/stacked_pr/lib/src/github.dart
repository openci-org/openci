import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'config.dart';
import 'models.dart';
import 'deadline.dart';

class ApiException implements Exception {
  const ApiException(this.method, this.path, this.status);
  final String method, path;
  final int status;
  @override
  String toString() => 'GitHub API $method ${path.split('?').first} returned $status';
}

String appJwt(String appId, RSAPrivateKey key, {DateTime? now}) {
  final timestamp = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
  return JWT({
    'iat': timestamp - 60,
    'exp': timestamp + 540,
    'iss': appId,
  }).sign(key, algorithm: JWTAlgorithm.RS256, noIssueAt: true);
}

http.Client createHttpClient(Map<String, String> environment) {
  final context = SecurityContext(withTrustedRoots: true);
  final ca = environment['GITHUB_CA_FILE'];
  if (ca != null && ca.isNotEmpty) context.setTrustedCertificates(ca);
  final proxyEnv = {...environment};
  for (final name in ['HTTP_PROXY', 'HTTPS_PROXY', 'NO_PROXY']) {
    if (environment[name] != null) {
      proxyEnv.putIfAbsent(name.toLowerCase(), () => environment[name]!);
    }
  }
  final client = HttpClient(context: context)
    ..connectionTimeout = const Duration(seconds: 30)
    ..findProxy = (uri) => HttpClient.findProxyFromEnvironment(uri, environment: proxyEnv);
  return IOClient(client);
}

class GitHubApi {
  GitHubApi(this.config, {http.Client? client, this.deadline})
    : client = client ?? createHttpClient(Platform.environment);
  final AppConfig config;
  final http.Client client;
  final Deadline? deadline;
  final _tokens = <int, ({String token, DateTime expires})>{};
  Json? _app;

  Future<Object?> raw(String token, String method, String path, [Json? body]) async {
    if (!path.startsWith('/') || path.startsWith('//')) throw ArgumentError('Invalid API path');
    final timeout = deadline?.limit(const Duration(seconds: 30)) ?? const Duration(seconds: 30);
    final request =
        http.Request(
            method,
            path == '/graphql' ? config.graphqlUrl : Uri.parse('${config.apiUrl}$path'),
          )
          ..followRedirects = false
          ..headers.addAll({
            HttpHeaders.authorizationHeader: 'Bearer $token',
            HttpHeaders.acceptHeader: 'application/vnd.github+json',
            'x-github-api-version': '2022-11-28',
            HttpHeaders.userAgentHeader: 'stacked-pr-app',
          });
    if (body != null) {
      request.headers[HttpHeaders.contentTypeHeader] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    final response = await (() async {
      final streamed = await client.send(request);
      return http.Response.fromStream(streamed);
    })().timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Do not retain response content, credentials, or transport exceptions in logs.
      throw ApiException(method, path, response.statusCode);
    }
    return response.statusCode == 204 ? null : jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<Json> identity() async =>
      _app ??= jsonObject(await raw(appJwt(config.appId, config.privateKey), 'GET', '/app'));

  Future<String> token(int installation) async {
    final old = _tokens[installation];
    if (old != null && old.expires.isAfter(DateTime.now().add(const Duration(minutes: 2)))) {
      return old.token;
    }
    final result = jsonObject(
      await raw(
        appJwt(config.appId, config.privateKey),
        'POST',
        '/app/installations/$installation/access_tokens',
        {},
      ),
    );
    final token = result['token'] as String;
    _tokens[installation] = (token: token, expires: DateTime.parse(result['expires_at'] as String));
    return token;
  }

  Future<Object?> request(int installation, String method, String path, [Json? body]) async {
    try {
      return await raw(await token(installation), method, path, body);
    } on ApiException catch (error) {
      if (error.status != 401) rethrow;
      _tokens.remove(installation);
      return raw(await token(installation), method, path, body);
    }
  }

  Future<List<Json>> list(int installation, String path, {String? field}) async {
    final result = <Json>[];
    for (var page = 1; ; page++) {
      final separator = path.contains('?') ? '&' : '?';
      final data = await request(installation, 'GET', '$path${separator}per_page=100&page=$page');
      final items = jsonObjects(field == null ? data : jsonObject(data)[field]);
      result.addAll(items);
      if (items.length < 100) return result;
    }
  }

  Future<bool> canWrite(int installation, String repoPath, String? login) async {
    if (login == null || login.isEmpty) return false;
    try {
      final result = jsonObject(
        await request(
          installation,
          'GET',
          '$repoPath/collaborators/${Uri.encodeComponent(login)}/permission',
        ),
      );
      final user = result['user'] == null ? <String, Object?>{} : jsonObject(result['user']);
      final permissions = user['permissions'] == null
          ? <String, Object?>{}
          : jsonObject(user['permissions']);
      return permissions['push'] == true ||
          ['admin', 'write', 'maintain'].contains(result['permission']);
    } on ApiException catch (error) {
      if (error.status == 404) return false;
      rethrow;
    }
  }

  /// PR timelines, unlike a fresh clone's reflog, include earlier branch tips.
  Future<List<Json>> timeline(int installation, Repository repo, int number) async {
    final parts = repo.fullName.split('/');
    final result = <Json>[];
    String? cursor;
    do {
      final response = jsonObject(
        await request(installation, 'POST', '/graphql', {
          'query': r'''
query StackHistory($owner: String!, $name: String!, $number: Int!, $cursor: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      timelineItems(first: 100, after: $cursor, itemTypes: [
        HEAD_REF_FORCE_PUSHED_EVENT, BASE_REF_CHANGED_EVENT, AUTOMATIC_BASE_CHANGE_SUCCEEDED_EVENT
      ]) {
        nodes {
          __typename
          ... on HeadRefForcePushedEvent {
            createdAt beforeCommit { oid } afterCommit { oid }
          }
          ... on BaseRefChangedEvent { createdAt previousRefName currentRefName }
          ... on AutomaticBaseChangeSucceededEvent { createdAt oldBase newBase }
        }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
}''',
          'variables': {'owner': parts[0], 'name': parts[1], 'number': number, 'cursor': cursor},
        }),
      );
      if (response['errors'] != null) throw const RetryException('GitHub history query failed');
      final data = jsonObject(response['data']);
      if (data['repository'] == null || jsonObject(data['repository'])['pullRequest'] == null) {
        throw const RetryException('Pull request history unavailable');
      }
      final pr = jsonObject(jsonObject(data['repository'])['pullRequest']);
      final items = jsonObject(pr['timelineItems']);
      result.addAll(jsonObjects(items['nodes']));
      final page = jsonObject(items['pageInfo']);
      if (page['hasNextPage'] != true) break;
      final next = page['endCursor'] as String?;
      if (next == null || next == cursor) throw const RetryException('Incomplete PR history');
      cursor = next;
    } while (true);
    return result;
  }

  Future<Map<int, List<Json>>> timelines(
    int installation,
    Repository repo,
    List<int> numbers,
  ) async {
    final result = <int, List<Json>>{};
    final parts = repo.fullName.split('/');
    for (var start = 0; start < numbers.length; start += 20) {
      final batch = numbers.skip(start).take(20).toList();
      if (batch.any((n) => n <= 0)) throw ArgumentError('Invalid PR number');
      final fields = batch
          .map(
            (n) =>
                '''
pr$n: pullRequest(number: $n) {
  timelineItems(first: 100, itemTypes: [
    HEAD_REF_FORCE_PUSHED_EVENT, BASE_REF_CHANGED_EVENT, AUTOMATIC_BASE_CHANGE_SUCCEEDED_EVENT
  ]) {
    nodes {
      __typename
      ... on HeadRefForcePushedEvent { createdAt beforeCommit { oid } afterCommit { oid } }
      ... on BaseRefChangedEvent { createdAt previousRefName currentRefName }
      ... on AutomaticBaseChangeSucceededEvent { createdAt oldBase newBase }
    }
    pageInfo { hasNextPage endCursor }
  }
}''',
          )
          .join('\n');
      final response = jsonObject(
        await request(installation, 'POST', '/graphql', {
          'query':
              'query StackHistories(\$owner: String!, \$name: String!) { '
              'repository(owner: \$owner, name: \$name) { $fields }}',
          'variables': {'owner': parts[0], 'name': parts[1]},
        }),
      );
      if (response['errors'] != null) throw const RetryException('GitHub history query failed');
      final repository = jsonObject(jsonObject(response['data'])['repository']);
      for (final number in batch) {
        if (repository['pr$number'] == null) throw const RetryException('PR history unavailable');
        final items = jsonObject(jsonObject(repository['pr$number'])['timelineItems']);
        result[number] = jsonObject(items['pageInfo'])['hasNextPage'] == true
            ? await timeline(installation, repo, number)
            : jsonObjects(items['nodes']);
      }
    }
    return result;
  }

  Future<bool> installationActive(int installation) async {
    try {
      final value = jsonObject(
        await raw(
          appJwt(config.appId, config.privateKey),
          'GET',
          '/app/installations/$installation',
        ),
      );
      return value['id'] == installation && value['suspended_at'] == null;
    } on ApiException catch (e) {
      if (e.status == 404) return false;
      rethrow;
    }
  }

  void close() => client.close();
}
