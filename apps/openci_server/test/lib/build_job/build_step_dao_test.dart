import 'package:drift/native.dart';
import 'package:openci_server/build_job/build_step_dao.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('BuildStepDao', () {
    late AppDatabase db;
    late BuildStepDao dao;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = db.buildStepDao;
    });

    tearDown(() async {
      await db.close();
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
        await dao.upsertBuildStep(first.copyWith(id: 'second', stepOrder: 1));
        await dao.upsertBuildStep(
          first.copyWith(id: 'other-run', runId: 'run-b'),
        );
        await dao.upsertBuildStep(first);
        await dao.upsertBuildStep(
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
  });
}
