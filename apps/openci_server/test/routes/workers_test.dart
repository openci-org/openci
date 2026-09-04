import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:test/test.dart';

import '../../routes/workers/heartbeat.dart' as heartbeat_route;
import '../../routes/workers/index.dart' as index_route;

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Workers Route Endpoints', () {
    group('POST /workers/heartbeat', () {
      test('responds with 401 Unauthorized when uid is null', () async {
        final context = TestRequestContext(
          path: '/workers/heartbeat',
          method: HttpMethod.post,
          body: jsonEncode({
            'workerId': 'worker-1',
            'version': '1.0.0',
            'platform': 'macos',
            'status': 'idle',
          }),
        );
        context.provide<AppDatabase>(db);
        context.provide<String?>(null);

        final response = await heartbeat_route.onRequest(context.context);
        expect(response.statusCode, equals(HttpStatus.unauthorized));
      });

      test(
        'responds with 200 OK for any authenticated uid',
        () async {
          final context = TestRequestContext(
            path: '/workers/heartbeat',
            method: HttpMethod.post,
            body: jsonEncode({
              'workerId': 'worker-1',
              'version': '1.0.0',
              'platform': 'macos',
              'status': 'idle',
            }),
          );
          context.provide<AppDatabase>(db);
          context.provide<String?>('authenticated-user');

          final response = await heartbeat_route.onRequest(context.context);
          expect(response.statusCode, equals(HttpStatus.ok));
        },
      );

      test(
        'responds with 200 OK and stores heartbeat when worker is authorized',
        () async {
          final context = TestRequestContext(
            path: '/workers/heartbeat',
            method: HttpMethod.post,
            body: jsonEncode({
              'workerId': 'worker-1',
              'version': '1.0.0',
              'platform': 'macos',
              'status': 'idle',
            }),
          );
          context.provide<AppDatabase>(db);
          context.provide<String?>('worker-1');

          final response = await heartbeat_route.onRequest(context.context);
          expect(response.statusCode, equals(HttpStatus.ok));

          final body = await response.json() as Map<String, dynamic>;
          expect(body['success'], isTrue);
          expect(body['workerHeartbeat_upsert']['id'], equals('worker-1'));

          final list = await db.workerHeartbeatDao.getAllHeartbeats();
          expect(list, hasLength(1));
          expect(list.first.id, equals('worker-1'));
          expect(list.first.version, equals('1.0.0'));
          expect(list.first.platform, equals('macos'));
          expect(list.first.status, equals('idle'));
        },
      );
    });

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
}
