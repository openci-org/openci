import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'config.dart';
import 'models.dart';

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
  GitHubApi(this.config, {http.Client? client})
    : client = client ?? createHttpClient(Platform.environment);
  final AppConfig config;
  final http.Client client;
  final _tokens = <int, ({String token, DateTime expires})>{};
  Json? _app;

  Future<Object?> raw(String token, String method, String path, [Json? body]) async {
    if (!path.startsWith('/') || path.startsWith('//')) throw ArgumentError('Invalid API path');
    final request = http.Request(method, Uri.parse('${config.apiUrl}$path'))
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
    })().timeout(const Duration(seconds: 30));
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

  void close() => client.close();
}
