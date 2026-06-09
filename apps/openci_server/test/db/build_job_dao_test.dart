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

      final states = <BuildJobStatus>[];
      final subscription = dao.watchBuildJob('test-job-watch').listen((j) {
        if (j != null) {
          states.add(j.status);
        }
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(states, equals([BuildJobStatus.WAITING]));

      final updated = job.copyWith(status: BuildJobStatus.IN_PROGRESS);
      await dao.updateBuildJob(updated);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        states,
        equals([BuildJobStatus.WAITING, BuildJobStatus.IN_PROGRESS]),
      );

      await subscription.cancel();
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
  });
}
