import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/logging/loki_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../../../routes/builds/[id]/runs/[runId]/logs.dart' as route;

class FakeLokiService extends LokiService {
  FakeLokiService(this.logs);

  final List<String> logs;
  int callCount = 0;
  String? requestedRunId;

  @override
  Future<List<String>> getLogsForRun({
    required String runId,
    String? stepId,
    int limit = 5000,
  }) async {
    callCount++;
    requestedRunId = runId;
    return logs;
  }
}

Future<void> _seedBuildJob(
  AppDatabase db, {
  bool includeRun = true,
}) async {
  final now = DateTime.now().toUtc();
  await db.buildJobDao.insertBuildJob(
    DriftBuildJob(
      id: 'job-xyz',
      status: BuildJobStatus.QUEUED,
      owner: 'owner',
      repo: 'repo',
      workflowName: 'workflow',
      workflowFileName: 'ci.yml',
      createdAt: now,
      updatedAt: now,
    ),
  );

  if (includeRun) {
    await db.buildRunDao.insertBuildRun(
      DriftBuildRun(
        id: 'run-456',
        buildJobId: 'job-xyz',
        status: 'success',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('GET /builds/<id>/runs/<runId>/logs', () {
    test('returns Loki logs as JSON', () async {
      await _seedBuildJob(db);
      final lokiService = FakeLokiService(['line 1', 'line 2']);
      final context = TestRequestContext(
        path: '/builds/job-xyz/runs/run-456/logs',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);
      context.provide<LokiService>(lokiService);

      final response = await route.onRequest(
        context.context,
        'job-xyz',
        'run-456',
      );

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.headers['content-type'], contains('application/json'));
      expect(await response.json(), equals(['line 1', 'line 2']));
      expect(lokiService.callCount, equals(1));
      expect(lokiService.requestedRunId, equals('run-456'));
    });

    test('returns an empty list when Loki has no logs', () async {
      await _seedBuildJob(db);
      final context = TestRequestContext(
        path: '/builds/job-xyz/runs/run-456/logs',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);
      context.provide<LokiService>(FakeLokiService(const []));

      final response = await route.onRequest(
        context.context,
        'job-xyz',
        'run-456',
      );

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(await response.json(), equals([]));
    });

    test('returns 500 when the Loki query fails', () async {
      await _seedBuildJob(db);
      final client = MockClient((_) async => http.Response('unavailable', 503));
      addTearDown(client.close);
      final context = TestRequestContext(
        path: '/builds/job-xyz/runs/run-456/logs',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);
      context.provide<LokiService>(
        LokiService(lokiUrl: 'http://loki.test:3100', client: client),
      );

      final response = await route.onRequest(
        context.context,
        'job-xyz',
        'run-456',
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
    });

    test('returns 404 without querying Loki when the run is missing', () async {
      await _seedBuildJob(db, includeRun: false);
      final lokiService = FakeLokiService(['unexpected log']);
      final context = TestRequestContext(
        path: '/builds/job-xyz/runs/non-existent-run/logs',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);
      context.provide<LokiService>(lokiService);

      final response = await route.onRequest(
        context.context,
        'job-xyz',
        'non-existent-run',
      );

      expect(response.statusCode, equals(HttpStatus.notFound));
      expect(
        await response.json(),
        equals({'success': false, 'error': 'Build run not found'}),
      );
      expect(lokiService.callCount, isZero);
    });
  });

  group('/builds/<id>/runs/<runId>/logs unsupported methods', () {
    test('returns 405 for POST', () async {
      final context = TestRequestContext(
        path: '/builds/job-xyz/runs/run-456/logs',
        method: HttpMethod.post,
      );

      final response = await route.onRequest(
        context.context,
        'job-xyz',
        'run-456',
      );

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('returns 405 for DELETE', () async {
      final context = TestRequestContext(
        path: '/builds/job-xyz/runs/run-456/logs',
        method: HttpMethod.delete,
      );

      final response = await route.onRequest(
        context.context,
        'job-xyz',
        'run-456',
      );

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });
  });
}
