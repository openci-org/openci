import 'dart:convert';
import 'dart:io';

import 'package:github_webhook_processor/github_webhook_processor.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const testRsaPrivateKey = '''
-----BEGIN PRIVATE KEY-----
MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBANiAAR187atVXowj
f+vCsYaoXkXkaxt1TPYiEa6r8NY1no2sQUa1X281FhNdYFlsCjAot4OBgGKe6GHx
R/qL2ifaSReCAf8DpqDi6SMMOjg+Owrya44E0Ld/SEVHyDy8PnLTmI2ijydhptjK
slf33COCWnIE88OQutWM3/OyMkrRAgMBAAECgYEAg/2OMH8gmusiCEgATijVeGYf
i3bVwdjCwfBFXXtgCgiIkJDq/wPGmhMAUXAFNJ9EmtXIA/mo3vdIb6XdHyeyKKi9
LRly8gHlowdJ5HTbjrBCJlpPTG/Hxo1+3Q+W50240LyuZLByOy7AABr86bIq8Xxo
F4U13aHYhPkI15pvEt0CQQDuLZvZ1i7JZB/KfUhM3pgsnApFxRFcGCwOG7bVXAM5
+fkLnAENP/yWzawD/HOctDxzQ7qdcSWlx0Ux2Ww9n4nDAkEA6LMkhxcnVAM7y6aQ
u6eKcHSJxDmFbHJoxVyyVlVynL9qDgKTckZvvzLopgBo7VawsqyC0YV7XZTxgsvV
wzK72wJAJjBR6N+aqNfQ8RqdWRXnuF9clks+uVF23tw6uIMEUWtvLxlYYdN8oIFh
r1HvB5UujByz80KNEsOcqJ1/6XGHGQJBANzLXhVwOrjUeKA7Y4kq54jcivvNOHQ1
+oOJ+Q1B9oYUeaThfNYpT060F1urd+P7JZ3jYh078lpRQPdCQYn9UZECQENnF2pp
Gl92V3wIHINZYD6o97L+/6Cw3H7TvkikX3bQf1vKy4P7+rE89jEAgA0jrMWPu6WG
Vtdh93Euj6RHtUE=
-----END PRIVATE KEY-----
''';

void main() {
  group('GitHubAuthClient', () {
    test('getInstallationClient creates authenticated GitHub client instance', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          equals('https://api.github.com/app/installations/12345/access_tokens'),
        );
        expect(request.headers['Authorization'], startsWith('Bearer '));
        expect(
          request.headers['Accept'],
          equals('application/vnd.github+json'),
        );

        return http.Response(
          jsonEncode({
            'token': 'ghs_installation_token_abc',
            'expires_at': '2026-06-19T20:00:00Z',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final authClient = GitHubAuthClient(
        appId: '9876',
        privateKeyPem: testRsaPrivateKey,
        apiBaseUrl: 'https://api.github.com',
        httpClient: mockClient,
      );

      final github = await authClient.getInstallationClient(installationId: 12345);
      expect(github.auth.token, equals('ghs_installation_token_abc'));
      expect(github.endpoint, equals('https://api.github.com'));
    });

    test('throws HttpException on error response from GitHub API', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final authClient = GitHubAuthClient(
        appId: '9876',
        privateKeyPem: testRsaPrivateKey,
        apiBaseUrl: 'https://api.github.com',
        httpClient: mockClient,
      );

      expect(
        () => authClient.getInstallationClient(installationId: 12345),
        throwsA(isA<HttpException>()),
      );
    });

    test('throws FormatException if token is missing in response body', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({}), 200);
      });

      final authClient = GitHubAuthClient(
        appId: '9876',
        privateKeyPem: testRsaPrivateKey,
        apiBaseUrl: 'https://api.github.com',
        httpClient: mockClient,
      );

      expect(
        () => authClient.getInstallationClient(installationId: 12345),
        throwsFormatException,
      );
    });
  });
}
