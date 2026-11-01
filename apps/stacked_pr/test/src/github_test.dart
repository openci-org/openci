import 'dart:convert';
import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:stacked_pr_app/src/config.dart';
import 'package:stacked_pr_app/src/github.dart';
import 'package:stacked_pr_app/src/models.dart';
import '../support/fixtures.dart';
import '../support/mocks.mocks.dart';

http.StreamedResponse response(Object? body, {int status = 200}) =>
    http.StreamedResponse(Stream.value(utf8.encode(jsonEncode(body))), status);

void main() {
  test('App JWT has verifiable RS256 signature and bounded lifetime', () {
    final token = appJwt(
      '123',
      config().privateKey,
      now: DateTime.fromMillisecondsSinceEpoch(1800000000000),
    );
    final verified = JWT.verify(
      token,
      RSAPublicKey(File('test/fixtures/test_public_key.txt').readAsStringSync()),
      checkExpiresIn: false,
    );
    final claims = jsonObject(verified.payload);
    expect(claims['iss'], '123');
    expect((claims['exp'] as int) - (claims['iat'] as int), 600);
    expect(claims['iat'], 1799999940);
  });
  test('GHES pagination stays on configured origin with redirects disabled', () async {
    final client = MockClient();
    final urls = <Uri>[];
    when(client.send(any)).thenAnswer((invocation) async {
      final request = invocation.positionalArguments.single as http.BaseRequest;
      urls.add(request.url);
      expect(request.followRedirects, isFalse);
      if (request.url.path.endsWith('/access_tokens')) {
        return response({
          'token': 'fake-token',
          'expires_at': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        });
      }
      expect(request.headers['authorization'], 'Bearer fake-token');
      return response(
        request.url.queryParameters['page'] == '1'
            ? List.generate(100, (id) => {'id': id})
            : [
                {'id': 100},
              ],
      );
    });
    final api = GitHubApi(config(), client: client);
    expect(await api.list(1, '/repos/org/repo/pulls?state=open'), hasLength(101));
    expect(
      urls.every((url) => url.toString().startsWith('https://git.example.com/api/v3/')),
      isTrue,
    );
    expect(urls.where((u) => u.path.endsWith('/access_tokens')), hasLength(1));
  });
  test('401 refreshes installation token exactly once without response leakage', () async {
    final client = MockClient();
    var tokens = 0, requests = 0;
    when(client.send(any)).thenAnswer((invocation) async {
      final request = invocation.positionalArguments.single as http.BaseRequest;
      if (request.url.path.endsWith('/access_tokens')) {
        tokens++;
        return response({
          'token': 'token-$tokens',
          'expires_at': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        });
      }
      requests++;
      return requests == 1 ? response('sensitive body', status: 401) : response({'ok': true});
    });
    final api = GitHubApi(config(), client: client);
    expect(await api.request(1, 'GET', '/test'), {'ok': true});
    expect(tokens, 2);
    expect(requests, 2);
    when(client.send(any)).thenAnswer((_) async => response('sensitive credentials', status: 403));
    await expectLater(
      api.raw('token', 'GET', '/forbidden'),
      throwsA(
        isA<ApiException>().having((e) => e.toString(), 'message', isNot(contains('sensitive'))),
      ),
    );
  });
  test('config validates URL and environment values before startup', () {
    final env = {
      'GITHUB_URL': 'https://git.example.com/',
      'GITHUB_APP_ID': '7',
      'GITHUB_PRIVATE_KEY_FILE': 'test/fixtures/test_key.txt',
      'GITHUB_WEBHOOK_SECRET': secret,
    };
    expect(AppConfig.fromEnvironment(env).apiUrl.toString(), 'https://git.example.com/api/v3');
    expect(
      AppConfig.fromEnvironment({...env, 'GITHUB_URL': 'https://github.com'}).apiUrl.toString(),
      'https://api.github.com',
    );
    for (final invalid in [
      'http://git.example.com',
      'https://user:pass@git.example.com',
      'https://git.example.com/path',
    ]) {
      expect(
        () => AppConfig.fromEnvironment({...env, 'GITHUB_URL': invalid}),
        throwsFormatException,
      );
    }
    expect(() => AppConfig.fromEnvironment({...env, 'AUTO_RESTACK': 'yes'}), throwsFormatException);
    expect(
      () => AppConfig.fromEnvironment({...env, 'GITHUB_WEBHOOK_SECRET': 'short'}),
      throwsFormatException,
    );
  });
}
