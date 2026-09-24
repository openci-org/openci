import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('groupBuildJobsToCommitGroups', () {
    test('returns no groups for an empty job list', () {
      expect(groupBuildJobsToCommitGroups([]), isEmpty);
    });

    test('supplies fallbacks for missing commit metadata', () {
      final group = groupBuildJobsToCommitGroups([_job('build')]).single;

      expect(group.commitSha, 'unknown');
      expect(group.branch, 'unknown');
      expect(group.commitMessage, 'openci-org/openci on unknown');
    });

    test('uses available metadata and sorts commits by their newest job', () {
      final groups = groupBuildJobsToCommitGroups([
        _job('old').copyWith(commitSha: 'sha-a'),
        _job('middle').copyWith(
          commitSha: 'sha-b',
          createdAt: DateTime.utc(2026, 9, 2),
        ),
        _job('new').copyWith(
          commitSha: 'sha-a',
          branch: 'develop',
          commitMessage: 'Add tests',
          workflowFileName: 'release.dart',
          createdAt: DateTime.utc(2026, 9, 3),
        ),
      ]);

      expect(groups.map((group) => group.commitSha), ['sha-a', 'sha-b']);
      expect(groups.first.createdAt, DateTime.utc(2026, 9, 3));
      expect(groups.first.branch, 'develop');
      expect(groups.first.commitMessage, 'Add tests');
      expect(
        groups.first.workflows.map((workflow) => workflow.fileName),
        ['ci.dart', 'release.dart'],
      );
    });

    for (final status in [
      BuildJobStatus.QUEUED,
      BuildJobStatus.WAITING,
      BuildJobStatus.IN_PROGRESS,
    ]) {
      test('$status keeps workflow and commit in progress', () {
        final group = groupBuildJobsToCommitGroups([
          _job('done'),
          _job('pending').copyWith(status: status),
        ]).single;

        expect(group.status, BuildJobStatus.IN_PROGRESS);
        expect(group.workflows.single.status, BuildJobStatus.IN_PROGRESS);
      });
    }

    for (final status in [
      BuildJobStatus.FAILURE,
      BuildJobStatus.CANCELLED,
      BuildJobStatus.TIMED_OUT,
    ]) {
      test('$status takes precedence over running and successful work', () {
        final group = groupBuildJobsToCommitGroups([
          _job('done'),
          _job('running').copyWith(status: BuildJobStatus.IN_PROGRESS),
          _job('failed').copyWith(status: status),
          _job('other-workflow').copyWith(workflowFileName: 'release.dart'),
        ]).single;

        expect(group.status, BuildJobStatus.FAILURE);
        expect(group.workflows.first.status, BuildJobStatus.FAILURE);
        expect(group.workflows.last.status, BuildJobStatus.SUCCESS);
      });
    }

    test('uses the longest completed job duration, not their sum', () {
      final group = groupBuildJobsToCommitGroups([
        _job('short').copyWith(completedAt: DateTime.utc(2026, 9, 1, 0, 1)),
        _job('long').copyWith(completedAt: DateTime.utc(2026, 9, 1, 0, 3)),
        _job('skipped').copyWith(status: BuildJobStatus.SKIPPED),
      ]).single;

      expect(group.status, BuildJobStatus.SUCCESS);
      expect(group.workflows.single.duration, const Duration(minutes: 3));
    });

    for (final status in [BuildJobStatus.IN_PROGRESS, BuildJobStatus.QUEUED]) {
      test('includes elapsed time for an unfinished $status job', () {
        final before = DateTime.now().toUtc();
        final createdAt = before.subtract(const Duration(minutes: 2));
        final group = groupBuildJobsToCommitGroups([
          _job('active').copyWith(status: status, createdAt: createdAt),
        ]).single;
        final after = DateTime.now().toUtc();

        expect(
          group.workflows.single.duration.inMicroseconds,
          inInclusiveRange(
            before.difference(createdAt).inMicroseconds,
            after.difference(createdAt).inMicroseconds,
          ),
        );
      });
    }
  });

  group('partitionJobsIntoStages', () {
    test('returns no stages for an empty job list', () {
      expect(partitionJobsIntoStages([]), isEmpty);
    });

    test(
      'orders dependencies regardless of input order and ignores absent jobs',
      () {
        final stages = partitionJobsIntoStages([
          _job('deploy').copyWith(needs: ['test']),
          _job('test').copyWith(needs: ['build']),
          _job('build').copyWith(needs: ['external-job']),
          _job('lint'),
        ]);

        expect(stages.map((stage) => stage.map((job) => job.id)), [
          ['build', 'lint'],
          ['test'],
          ['deploy'],
        ]);
      },
    );

    test('keeps cyclic dependencies in a final stage without losing jobs', () {
      final stages = partitionJobsIntoStages([
        _job('a').copyWith(needs: ['b'], matrixLabel: 'iOS'),
        _job('b').copyWith(needs: ['a']),
        _job('independent'),
      ]);

      expect(stages.map((stage) => stage.map((job) => job.id)), [
        ['independent'],
        ['a', 'b'],
      ]);
      expect(stages.last.map((job) => job.label), ['iOS', 'b']);
    });

    test('preserves matrix job labels and falls back to the job ID', () {
      final stages = partitionJobsIntoStages([
        _job('ios').copyWith(jobKey: 'build-ios', matrix: {'os': 'ios'}),
        _job(
          'android',
        ).copyWith(jobKey: 'build-android', matrixLabel: 'Android'),
        _job('plain').copyWith(jobKey: null),
      ]);

      expect(stages.single.map((job) => job.label), [
        'ios',
        'Android',
        'plain',
      ]);
      expect(
        stages.single.map((job) => job.status),
        everyElement(BuildJobStatus.SUCCESS),
      );
    });
  });
}

BuildJob _job(String id) => BuildJob(
  id: id,
  jobKey: id,
  status: BuildJobStatus.SUCCESS,
  owner: 'openci-org',
  repo: 'openci',
  workflowName: 'CI',
  workflowFileName: 'ci.dart',
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
);
