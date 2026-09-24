import 'dart:async';
import 'dart:convert';

import 'package:openci_cli/src/auth/firebase_auth_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  const password = 'private-password 日本語';
  const token = 'private-id-token';
  const refreshToken = 'private-refresh-token';
  const signInBody = {
    'idToken': token,
    'refreshToken': refreshToken,
    'expiresIn': '3600',
  };

  test('signs in directly with Firebase and parses the session', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(
        request.url,
        Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=test-key',
        ),
      );
      expect(request.followRedirects, isFalse);
      expect(request.headers['content-type'], contains('application/json'));
      expect(jsonDecode(utf8.decode(request.bodyBytes)), {
        'email': 'user@example.com',
        'password': password,
        'returnSecureToken': true,
      });
      return http.Response(jsonEncode(signInBody), 200);
    });
    addTearDown(client.close);
    final before = DateTime.now().toUtc();

    final session = await FirebaseAuthClient(
      client,
    ).signIn(apiKey: 'test-key', email: 'user@example.com', password: password);

    expect(session.token, token);
    expect(session.refreshToken, refreshToken);
    expect(session.expiresAt.isUtc, isTrue);
    expect(
      session.expiresAt.difference(before).inSeconds,
      inInclusiveRange(3600, 3601),
    );
    expect(session.toString(), isNot(contains(token)));
    expect(session.toString(), isNot(contains(refreshToken)));
  });

  test(
    'refreshes tokens using form encoding and accepts a rotated token',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url,
          Uri.parse('https://securetoken.googleapis.com/v1/token?key=test-key'),
        );
        expect(request.followRedirects, isFalse);
        expect(
          request.headers['content-type'],
          contains('application/x-www-form-urlencoded'),
        );
        expect(request.bodyFields, {
          'grant_type': 'refresh_token',
          'refresh_token': 'refresh+token/&=',
        });
        return http.Response(
          jsonEncode({
            'id_token': token,
            'refresh_token': 'rotated-refresh-token',
            'expires_in': '3600',
          }),
          200,
        );
      });
      addTearDown(client.close);

      final session = await FirebaseAuthClient(
        client,
      ).refresh(apiKey: 'test-key', refreshToken: 'refresh+token/&=');

      expect(session.token, token);
      expect(session.refreshToken, 'rotated-refresh-token');
    },
  );

  for (final body in [
    password,
    'null',
    '[]',
    jsonEncode({...signInBody, 'idToken': ''}),
    jsonEncode({...signInBody, 'refreshToken': null}),
    jsonEncode({...signInBody, 'expiresIn': '0'}),
    jsonEncode({...signInBody, 'expiresIn': '-1'}),
    jsonEncode({...signInBody, 'expiresIn': 'invalid'}),
  ]) {
    test('rejects malformed session data: $body', () async {
      final client = MockClient((_) async => http.Response(body, 200));
      addTearDown(client.close);

      await expectLater(
        FirebaseAuthClient(
          client,
        ).signIn(apiKey: 'key', email: 'user@example.com', password: password),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  }

  for (final (label, respond) in <(String, Future<http.Response> Function())>[
    ('invalid credentials', () async => http.Response(password, 400)),
    (
      'redirect',
      () async => http.Response(
        password,
        302,
        headers: {'location': 'https://other.example.com'},
      ),
    ),
    ('network error', () async => throw http.ClientException(password)),
    ('timeout', () => Completer<http.Response>().future),
  ]) {
    test('does not disclose credentials on $label', () async {
      final client = MockClient((_) => respond());
      addTearDown(client.close);

      await expectLater(
        FirebaseAuthClient(
          client,
          timeout: const Duration(milliseconds: 20),
        ).signIn(apiKey: 'key', email: 'user@example.com', password: password),
        throwsA(
          isA<FirebaseAuthException>().having(
            (error) => error.toString(),
            'message',
            isNot(contains(password)),
          ),
        ),
      );
    });
  }
}
