import 'package:drift/drift.dart';
import 'package:openci_server/build_job/build_job.dart';
import 'package:openci_server/database.dart';

part 'build_step_log_dao.g.dart';

@DriftAccessor(tables: [BuildStepLogs])
class BuildStepLogDao extends DatabaseAccessor<AppDatabase>
    with _$BuildStepLogDaoMixin {
  BuildStepLogDao(super.attachedDatabase);

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
