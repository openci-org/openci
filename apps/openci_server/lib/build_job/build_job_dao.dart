import 'package:drift/drift.dart';
import 'package:openci_server/build_job/build_job.dart';
import 'package:openci_server/database.dart';

part 'build_job_dao.g.dart';

@DriftAccessor(tables: [BuildJobs, BuildJobLogs])
class BuildJobDao extends DatabaseAccessor<AppDatabase>
    with _$BuildJobDaoMixin {
  BuildJobDao(super.attachedDatabase);

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
}
