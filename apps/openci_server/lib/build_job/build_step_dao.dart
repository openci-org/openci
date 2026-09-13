import 'package:drift/drift.dart';
import 'package:openci_server/build_job/build_job.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';

part 'build_step_dao.g.dart';

@DriftAccessor(tables: [BuildSteps])
class BuildStepDao extends DatabaseAccessor<AppDatabase>
    with _$BuildStepDaoMixin {
  BuildStepDao(super.attachedDatabase);

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
}
