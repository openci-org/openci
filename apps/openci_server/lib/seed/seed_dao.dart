import 'package:drift/drift.dart';
import 'package:openci_server/build_job/build_job.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/team/team_table.dart';
import 'package:openci_shared/openci_shared.dart';

part 'seed_dao.g.dart';

@DriftAccessor(tables: [Teams, BuildJobs])
class SeedDao extends DatabaseAccessor<AppDatabase> with _$SeedDaoMixin {
  SeedDao(super.attachedDatabase);

  Future<void> ensureTestTeam({
    String teamId = 'test-team',
    String name = 'Test Team',
    int installationId = 12345678,
  }) async {
    final existing = await (select(
      teams,
    )..where((t) => t.id.equals(teamId))).getSingleOrNull();
    final now = DateTime.now().toUtc();

    if (existing != null) {
      if (!existing.installationIds.contains(installationId)) {
        final newInstallationIds = [
          ...existing.installationIds,
          installationId,
        ];
        await (update(teams)..where((t) => t.id.equals(teamId))).write(
          TeamsCompanion(
            installationIds: Value(newInstallationIds),
            updatedAt: Value(now),
          ),
        );
      }
      return;
    }

    try {
      await into(teams).insert(
        DriftTeam(
          id: teamId,
          name: name,
          installationIds: [installationId],
          aiEnabled: true,
          runNumber: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } catch (_) {
      // Ignore duplicate key errors if created concurrently or already exists
    }
  }

  Future<DriftBuildJob> createTestBuildJob({
    String runsOn = 'macos-latest',
    String owner = 'openci-org',
    String repo = 'openci',
    String workflowName = 'Test Workflow',
    String workflowFileName = 'ci.yml',
    String teamId = 'test-team',
    String installationId = '12345678',
    String commitSha = 'main',
    String commitMessage = 'feat: Test build job created by seed',
    String branch = 'main',
    String? customScript,
  }) async {
    await ensureTestTeam();
    final now = DateTime.now().toUtc();
    final id = 'test-job-${now.millisecondsSinceEpoch}';

    final job = DriftBuildJob(
      id: id,
      status: BuildJobStatus.QUEUED,
      owner: owner,
      repo: repo,
      workflowName: workflowName,
      workflowFileName: workflowFileName,
      teamId: teamId,
      installationId: installationId,
      commitSha: commitSha,
      commitMessage: commitMessage,
      branch: branch,
      runsOn: runsOn,
      customScript: customScript,
      createdAt: now,
      updatedAt: now,
    );

    await into(buildJobs).insert(job);
    return job;
  }
}
