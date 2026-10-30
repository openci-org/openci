import 'dart:async';
import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  late List<http.Request> requests;

  setUp(() => requests = []);

  ChopperClient createClient(FutureOr<String?> Function() tokenProvider) {
    final httpClient = MockClient((request) async {
      requests.add(request);
      return http.Response(
        jsonEncode([
          {
            'id': 'device-123',
            'userId': 'user-123',
            'teamId': 'team-123',
            'udid': 'device-udid',
            'deviceProduct': 'iPhone',
            'deviceOsVersion': '26.0',
            'createdAt': '2026-01-01T00:00:00Z',
            'updatedAt': '2026-01-01T00:00:00Z',
          },
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final client = http.runWithClient(
      () => createOpenCIChopperClient(
        baseUrl: 'https://api.openci.test',
        tokenProvider: tokenProvider,
        services: [OpenCIApiService.create()],
      ),
      () => httpClient,
    );
    addTearDown(client.dispose);
    return client;
  }

  test(
    'resolves the current token for each request and decodes devices',
    () async {
      var token = 'first-token';
      var tokenReads = 0;
      final client = createClient(() async {
        tokenReads++;
        return token;
      });
      final api = client.getService<OpenCIApiService>();

      final firstResponse = await api.getDevices();
      token = 'refreshed-token';
      final secondResponse = await api.getDevices();

      expect(tokenReads, 2);
      expect(requests.map((r) => r.headers['Authorization']), [
        'Bearer first-token',
        'Bearer refreshed-token',
      ]);
      expect(requests.first.url, Uri.parse('https://api.openci.test/devices'));
      expect(firstResponse.body!.single.id, 'device-123');
      expect(secondResponse.body!.single.teamId, 'team-123');
      expect(secondResponse.body!.single.userId, 'user-123');
    },
  );

  for (final token in [null, '']) {
    test('sends no authorization header when token is $token', () async {
      final client = createClient(() => token);

      final response = await client.getService<OpenCIApiService>().getDevices();

      expect(response.isSuccessful, isTrue);
      expect(requests.single.headers, isNot(contains('Authorization')));
    });
  }

  test('waits for asynchronous token resolution before sending', () async {
    final token = Completer<String?>();
    final client = createClient(() => token.future);

    final response = client.getService<OpenCIApiService>().getDevices();
    await Future<void>.delayed(Duration.zero);
    expect(requests, isEmpty);

    token.complete('ready-token');
    await response;
    expect(requests.single.headers['Authorization'], 'Bearer ready-token');
  });

  test('replaces stale authorization while preserving other headers', () async {
    final client = createClient(() => 'current-token');

    await client.get<List<UserDevice>, UserDevice>(
      Uri.parse('/devices'),
      headers: {'Authorization': 'Bearer stale-token', 'X-Request-ID': 'req-1'},
    );

    expect(requests.single.headers['Authorization'], 'Bearer current-token');
    expect(requests.single.headers['X-Request-ID'], 'req-1');
  });

  test('propagates token failures without sending a request', () async {
    final error = StateError('Token refresh failed');
    final client = createClient(() async => throw error);

    await expectLater(
      client.getService<OpenCIApiService>().getDevices(),
      throwsA(same(error)),
    );
    expect(requests, isEmpty);
  });
}
