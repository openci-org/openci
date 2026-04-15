import 'dart:convert';

import 'package:dart_functions/github/installation_token.dart';
import 'package:test/test.dart';

const _testPrivateKey = '''
-----BEGIN RSA PRIVATE KEY-----
MIIEpgIBAAKCAQEA4I6iH+IeXEMbwtnE7POvTZZo8d2kukYgRyYgIalAUb02XsRb
t87R/rV+9i1wt86p6VvSTcXhlrCHNiOmtmxfH8ZYYl0rIJB8+vGNAjvqaYZFc4x3
02sf8cJaqZe8cC2vWuHKl9n4Pi2xRJ+tSNrkFOrrYi40NCJa/gAqjyD//vWtVtAx
hxhoBwkWJcXIWIq7HFqEP3TPYEFsD6zMOYl5OWAJT5DTEvoyjYx9xvTfTbJCn01G
i4MnbwiSQz0Cc3ACzMPr8JYpP0OxDtKPTbURQgRByCjNCWsFkSGAASgJDNFoRuue
hCDrHuZI2jJY/EzpqQryJiYvCb0yJ+L0I3PL9wIDAQABAoIBAQCDJytPndyHnHZp
XpFip4z6rt+KbB6a4PxXMdBQeK7lTrKjtOGwwC3sKwsFM1MDN8QLVKLG4803GtFN
8JKdNzxzrX/Pq4TV1y33zv7BkEb/7PlBXIhbxdR5ej9DkCjyB+zEEt4lxJv1jPBd
GTm3NIlEIlTqGfxJestUULqKsAZ0XOb+obDT7R+c//L0x3nShRIUmkTlpNfbulhq
nBddOGEK85RMrmPvWBlYeL6sHa5zQ2kitLF0MrFTyz66CNv+QN9VG+d7KkNgyI72
S5X1qx7jlRvFtIvPC+tCduychP/oUJnVbqcDaPayPFO4zyf5MVqpqfFWtZMtZdlL
wSx0mt2RAoGBAPYXs2djxL4UprkGGy/fJh+bdxujiKOKJD5pWkJLPXSlqKcxo2tI
bOfJpB0GurP5nhDKm09eP3din3D6mC9Pt8X/ZzfQRtQsAheOYM9p6ij2+lNCEVWf
L8xEDAqWsO+9UtiQupJ141kwfKvDcDz5azFCpJUViOiG0S74PiZDa2EPAoGBAOmY
+3/58PUZnODOq7VfmrygBN9bT4awtMUDzGcTvspZKiYyUkjSCSF7iQnLFGJrKRDF
VXK4TVd+sxjIBXKJOBHZ9f2dTiiE074lkdE3ilLPQyjKq1EOB/pG1EhgFMtir5Bj
D+QpJ03/wS5acUkKMkCoBPOVKorBwaAZGFbsGJaZAoGBALzIk7z1oUD8EKYRlBuW
QOWwWp/eRPzIBWPHaBFBLOTmDEouXyH2zmzFl9sYhXN5QxO4iYpKT7+i7ZM6+jIZ
Im6GrkT3xs4O8I/njkavBo3kYUYrgabAVmeJr/8TeKqA/yPZavbd7slF0+3kIJ71
65A/gohHm95dRe2VTAAIakBrAoGBALgXmByDHSILzVZdiXSmo4uDkFN14naDS/L3
y15wcSuGmXEAt1gsLoX0lUrigG4PhY1x9qUyGcGaWApvl9tryIRJAVOdZLsJ8tUn
RoNbAefA72x2TAzUwfS7XRCsp7ahTzq61ws4Y4FUzSl6nUyyfGf4Ae7031H64F0L
aeMWrUoBAoGBAON48n/1X/GuwhdEfQ0/JdCDOgpyVNNZkV6UeJyd/zAaTyN7W7lK
7IRzsvY/I4JPJMSVq0uXWtY4A6DUkXqtXZd0ElIfv/a4CVfBxNKapY7HJHZ+iGLo
N/47XpIcPVhKyHGBX78RWaaUvs0F9L6jVX6abgTvAtjkElAiYwyK1atQ
-----END RSA PRIVATE KEY-----''';

void main() {
  group('createGitHubAppJwt', () {
    test('returns a valid JWT with 3 parts', () {
      final token = createGitHubAppJwt(
        appId: '12345',
        privateKey: _testPrivateKey,
      );

      final parts = token.split('.');
      expect(parts.length, 3);
    });

    test('payload contains correct iss (appId)', () {
      final token = createGitHubAppJwt(
        appId: '12345',
        privateKey: _testPrivateKey,
      );

      final payload = _decodePayload(token);
      expect(payload['iss'], '12345');
    });

    test('iat is approximately 60 seconds in the past', () {
      final before = DateTime.now().toUtc();
      final token = createGitHubAppJwt(
        appId: '12345',
        privateKey: _testPrivateKey,
      );

      final payload = _decodePayload(token);
      final iat = payload['iat'] as int;
      final expectedIat =
          before.subtract(const Duration(seconds: 60)).millisecondsSinceEpoch ~/
              1000;

      // Allow 2 second tolerance
      expect(iat, closeTo(expectedIat, 2));
    });

    test('exp is approximately 10 minutes in the future', () {
      final before = DateTime.now().toUtc();
      final token = createGitHubAppJwt(
        appId: '12345',
        privateKey: _testPrivateKey,
      );

      final payload = _decodePayload(token);
      final exp = payload['exp'] as int;
      final expectedExp =
          before.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/
              1000;

      expect(exp, closeTo(expectedExp, 2));
    });

    test('uses RS256 algorithm', () {
      final token = createGitHubAppJwt(
        appId: '12345',
        privateKey: _testPrivateKey,
      );

      final header = _decodeHeader(token);
      expect(header['alg'], 'RS256');
    });

    test('different appIds produce different tokens', () {
      final token1 = createGitHubAppJwt(
        appId: '11111',
        privateKey: _testPrivateKey,
      );
      final token2 = createGitHubAppJwt(
        appId: '22222',
        privateKey: _testPrivateKey,
      );

      expect(token1, isNot(token2));
    });
  });

  group('createGitHubDio', () {
    test('configures baseUrl correctly', () {
      final dio = createGitHubDio('fake-token');
      expect(dio.options.baseUrl, 'https://api.github.com');
    });

    test('configures required GitHub headers', () {
      final dio = createGitHubDio('fake-token');
      final headers = dio.options.headers;

      expect(headers['Authorization'], 'Bearer fake-token');
      expect(headers['Accept'], 'application/vnd.github+json');
      expect(headers['X-GitHub-Api-Version'], '2022-11-28');
    });
  });
}

Map<String, dynamic> _decodePayload(String token) {
  final parts = token.split('.');
  final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
  return jsonDecode(payload) as Map<String, dynamic>;
}

Map<String, dynamic> _decodeHeader(String token) {
  final parts = token.split('.');
  final header = utf8.decode(base64Url.decode(base64Url.normalize(parts[0])));
  return jsonDecode(header) as Map<String, dynamic>;
}
