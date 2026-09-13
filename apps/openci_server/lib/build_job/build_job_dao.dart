import 'package:drift/drift.dart';
import 'package:openci_server/build_job/build_job.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';

part 'build_job_dao.g.dart';

@DriftAccessor(tables: [BuildJobs, BuildSteps, BuildStepLogs])
class BuildJobDao extends DatabaseAccessor<AppDatabase>
    with _$BuildJobDaoMixin {
  BuildJobDao(super.attachedDatabase);

  Future<DriftBuildJob?> claimNextJob({
    String? vmName,
    String? workerHost,
    int? maxConcurrentJobs,
  }) async {
    return db.transaction(() async {
      if (maxConcurrentJobs != null && workerHost != null) {
        // Serialize the count and claim for this host across server instances.
        await db
            .customSelect(
              r"SELECT pg_advisory_xact_lock(hashtext('build_job_claim'), hashtext($1))",
              variables: [Variable.withString(workerHost)],
            )
            .get();

        final countExpr = buildJobs.id.count();
        final activeCount =
            await (selectOnly(buildJobs)
                  ..addColumns([countExpr])
                  ..where(
                    buildJobs.status.equalsValue(BuildJobStatus.IN_PROGRESS) &
                        buildJobs.workerHost.equals(workerHost),
                  ))
                .map((row) => row.read(countExpr) ?? 0)
                .getSingle();

        if (activeCount >= maxConcurrentJobs) {
          return null;
        }
      }

      final sql = '''
        SELECT * FROM build_jobs 
        WHERE status = 'QUEUED' 
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

  Stream<List<DriftBuildJob>> watchBuildJobsForTeam({
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

    return query.watch();
  }

  Stream<List<DriftBuildJob>> watchQueuedJobs() {
    final query = select(buildJobs)
      ..where((t) => t.status.equalsValue(BuildJobStatus.QUEUED));
    return query.watch();
  }

  Future<List<DriftBuildJob>> getQueuedJobs() {
    final query = select(buildJobs)
      ..where((t) => t.status.equalsValue(BuildJobStatus.QUEUED));
    return query.get();
  }

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

  Future<void> upsertBuildStep(BuildStep step) =>
      into(buildSteps).insertOnConflictUpdate(
        DriftBuildStep(
          id: step.id,
          runId: step.runId,
          name: step.name,
          status: step.status,
          durationMs: step.durationMs,
          stepOrder: step.stepOrder,
          createdAt: step.createdAt,
          updatedAt: step.updatedAt,
        ),
      );

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
