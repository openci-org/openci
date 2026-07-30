import 'package:drift/drift.dart';
import 'package:openci_server/build_job/build_job.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';

part 'build_job_dao.g.dart';

@DriftAccessor(tables: [BuildJobs, BuildJobLogs, BuildSteps, BuildStepLogs])
class BuildJobDao extends DatabaseAccessor<AppDatabase>
    with _$BuildJobDaoMixin {
  BuildJobDao(super.attachedDatabase);

  Future<DriftBuildJob?> claimNextJob(
    String runsOnPattern, {
    String? vmName,
    String? workerHost,
    int? maxConcurrentJobs,
  }) async {
    return db.transaction(() async {
      if (maxConcurrentJobs != null && workerHost != null) {
        final activeJobsResult = await db
            .customSelect(
              "SELECT COUNT(*) AS active_count FROM build_jobs WHERE status = 'IN_PROGRESS' AND worker_host = \$1",
              variables: [Variable.withString(workerHost)],
            )
            .getSingle();
        final activeCount = activeJobsResult.read<int>('active_count');
        if (activeCount >= maxConcurrentJobs) {
          return null;
        }
      }

      final String runsOnCondition;
      if (runsOnPattern.toLowerCase().contains('macos')) {
        runsOnCondition = "LOWER(runs_on) LIKE '%macos%'";
      } else {
        runsOnCondition =
            "LOWER(runs_on) LIKE '%ubuntu%' OR runs_on IS NULL OR runs_on = ''";
      }

      final sql =
          '''
        SELECT * FROM build_jobs 
        WHERE status = 'QUEUED' AND ($runsOnCondition) 
        ORDER BY created_at ASC 
        LIMIT 1 
        FOR UPDATE SKIP LOCKED
      ''';

      final results = await db.customSelect(sql).get();

      if (results.isEmpty) return null;

      final row = results.first;
      final job = buildJobs.map(row.data);

      final updated = job.copyWith(
        status: BuildJobStatus.IN_PROGRESS,
        vmName: Value(vmName),
        workerHost: Value(workerHost),
        updatedAt: DateTime.now().toUtc(),
      );
      await updateBuildJob(updated);

      return updated;
    });
  }

  Future<void> insertBuildJob(DriftBuildJob job) => into(buildJobs).insert(job);

  Future<DriftBuildJob?> getLatestSuccessfulMacosJob({
    required String owner,
    required String repo,
  }) async {
    return (select(buildJobs)
          ..where((t) => t.owner.equals(owner))
          ..where((t) => t.repo.equals(repo))
          ..where((t) => t.status.equals(BuildJobStatus.SUCCESS.name))
          ..where((t) => t.runsOn.like('%macos%'))
          ..where((t) => t.branch.equals('develop'))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<DriftBuildJob>> getRecentSuccessfulMacosJobs({
    required String owner,
    required String repo,
    int limit = 10,
  }) async {
    return (select(buildJobs)
          ..where((t) => t.owner.equals(owner))
          ..where((t) => t.repo.equals(repo))
          ..where((t) => t.status.equals(BuildJobStatus.SUCCESS.name))
          ..where((t) => t.runsOn.like('%macos%'))
          ..where((t) => t.branch.equals('develop'))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
          ..limit(limit))
        .get();
  }

  Future<DriftBuildJob?> getBuildJob(String id) =>
      (select(buildJobs)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<DriftBuildJob>> getBuildJobsForTeam({
    required String teamId,
    bool? hasIpa,
    int limit = 100,
  }) {
    final query = select(buildJobs)
      ..where((t) => t.teamId.equals(teamId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);

    if (hasIpa != null) {
      query.where((t) => t.hasIpa.equals(hasIpa));
    }

    return query.get();
  }

  Stream<DriftBuildJob?> watchBuildJob(String id) =>
      (select(buildJobs)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<void> updateBuildJob(DriftBuildJob job) =>
      update(buildJobs).replace(job);

  Future<void> incrementRunCount({
    required String id,
    required String latestRunId,
    required DateTime updatedAt,
  }) async {
    final count = await (update(buildJobs)..where((t) => t.id.equals(id)))
        .write(
          BuildJobsCompanion.custom(
            runCount:
                coalesce([buildJobs.runCount, const Constant(0)]) +
                const Constant(1),
            latestRunId: Constant(latestRunId),
            updatedAt: Constant(updatedAt),
          ),
        );
    if (count != 1) {
      throw StateError(
        'Failed to increment run count for build job $id: '
        'expected 1 row to be updated, but updated $count.',
      );
    }
  }

  Future<void> insertBuildJobLog(String runId, String content) =>
      into(buildJobLogs).insert(
        BuildJobLogsCompanion.insert(
          runId: runId,
          logContent: content,
          createdAt: DateTime.now().toUtc(),
        ),
      );

  Future<List<DriftBuildJobLog>> getBuildJobLogs(String runId) =>
      (select(buildJobLogs)
            ..where((t) => t.runId.equals(runId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  Stream<List<DriftBuildJobLog>> watchBuildJobLogs(String runId) =>
      (select(buildJobLogs)
            ..where((t) => t.runId.equals(runId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch();

  Future<void> insertBuildStep(DriftBuildStep step) =>
      into(buildSteps).insertOnConflictUpdate(step);

  Future<void> updateBuildStep(DriftBuildStep step) =>
      update(buildSteps).replace(step);

  Future<List<DriftBuildStep>> getBuildSteps(String runId) =>
      (select(buildSteps)
            ..where((t) => t.runId.equals(runId))
            ..orderBy([(t) => OrderingTerm.asc(t.stepOrder)]))
          .get();

  Future<void> insertBuildStepLog(String stepId, String content) =>
      into(buildStepLogs).insert(
        BuildStepLogsCompanion.insert(
          stepId: stepId,
          logContent: content,
          createdAt: DateTime.now().toUtc(),
        ),
      );

  Future<List<DriftBuildStepLog>> getBuildStepLogs(String stepId) =>
      (select(buildStepLogs)
            ..where((t) => t.stepId.equals(stepId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();
}
