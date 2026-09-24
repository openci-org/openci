import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/build_job/build_job_dao.dart';
import 'package:openci_server/database.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../routes/worker/_middleware.dart' as worker;
import '../../../../routes/worker/jobs/stream.dart' as route;

class _MockDatabase extends Mock implements AppDatabase {}

class _MockBuildJobDao extends Mock implements BuildJobDao {}

class _MockBuildJob extends Mock implements DriftBuildJob {}

void main() {
  late AppDatabase db;
  late BuildJobDao dao;

  setUp(() {
    db = _MockDatabase();
    dao = _MockBuildJobDao();
    when(() => db.buildJobDao).thenReturn(dao);
  });

  Future<Uri> startServer(
    InternalApiKeyValidator validator, {
    String? uid,
  }) async {
    final handler = worker
        .middleware(route.onRequest)
        .use(provider<AppDatabase>((_) => db))
        .use(provider<String?>((_) => uid))
        .use(provider<InternalApiKeyValidator>((_) => validator));
    final server = await serve(handler, InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    return Uri(
      scheme: 'http',
      host: server.address.address,
      port: server.port,
      path: '/worker/jobs/stream',
    );
  }

  Future<void> expectUnauthorizedUpgrade(
    Uri uri, {
    Map<String, String> headers = const {},
  }) async {
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final request = await client.getUrl(uri);
    request.headers
      ..set(HttpHeaders.connectionHeader, 'Upgrade')
      ..set(HttpHeaders.upgradeHeader, 'websocket')
      ..set('Sec-WebSocket-Version', '13')
      ..set('Sec-WebSocket-Key', 'dGhlIHNhbXBsZSBub25jZQ==');
    headers.forEach((name, value) => request.headers.set(name, value));
    final response = await request.close();

    expect(response.statusCode, HttpStatus.unauthorized);
    expect(response.headers.value(HttpHeaders.upgradeHeader), isNull);
    final body = await utf8.decoder.bind(response).join();
    expect(jsonDecode(body), {
      'success': false,
      'error': 'Authentication required',
    });
    verifyZeroInteractions(db);
    verifyZeroInteractions(dao);
  }

  group('GET /worker/jobs/stream', () {
    for (final (name, token, uid) in [
      ('missing credentials', null, null),
      ('an empty token', '', null),
      ('an incorrect key', 'wrong-internal-key', 'system-job-processor'),
      ('a Firebase user token', 'firebase-id-token', 'user-1'),
      (
        'a Firebase token with the reserved UID',
        'firebase-id-token',
        'system-job-processor',
      ),
    ]) {
      test(
        'rejects $name before upgrading or accessing the database',
        () async {
          const validator = InternalApiKeyValidator.forTesting(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          );
          final uri = await startServer(validator, uid: uid);

          await expectUnauthorizedUpgrade(
            uri,
            headers: {if (token != null) 'Authorization': 'Bearer $token'},
          );
        },
      );
    }

    test('rejects requests when the internal key is not configured', () async {
      const validator = InternalApiKeyValidator.forTesting(environment: {});
      final uri = await startServer(validator);

      await expectUnauthorizedUpgrade(
        uri,
        headers: {'Authorization': 'Bearer test-internal-key'},
      );
    });

    test(
      'rejects requests when the configured internal key is empty',
      () async {
        const validator = InternalApiKeyValidator.forTesting(
          environment: {'INTERNAL_API_KEY': ''},
        );
        final uri = await startServer(validator);

        await expectUnauthorizedUpgrade(
          uri,
          headers: {'Authorization': 'Bearer '},
        );
      },
    );

    test(
      'rejects an incorrect Bearer token despite a valid query key',
      () async {
        const validator = InternalApiKeyValidator.forTesting(
          environment: {'INTERNAL_API_KEY': 'test-internal-key'},
        );
        final uri = await startServer(validator);

        await expectUnauthorizedUpgrade(
          uri.replace(queryParameters: {'token': 'test-internal-key'}),
          headers: {'Authorization': 'Bearer wrong-internal-key'},
        );
      },
    );

    for (final (name, headers, query) in [
      (
        'a Bearer header',
        {'Authorization': 'Bearer test-internal-key'},
        <String, String>{},
      ),
      ('the token query', <String, String>{}, {'token': 'test-internal-key'}),
      ('the auth query', <String, String>{}, {'auth': 'test-internal-key'}),
    ]) {
      test(
        'accepts $name and delivers job notifications without a UID',
        () async {
          const validator = InternalApiKeyValidator.forTesting(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          );
          final cancelled = Completer<void>();
          final queuedJobs = StreamController<List<DriftBuildJob>>.broadcast(
            onCancel: cancelled.complete,
          );
          addTearDown(queuedJobs.close);
          when(
            () => dao.watchQueuedJobs(),
          ).thenAnswer((_) => queuedJobs.stream);
          when(
            () => dao.getQueuedJobs(),
          ).thenAnswer((_) async => [_MockBuildJob()]);
          final uri = await startServer(validator);
          final socket = await WebSocket.connect(
            uri.replace(scheme: 'ws', queryParameters: query).toString(),
            headers: headers,
          );
          addTearDown(socket.close);
          final messages = StreamIterator(socket);
          addTearDown(messages.cancel);

          expect(
            await messages.moveNext().timeout(const Duration(seconds: 5)),
            isTrue,
          );
          _expectJobNotification(messages.current, queuedCount: 1);

          queuedJobs.add([_MockBuildJob(), _MockBuildJob()]);
          expect(
            await messages.moveNext().timeout(const Duration(seconds: 5)),
            isTrue,
          );
          _expectJobNotification(messages.current, queuedCount: 2);

          await socket.close();
          await cancelled.future.timeout(const Duration(seconds: 5));
          verify(() => dao.watchQueuedJobs()).called(1);
          verify(() => dao.getQueuedJobs()).called(1);
        },
      );
    }
  });
}

void _expectJobNotification(dynamic message, {required int queuedCount}) {
  final payload = jsonDecode(message as String) as Map<String, dynamic>;
  expect(payload.keys, unorderedEquals(['event', 'queuedCount', 'timestamp']));
  expect(payload['event'], 'job_available');
  expect(payload['queuedCount'], queuedCount);
  expect(DateTime.parse(payload['timestamp'] as String).isUtc, isTrue);
}
