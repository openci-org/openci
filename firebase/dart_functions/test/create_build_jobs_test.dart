import 'dart:convert';

import 'package:openci_dart_functions/src/create_build_jobs.dart';
import 'package:openci_dart_functions/src/data_connect.dart';
import 'package:openci_dart_functions/src/planning_event.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

class _Store implements PlanningStore {
  String status = 'pending';
  bool loseResponse = false;
  bool failCommit = false;
  final List<BuildJobPlan> published = [];
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
  Future<void> complete(
    String id,
    PlanningEvent? event,
    PlanningConnection? connection,
    List<BuildJobPlan> jobs,
  ) async {
    if (failCommit) throw StateError('Database unavailable');
    published.addAll(jobs);
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
