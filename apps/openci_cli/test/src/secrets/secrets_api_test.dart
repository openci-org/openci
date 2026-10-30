import 'dart:convert';

import 'package:genuineci_cli/src/credential_store/credential_config.dart';
import 'package:genuineci_cli/src/secrets/secrets_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  final token =
      'header.${base64Url.encode(utf8.encode(jsonEncode({'aud': 'demo-openci'}))).replaceAll('=', '')}.signature';
  test(
    'infers the project from Firebase login and preserves exact values',
    () async {
      late http.Request sent;
      final api = SecretsApi(
        AuthProfile(token: token),
        client: MockClient((request) async {
          sent = request;
          return http.Response('{"result":{"success":true}}', 200);
        }),
      );
      addTearDown(api.dispose);
      const value = '\uFEFF  private\r\n日本語\n';
      expect(
        (await api.saveSecret('team/with space', {
          'name': 'TOKEN',
          'value': value,
        })).isSuccessful,
        isTrue,
      );
      expect(
        sent.url.toString(),
        'https://asia-northeast1-demo-openci.cloudfunctions.net/teamSecrets',
      );
      expect(sent.method, 'POST');
      expect(sent.followRedirects, isFalse);
      expect(sent.headers['authorization'], 'Bearer $token');
      expect(jsonDecode(sent.body), {
        'data': {
          'action': 'save',
          'teamId': 'team/with space',
          'name': 'TOKEN',
          'value': value,
        },
      });
    },
  );
  test(
    'local Firebase authentication automatically uses the Functions emulator',
    () {
      final api = SecretsApi(
        AuthProfile(token: token, firebaseAuthEmulatorHost: '127.0.0.1:9099'),
      );
      addTearDown(api.dispose);
      expect(
        api.endpoint.toString(),
        'http://127.0.0.1:5001/demo-openci/asia-northeast1/teamSecrets',
      );
    },
  );
  test(
    'rejects non-loopback emulator destinations and non-Firebase credentials',
    () {
      for (final profile in [
        AuthProfile(token: token, functionsEmulatorHost: 'attacker.test:5001'),
        AuthProfile(
          token: token,
          functionsEmulatorHost: 'user:password@localhost:5001',
        ),
        AuthProfile(token: token, functionsEmulatorHost: 'localhost:5001/path'),
        const AuthProfile(token: 'legacy-api-key'),
      ]) {
        final api = SecretsApi(profile);
        addTearDown(api.dispose);
        expect(() => api.endpoint, throwsFormatException);
      }
    },
  );
  test(
    'reports HTTP failures without decoding or exposing response contents',
    () async {
      final api = SecretsApi(
        AuthProfile(token: token),
        client: MockClient(
          (_) async => http.Response('private diagnostic', 503),
        ),
      );
      addTearDown(api.dispose);
      final result = await api.getSecrets('team');
      expect(result.statusCode, 503);
      expect(result.body, isNull);
    },
  );
}
