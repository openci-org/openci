import 'dart:async';

import 'package:drift/drift.dart' show Value;
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

    test('team queries apply IPA filters and limits after sorting', () async {
      for (final job in [
        _job('ipa').copyWith(hasIpa: const Value(true)),
        _job('no-ipa').copyWith(
          hasIpa: const Value(false),
          createdAt: DateTime.utc(2026, 9, 2),
        ),
        _job('unknown-ipa').copyWith(createdAt: DateTime.utc(2026, 9, 3)),
        _job('other-team').copyWith(teamId: const Value('other-team')),
      ]) {
        await dao.insertBuildJob(job);
      }

      expect(
        (await dao.getBuildJobsForTeam(teamId: 'team-a')).map((job) => job.id),
        ['unknown-ipa', 'no-ipa', 'ipa'],
      );
      expect(
        (await dao.getBuildJobsForTeam(
          teamId: 'team-a',
          limit: 1,
        )).map((job) => job.id),
        ['unknown-ipa'],
      );
      expect(
        (await dao.getBuildJobsForTeam(
          teamId: 'team-a',
          hasIpa: true,
          limit: 1,
        )).map((job) => job.id),
        ['ipa'],
      );
      expect(
        (await dao.getBuildJobsForTeam(
          teamId: 'team-a',
          hasIpa: false,
        )).map((job) => job.id),
        ['no-ipa'],
      );
      expect(await dao.getBuildJobsForTeam(teamId: 'missing'), isEmpty);
    });

    test('team watch updates the filtered and limited result', () async {
      final old = _job('old').copyWith(hasIpa: const Value(true));
      final newest = _job(
        'newest',
      ).copyWith(createdAt: DateTime.utc(2026, 9, 2));
      await dao.insertBuildJob(old);
      await dao.insertBuildJob(newest);
      await dao.insertBuildJob(
        _job('other-team').copyWith(
          teamId: const Value('other-team'),
          hasIpa: const Value(true),
          createdAt: DateTime.utc(2026, 9, 3),
        ),
      );
      final updates = StreamIterator(
        dao.watchBuildJobsForTeam(teamId: 'team-a', hasIpa: true, limit: 1),
      );
      addTearDown(updates.cancel);

      expect(await updates.moveNext(), isTrue);
      expect(updates.current.map((job) => job.id), ['old']);
      await dao.updateBuildJob(newest.copyWith(hasIpa: const Value(true)));
      expect(await updates.moveNext(), isTrue);
      expect(updates.current.map((job) => job.id), ['newest']);
      await dao.updateBuildJob(newest.copyWith(hasIpa: const Value(false)));
      expect(await updates.moveNext(), isTrue);
      expect(updates.current.map((job) => job.id), ['old']);
    });

    test('queued queries remove jobs when their status changes', () async {
      final queued = _job('queued');
      await dao.insertBuildJob(queued);
      await dao.insertBuildJob(
        _job('running').copyWith(status: BuildJobStatus.IN_PROGRESS),
      );
      await dao.insertBuildJob(
        _job('waiting').copyWith(status: BuildJobStatus.WAITING),
      );
      final updates = StreamIterator(dao.watchQueuedJobs());
      addTearDown(updates.cancel);

      expect((await dao.getQueuedJobs()).map((job) => job.id), ['queued']);
      expect(await updates.moveNext(), isTrue);
      expect(updates.current.map((job) => job.id), ['queued']);
      await dao.updateBuildJob(
        queued.copyWith(status: BuildJobStatus.IN_PROGRESS),
      );
      expect(await updates.moveNext(), isTrue);
      expect(updates.current, isEmpty);
      expect(await dao.getQueuedJobs(), isEmpty);
    });

    test('incrementRunCount starts a null count at one', () async {
      await dao.insertBuildJob(_job('first-run'));
      final updatedAt = DateTime.utc(2026, 9, 2);

      await dao.incrementRunCount(
        id: 'first-run',
        latestRunId: 'run-1',
        updatedAt: updatedAt,
      );

      final job = (await dao.getBuildJob('first-run'))!;
      expect(job.runCount, 1);
      expect(job.latestRunId, 'run-1');
      expect(job.updatedAt.toUtc(), updatedAt);
    });

    test(
      'steps are ordered within a run and upsert preserves a single row',
      () async {
        final first = BuildStep(
          id: 'first',
          runId: 'run-a',
          name: 'Checkout',
          status: BuildJobStatus.IN_PROGRESS,
          durationMs: 0,
          stepOrder: 0,
          createdAt: DateTime.utc(2026, 9, 1),
          updatedAt: DateTime.utc(2026, 9, 1),
        );
        await dao.saveStep(first.copyWith(id: 'second', stepOrder: 1));
        await dao.saveStep(first.copyWith(id: 'other-run', runId: 'run-b'));
        await dao.saveStep(first);
        await dao.saveStep(
          first.copyWith(status: BuildJobStatus.SUCCESS, durationMs: 10),
        );

        final steps = await dao.getBuildSteps('run-a');
        expect(steps.map((step) => step.id), ['first', 'second']);
        expect(steps.first.runId, first.runId);
        expect(steps.first.name, first.name);
        expect(steps.first.status, BuildJobStatus.SUCCESS);
        expect(steps.first.durationMs, 10);
        expect(steps.first.stepOrder, first.stepOrder);
        expect(steps.first.createdAt.toUtc(), first.createdAt);
        expect(steps.first.updatedAt.toUtc(), first.updatedAt);
        expect(await dao.getBuildSteps('missing'), isEmpty);
      },
    );

    test(
      'step logs preserve insertion order and stay within their step',
      () async {
        await dao.insertBuildStepLog('step-a', 'first');
        await dao.insertBuildStepLog('step-b', 'unrelated');
        await dao.insertBuildStepLog('step-a', 'second');

        expect(
          (await dao.getBuildStepLogs('step-a')).map((log) => log.logContent),
          ['first', 'second'],
        );
        expect(await dao.getBuildStepLogs('missing'), isEmpty);
      },
    );

    test('Job CRUD Operations', () async {
      final now = DateTime.now().toUtc();
      final job = DriftBuildJob(
        id: 'test-job-dao-123',
        status: BuildJobStatus.QUEUED,
        owner: 'openci-org',
        repo: 'openci',
        workflowName: 'CI',
        workflowFileName: 'ci.yml',
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
          workflowFileName: 'ci.yml',
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

DriftBuildJob _job(String id) => DriftBuildJob(
  id: id,
  teamId: 'team-a',
  status: BuildJobStatus.QUEUED,
  owner: 'openci-org',
  repo: 'openci',
  workflowName: 'CI',
  workflowFileName: 'ci.dart',
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
);
