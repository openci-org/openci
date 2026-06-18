import 'dart:async';

import 'package:drift/native.dart';
import 'package:openci_server/build_job/build_job_dao.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('BuildJobDao Tests', () {
    late AppDatabase db;
    late BuildJobDao dao;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = db.buildJobDao;
    });

    tearDown(() async {
      await db.close();
    });

    test('Job CRUD Operations', () async {
      final now = DateTime.now().toUtc();
      final job = DriftBuildJob(
        id: 'test-job-dao-123',
        status: BuildJobStatus.QUEUED,
        owner: 'openci-org',
        repo: 'openci',
        workflowName: 'CI',
        createdAt: now,
        updatedAt: now,
      );

      await dao.insertBuildJob(job);

      final retrieved = await dao.getBuildJob('test-job-dao-123');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'test-job-dao-123');
      expect(retrieved.status, BuildJobStatus.QUEUED);

      final updated = retrieved.copyWith(status: BuildJobStatus.IN_PROGRESS);
      await dao.updateBuildJob(updated);

      final retrieved2 = await dao.getBuildJob('test-job-dao-123');
      expect(retrieved2!.status, BuildJobStatus.IN_PROGRESS);
    });

    test('watchBuildJob streams updates correctly', () async {
      final now = DateTime.now().toUtc();
      final job = DriftBuildJob(
        id: 'test-job-watch',
        status: BuildJobStatus.WAITING,
        owner: 'openci-org',
        repo: 'openci',
        workflowName: 'CI',
        createdAt: now,
        updatedAt: now,
      );

      await dao.insertBuildJob(job);

      final statesFuture = dao
          .watchBuildJob('test-job-watch')
          .where((j) => j != null)
          .map((j) => j!.status)
          .take(2)
          .toList();

      final updated = job.copyWith(status: BuildJobStatus.IN_PROGRESS);
      await dao.updateBuildJob(updated);

      final states = await statesFuture;
      expect(
        states,
        equals([BuildJobStatus.WAITING, BuildJobStatus.IN_PROGRESS]),
      );
    });

    test('Log Operations and Ordering', () async {
      final runId = 'run-dao-999';

      await dao.insertBuildJobLog(runId, 'First message\n');
      await dao.insertBuildJobLog(runId, 'Second message\n');

      final logs = await dao.getBuildJobLogs(runId);
      expect(logs, hasLength(2));
      expect(logs[0].logContent, 'First message\n');
      expect(logs[1].logContent, 'Second message\n');
    });

    test('watchBuildJobLogs streams new log rows in real-time', () async {
      final runId = 'run-dao-watch';

      await dao.insertBuildJobLog(runId, 'Log 1\n');

      final logLists = <List<DriftBuildJobLog>>[];
      final subscription = dao.watchBuildJobLogs(runId).listen((list) {
        logLists.add(list);
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(logLists, hasLength(1));
      expect(logLists[0], hasLength(1));
      expect(logLists[0][0].logContent, 'Log 1\n');

      await dao.insertBuildJobLog(runId, 'Log 2\n');

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(logLists, hasLength(2));
      expect(logLists[1], hasLength(2));
      expect(logLists[1][1].logContent, 'Log 2\n');

      await subscription.cancel();
    });

    test(
      'incrementRunCount updates runCount and latestRunId successfully',
      () async {
        final nowRaw = DateTime.now().toUtc();
        final now = DateTime.utc(
          nowRaw.year,
          nowRaw.month,
          nowRaw.day,
          nowRaw.hour,
          nowRaw.minute,
          nowRaw.second,
        );
        final job = DriftBuildJob(
          id: 'test-job-increment',
          status: BuildJobStatus.QUEUED,
          owner: 'openci-org',
          repo: 'openci',
          workflowName: 'CI',
          runCount: 2,
          createdAt: now,
          updatedAt: now,
        );

        await dao.insertBuildJob(job);

        final updatedTime = now.add(const Duration(seconds: 10));
        await dao.incrementRunCount(
          id: 'test-job-increment',
          latestRunId: 'run-777',
          updatedAt: updatedTime,
        );

        final retrieved = await dao.getBuildJob('test-job-increment');
        expect(retrieved, isNotNull);
        expect(retrieved!.runCount, equals(3));
        expect(retrieved.latestRunId, equals('run-777'));
        expect(retrieved.updatedAt.toUtc(), equals(updatedTime.toUtc()));
      },
    );

    test(
      'incrementRunCount throws StateError when build job does not exist',
      () async {
        final now = DateTime.now().toUtc();
        expect(
          () => dao.incrementRunCount(
            id: 'non-existent-job',
            latestRunId: 'run-888',
            updatedAt: now,
          ),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}
