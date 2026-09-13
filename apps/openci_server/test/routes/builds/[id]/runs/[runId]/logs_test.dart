import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../../../routes/builds/[id]/runs/[runId]/logs.dart' as route;

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
    test('returns stored build step logs', () async {
      await _seedBuildJob(db);
      final now = DateTime.now().toUtc();
      await db.buildJobDao.upsertBuildStep(
        BuildStep(
          id: 'checkout',
          runId: 'run-456',
          name: 'Checkout',
          status: BuildJobStatus.SUCCESS,
          durationMs: 100,
          stepOrder: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await db.buildJobDao.insertBuildStepLog(
        'run-456_checkout',
        'line 1\nline 2\n',
      );
      await db.buildJobDao.upsertBuildStep(
        BuildStep(
          id: 'test',
          runId: 'run-456',
          name: 'Test',
          status: BuildJobStatus.SUCCESS,
          durationMs: 200,
          stepOrder: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final context = TestRequestContext(
        path: '/builds/job-xyz/runs/run-456/logs',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);

      final response = await route.onRequest(
        context.context,
        'job-xyz',
        'run-456',
      );

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        await response.json(),
        equals([
          '=== Checkout ===',
          'line 1',
          'line 2',
          '',
          '=== Test ===',
          'No logs available.',
          '',
        ]),
      );
    });

    test('returns 404 when the run is missing', () async {
      await _seedBuildJob(db, includeRun: false);
      final context = TestRequestContext(
        path: '/builds/job-xyz/runs/non-existent-run/logs',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);

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
