import 'dart:convert';

import 'package:openci_dart_functions/src/create_build_jobs.dart';
import 'package:openci_dart_functions/src/data_connect.dart';
import 'package:openci_dart_functions/src/planning_event.dart';
import 'package:openci_dart_functions/src/plan_jobs.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

class _Store implements PlanningStore {
  String status = 'pending';
  bool loseResponse = false;
  bool failCommit = false;
  final List<BuildJobPlan> published = [];
  final List<SkippedWorkflow> skipped = [];
  String? reason;
  @override
  Future<PlanningTask?> getTask(String id) async => PlanningTask(
    id,
    'push',
    jsonEncode({
      'installation': {'id': 30},
      'repository': {
        'id': 10,
        'name': 'app',
        'owner': {'id': 20, 'login': 'org'},
      },
      'after': 'a' * 40,
      'ref': 'refs/heads/develop',
    }),
    status,
  );
  @override
  Future<PlanningConnection?> findConnection(int id) async =>
      const PlanningConnection('connection', '20', 'team');
  @override
  Future<PlanningFence> beginPullRequestPlanning(
    String taskId,
    PlanningEvent event,
    PlanningConnection connection,
  ) async => const PlanningFence('planning', 'token');
  @override
  Future<void> complete(
    String id,
    PlanningEvent? event,
    PlanningConnection? connection,
    WorkflowPlan plan, {
    PlanningFence? fence,
  }) async {
    if (failCommit) throw StateError('Database unavailable');
    published.addAll(plan.jobs);
    skipped.addAll(plan.skipped);
    reason = plan.pathFilterReason;
    status = 'completed';
    if (loseResponse) throw StateError('Response lost after commit');
  }

  @override
  Future<void> reject(String id, String reason) async {
    status = 'failed';
  }
}

void main() {
  test(
    'fetches paths once per task and persists skipped results on redelivery',
    () async {
      final store = _Store()..loseResponse = true;
      var comparisons = 0;
      final planner = BuildJobPlanner(
        store: store,
        fetchWorkflows: (_) async => [
          for (final name in ['one', 'two'])
            OpenCIFile(
              name: '$name.dart',
              path: 'openci/$name.dart',
              content:
                  "void main() { OpenCI.init(workflowName: '$name', ciTriggers: [CITrigger.push(branch: '*', paths: ['apps/**'])]); }",
            ),
        ],
        fetchChangedFiles: (_) async {
          comparisons++;
          return ChangedFilesResult(
            paths: ['README.md'],
            isComplete: true,
            headSha: 'a' * 40,
            baseSha: 'b' * 40,
          );
        },
      );
      expect(await planner.process('task'), 'duplicate');
      expect(await planner.process('task'), 'duplicate');
      expect(store.published, isEmpty);
      expect(store.skipped, hasLength(2));
      expect(comparisons, 1);
    },
  );
  test(
    'does not fetch changed paths for unfiltered or unmatched workflows',
    () async {
      for (final branch in ['develop', 'release']) {
        final store = _Store();
        final planner = BuildJobPlanner(
          store: store,
          fetchWorkflows: (_) async => [
            OpenCIFile(
              name: 'ci.dart',
              path: 'openci/ci.dart',
              content:
                  "void main() { OpenCI.init(workflowName: 'CI', ciTriggers: [CITrigger.push(branch: '$branch')]); }",
            ),
          ],
          fetchChangedFiles: (_) async =>
              throw StateError('Unexpected comparison'),
        );
        expect(await planner.process('task'), 'created');
      }
    },
  );
  test(
    'reconciles a committed transaction with a lost response and does not replan on redelivery',
    () async {
      final store = _Store()..loseResponse = true;
      var fetches = 0;
      final planner = BuildJobPlanner(
        store: store,
        fetchWorkflows: (_) async {
          fetches++;
          return [
            const OpenCIFile(
              name: 'ci.dart',
              path: 'openci/ci.dart',
              content:
                  "void main() { OpenCI.init(workflowName: 'CI', ciTriggers: [CITrigger.push(branch: '*')]); }",
            ),
          ];
        },
      );
      expect(await planner.process('task'), 'duplicate');
      expect(await planner.process('task'), 'duplicate');
      expect(store.published, hasLength(1));
      expect(fetches, 1);
    },
  );
  test('a failed transaction remains pending and can be retried', () async {
    final store = _Store()..failCommit = true;
    final planner = BuildJobPlanner(
      store: store,
      fetchWorkflows: (_) async => [],
    );
    await expectLater(planner.process('task'), throwsStateError);
    expect(store.status, 'pending');
    store.failCommit = false;
    expect(await planner.process('task'), 'created');
    expect(store.status, 'completed');
  });
}
