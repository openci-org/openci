import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:genuineci_server/database.dart';
import 'package:test/test.dart';

import '../../helpers/database_failure_checks.dart';
import '../../../routes/workers/index.dart' as index_route;

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Workers Route Endpoints', () {
    group('GET /workers', () {
      test('responds with 401 Unauthorized when uid is null', () async {
        final context = TestRequestContext(
          path: '/workers',
          method: HttpMethod.get,
        );
        context.provide<AppDatabase>(db);
        context.provide<String?>(null);

        final response = await index_route.onRequest(context.context);
        expect(response.statusCode, equals(HttpStatus.unauthorized));
      });

      test(
        'responds with 200 OK and returns workers list when uid is present',
        () async {
          final now = DateTime.now().toUtc();
          await db.workerHeartbeatDao.upsertHeartbeat(
            DriftWorkerHeartbeat(
              id: 'worker-1',
              version: '1.0.0',
              platform: 'macos',
              status: 'idle',
              lastSeenAt: now,
            ),
          );

          final context = TestRequestContext(
            path: '/workers',
            method: HttpMethod.get,
          );
          context.provide<AppDatabase>(db);
          context.provide<String?>('user-123');

          final response = await index_route.onRequest(context.context);
          expect(response.statusCode, equals(HttpStatus.ok));

          final body = await response.json() as Map<String, dynamic>;
          expect(body['success'], isTrue);

          final list = body['workers'] as List<dynamic>;
          expect(list, hasLength(1));
          expect(list.first['id'], equals('worker-1'));
          expect(list.first['version'], equals('1.0.0'));
          expect(list.first['platform'], equals('macos'));
          expect(list.first['status'], equals('idle'));
        },
      );
    });
  });

  testDatabaseFailures([
    DatabaseFailureEndpoint('/workers', HttpMethod.get, index_route.onRequest),
  ]);
}
