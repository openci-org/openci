import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  group('SeedDao.ensureTestTeam', () {
    test('creates the default team without a member', () async {
      await db.seedDao.ensureTestTeam();

      final team = (await db.teamDao.getTeam('test-team'))!;
      expect(team.name, 'Test Team');
      expect(team.installationIds, [12345678]);
      expect(team.aiEnabled, isTrue);
      expect(team.runNumber, 1);
      expect(team.createdAt, team.updatedAt);
      expect(await db.teamDao.getTeamMembers(team.id), isEmpty);
    });

    test('repeated seeding preserves team settings and membership', () async {
      await db.seedDao.ensureTestTeam(
        teamId: 'team-a',
        name: 'Custom team',
        installationId: 42,
        userId: 'user-a',
      );
      final original = (await db.teamDao.getTeam('team-a'))!.copyWith(
        aiEnabled: false,
        runNumber: 9,
      );
      await db.teamDao.updateTeam(original);

      await db.seedDao.ensureTestTeam(
        teamId: 'team-a',
        name: 'Replacement name',
        installationId: 42,
        userId: 'user-a',
      );

      expect((await db.teamDao.getTeam('team-a'))!.toJson(), original.toJson());
      final members = await db.teamDao.getTeamMembers('team-a');
      expect(members.map((member) => member.userId), ['user-a']);
    });

    test('adds installations and members only to the requested team', () async {
      await db.seedDao.ensureTestTeam(
        teamId: 'team-a',
        installationId: 1,
        userId: 'user-a',
      );
      await db.seedDao.ensureTestTeam(
        teamId: 'team-b',
        installationId: 2,
        userId: 'user-b',
      );

      await db.seedDao.ensureTestTeam(
        teamId: 'team-a',
        installationId: 3,
        userId: 'user-b',
      );
      await db.seedDao.ensureTestTeam(teamId: 'team-a', installationId: 3);

      expect((await db.teamDao.getTeam('team-a'))!.installationIds, [1, 3]);
      expect((await db.teamDao.getTeam('team-b'))!.installationIds, [2]);
      expect(
        (await db.teamDao.getTeamMembers('team-a')).map((m) => m.userId),
        unorderedEquals(['user-a', 'user-b']),
      );
      expect(
        (await db.teamDao.getTeamMembers('team-b')).map((m) => m.userId),
        ['user-b'],
      );
    });

    test('does not create a member for an empty user ID', () async {
      await db.seedDao.ensureTestTeam(userId: '');

      expect(await db.teamDao.getTeam('test-team'), isNotNull);
      expect(await db.teamDao.getTeamMembers('test-team'), isEmpty);
    });
  });

  group('SeedDao.createTestBuildJob', () {
    test('persists distinct queued jobs with the local defaults', () async {
      final first = await db.seedDao.createTestBuildJob();
      final second = await db.seedDao.createTestBuildJob();

      expect(first.id, startsWith('test-job-'));
      expect(second.id, isNot(first.id));
      final jobs = await db.buildJobDao.getQueuedJobs();
      expect(jobs.map((job) => job.id), unorderedEquals([first.id, second.id]));
      for (final job in jobs) {
        expect(job.status, BuildJobStatus.QUEUED);
        expect(job.owner, 'openci-org');
        expect(job.repo, 'openci');
        expect(job.workflowName, 'Test Workflow');
        expect(job.workflowFileName, 'ci.yml');
        expect(job.teamId, 'test-team');
        expect(job.installationId, '12345678');
        expect(job.commitSha, 'main');
        expect(job.commitMessage, 'feat: Test build job created by seed');
        expect(job.branch, 'main');
        expect(job.runsOn, 'macos-latest');
        expect(job.createdAt, job.updatedAt);
      }
    });

    test(
      'persists explicitly supplied workflow and repository values',
      () async {
        final created = await db.seedDao.createTestBuildJob(
          runsOn: 'ubuntu-latest',
          owner: 'example',
          repo: 'mobile',
          workflowName: 'Release',
          workflowFileName: 'release.dart',
          teamId: 'team-custom',
          installationId: '98765',
          commitSha: 'abc123',
          commitMessage: 'Release app',
          branch: 'release/v2',
        );

        final job = (await db.buildJobDao.getBuildJob(created.id))!;
        expect(job.status, BuildJobStatus.QUEUED);
        expect(job.owner, 'example');
        expect(job.repo, 'mobile');
        expect(job.workflowName, 'Release');
        expect(job.workflowFileName, 'release.dart');
        expect(job.teamId, 'team-custom');
        expect(job.installationId, '98765');
        expect(job.commitSha, 'abc123');
        expect(job.commitMessage, 'Release app');
        expect(job.branch, 'release/v2');
        expect(job.runsOn, 'ubuntu-latest');
      },
    );
  });
}
