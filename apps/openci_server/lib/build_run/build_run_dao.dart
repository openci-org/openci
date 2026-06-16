import 'package:drift/drift.dart';
import 'package:openci_server/build_run/build_run.dart';
import 'package:openci_server/database.dart';

part 'build_run_dao.g.dart';

@DriftAccessor(tables: [BuildRuns])
class BuildRunDao extends DatabaseAccessor<AppDatabase>
    with _$BuildRunDaoMixin {
  BuildRunDao(super.attachedDatabase);

  Future<void> insertBuildRun(DriftBuildRun run) => into(buildRuns).insert(run);

  Future<void> updateBuildRun(DriftBuildRun run) =>
      update(buildRuns).replace(run);

  Future<DriftBuildRun?> getBuildRun(String runId) =>
      (select(buildRuns)..where((t) => t.id.equals(runId))).getSingleOrNull();

  Future<List<DriftBuildRun>> getBuildRuns(String buildJobId) =>
      (select(buildRuns)
            ..where((t) => t.buildJobId.equals(buildJobId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();
}
