import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/environment_value/environment_value.dart';
import 'package:openci_server/router.dart';
import 'package:openci_server/storage.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../storage/fake_storage.dart';

void main() {
  group('SSE Log Streaming Tests', () {
    late Handler handler;
    late AppDatabase db;
    late FakeStorageManager storage;
    const localHost = "http://localhost";

    setUp(() {
      storage = FakeStorageManager();
      db = AppDatabase(NativeDatabase.memory());
      final envValue = EnvironmentValue.load(
        environment: {
          'DATABASE_URL': 'postgres://localhost:5432/test',
          'SECRET_ENCRYPTION_KEY':
              'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=',
        },
      );
      final container = ProviderContainer(
        overrides: [
          environmentValueProvider.overrideWithValue(envValue),
          databaseProvider.overrideWithValue(db),
          storageProvider.overrideWithValue(storage),
          firebaseAppProvider.overrideWithValue(null),
        ],
      );
      handler = container.read(handlerProvider);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'GET /builds/<buildJobId>/runs/<runId>/logs/stream returns SSE and streams logs',
      () async {
        final buildJobId = 'test-job-id';
        final runId = 'test-run-id';

        final now = DateTime.now().toUtc();
        await db.buildJobDao.insertBuildJob(
          DriftBuildJob(
            id: buildJobId,
            status: BuildJobStatus.IN_PROGRESS,
            owner: 'owner',
            repo: 'repo',
            workflowName: 'workflow',
            createdAt: now,
            updatedAt: now,
          ),
        );

        await db.buildJobDao.insertBuildJobLog(runId, 'log line 1\n');

        final request = Request(
          'GET',
          Uri.parse('$localHost/builds/$buildJobId/runs/$runId/logs/stream'),
        );
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        expect(response.headers['Content-Type'], equals('text/event-stream'));
        expect(response.headers['Cache-Control'], equals('no-cache'));
        expect(response.headers['Connection'], equals('keep-alive'));

        final stream = response.read();
        final linesStream = stream
            .transform(utf8.decoder)
            .transform(const LineSplitter());
        final iterator = StreamIterator(linesStream);

        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, startsWith('data: '));
        final jsonStr = iterator.current.substring(6);
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        expect(data['id'], equals(1));
        expect(data['content'], equals('log line 1\n'));

        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, isEmpty);

        await db.buildJobDao.insertBuildJobLog(runId, 'log line 2\n');

        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, startsWith('data: '));
        final jsonStr2 = iterator.current.substring(6);
        final data2 = jsonDecode(jsonStr2) as Map<String, dynamic>;
        expect(data2['id'], equals(2));
        expect(data2['content'], equals('log line 2\n'));

        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, isEmpty);

        await db.buildJobDao.updateBuildJob(
          DriftBuildJob(
            id: buildJobId,
            status: BuildJobStatus.SUCCESS,
            owner: 'owner',
            repo: 'repo',
            workflowName: 'workflow',
            createdAt: now,
            updatedAt: DateTime.now().toUtc(),
          ),
        );

        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, equals('event: done'));
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, equals('data: {}'));
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, isEmpty);

        await iterator.cancel();
      },
    );
  });
}
