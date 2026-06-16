import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:openci_worker_cli/cloud_function_caller.dart';
import 'package:openci_worker_cli/firebase.dart';
import 'package:test/test.dart';

class MockAuthManager implements AuthManager {
  @override
  String get apiKey => 'mock-api-key';
  @override
  String get email => 'mock-email';
  @override
  String get password => 'mock-password';

  @override
  Future<void> signIn() async {}

  @override
  Future<String> getIdToken() async {
    return 'mock-id-token';
  }
}

void main() {
  group('ApiClient Tests', () {
    late HttpServer server;
    late ApiClient apiClient;
    late String serverUrl;
    late http.Client httpClient;
    const teamId = 'test-team-id';

    setUp(() async {
      // Bind to local ephemeral port
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      serverUrl = 'http://127.0.0.1:${server.port}';

      httpClient = http.Client();
      apiClient = ApiClient(
        authManager: MockAuthManager(),
        projectId: 'test-project',
        serverUrl: serverUrl,
        client: httpClient,
      );
    });

    tearDown(() async {
      httpClient.close();
      await server.close(force: true);
    });

    test(
      'getSecrets queries team secrets endpoint and parses response',
      () async {
        // Set up mock server response
        final done = server.listen((HttpRequest request) {
          expect(request.method, equals('GET'));
          expect(request.uri.path, equals('/teams/$teamId/secrets'));
          expect(
            request.headers.value('Authorization'),
            equals('Bearer mock-id-token'),
          );
          expect(
            request.headers.value('Content-Type'),
            equals('application/json'),
          );

          final responsePayload = [
            {
              'id': '1',
              'name': 'SSH_KEY',
              'createdAt': '2026-06-16T12:00:00Z',
              'updatedAt': '2026-06-16T12:00:00Z',
            },
            {
              'id': '2',
              'name': 'API_KEY',
              'createdAt': '2026-06-16T12:00:00Z',
              'updatedAt': '2026-06-16T12:00:00Z',
            },
          ];

          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(responsePayload))
            ..close();
        });

        final result = await apiClient.getSecrets(teamId);
        expect(result.length, equals(2));
        expect(result[0]['name'], equals('SSH_KEY'));
        expect(result[1]['name'], equals('API_KEY'));

        await done.cancel();
      },
    );

    test(
      'getSecretValue queries team secret value endpoint and returns the value',
      () async {
        const secretName = 'API_KEY';
        const secretValue = 'my-decrypted-secret-token';

        final done = server.listen((HttpRequest request) {
          expect(request.method, equals('GET'));
          expect(
            request.uri.path,
            equals('/teams/$teamId/secrets/$secretName/value'),
          );
          expect(
            request.headers.value('Authorization'),
            equals('Bearer mock-id-token'),
          );

          final responsePayload = {'success': true, 'value': secretValue};

          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(responsePayload))
            ..close();
        });

        final result = await apiClient.getSecretValue(teamId, secretName);
        expect(result, equals(secretValue));

        await done.cancel();
      },
    );

    test('getSecrets handles non-200 responses appropriately', () async {
      final done = server.listen((HttpRequest request) {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..write('Forbidden')
          ..close();
      });

      await expectLater(
        apiClient.getSecrets(teamId),
        throwsA(isA<HttpException>()),
      );

      await done.cancel();
    });
  });
}
