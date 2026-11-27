import 'dart:convert';

import 'package:openci_dart_functions/src/create_build_jobs.dart';
import 'package:openci_dart_functions/src/data_connect.dart';
import 'package:openci_dart_functions/src/github_workflows.dart';
import 'package:openci_dart_functions/src/planning_event.dart';
import 'package:openci_dart_functions/src/plan_jobs.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

class _Store implements PlanningStore {
  String status = 'pending';
  bool loseResponse = false;
  bool failCommit = false;
  bool pullRequest = false;
  bool release = false;
  bool connected = true;
  int conflictsRemaining = 0;
  final List<PlanningFence> fences = [];
  final List<BuildJobPlan> published = [];
  final List<SkippedWorkflow> skipped = [];
  String? reason;
  @override
  Future<PlanningTask?> getTask(String id) async => PlanningTask(
    id,
    release ? 'release' : (pullRequest ? 'pull_request' : 'push'),
    jsonEncode({
      'installation': {'id': 30},
      'repository': {
        'id': 10,
        'name': 'app',
        'owner': {'id': 20, 'login': 'org'},
      },
      'after': 'a' * 40,
      'ref': 'refs/heads/develop',
      if (release) ...{
        'action': 'published',
        'release': {
          'id': 40,
          'tag_name': 'v1.2.0',
          'draft': false,
          'target_commitish': 'develop',
        },
      },
      if (pullRequest) ...{
        'action': 'synchronize',
        'number': 7,
        'pull_request': {
          'title': 'PR',
          'head': {
            'sha': 'a' * 40,
            'ref': 'feature',
            'repo': {'id': 10},
          },
          'base': {
            'sha': 'b' * 40,
            'ref': 'develop',
            'repo': {'id': 10},
          },
        },
      },
    }),
    status,
  );
  @override
  Future<PlanningConnection?> findConnection(int id, int repositoryId) async =>
      connected ? const PlanningConnection('connection', '20', 'team') : null;
  @override
  Future<PlanningFence> beginPullRequestPlanning(
    String taskId,
    PlanningEvent event,
    PlanningConnection connection,
  ) async {
    final fence = PlanningFence('planning', 'token-${fences.length}');
    fences.add(fence);
    return fence;
  }

  @override
  Future<void> complete(
    String id,
    PlanningEvent? event,
    PlanningConnection? connection,
    WorkflowPlan plan, {
    PlanningFence? fence,
  }) async {
    if (failCommit) throw StateError('Database unavailable');
    if (conflictsRemaining > 0) {
      conflictsRemaining--;
      throw const PlanningObservationSuperseded();
    }
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
    'release publication resolves its tag before reading and planning CD',
    () async {
      final store = _Store()..release = true;
      final sha = 'c' * 40;
      var resolutions = 0;
      final planner = BuildJobPlanner(
        store: store,
        resolveReleaseCommit: (event) async {
          resolutions++;
          expect(event.webhook.commitSha, isEmpty);
          return sha;
        },
        fetchWorkflows: (event) async {
          expect(event.webhook.commitSha, sha);
          return [
            for (final (name, trigger) in [
              ('cd', "CITrigger.release(tag: 'v*')"),
              ('patch', "CITrigger.push(branch: 'develop')"),
              ('tag', "CITrigger.push(branch: 'refs/tags/*')"),
            ])
              OpenCIFile(
                name: '$name.dart',
                path: 'openci/$name.dart',
                content:
                    "void main() { OpenCI.init(workflowName: '$name', ciTriggers: [$trigger]); }",
              ),
          ];
        },
        fetchChangedFiles: (_) async =>
            throw StateError('No release path comparison'),
        observePullRequest: (_) async => throw StateError('Not a PR'),
      );
      expect(await planner.process('release-task'), 'created');
      expect(await planner.process('release-task'), 'duplicate');
      expect(resolutions, 1);
      expect(store.published, hasLength(1));
      expect(store.published.single.workflowFileName, 'cd.dart');
      expect(store.published.single.commitSha, sha);
      expect(store.published.single.branch, 'refs/tags/v1.2.0');
      expect(store.published.single.pullRequestNumber, isNull);
      expect(store.fences, isEmpty);
    },
  );

  test(
    'release tag outages leave the task pending without fetching code',
    () async {
      final store = _Store()..release = true;
      for (final resolve in <Future<String> Function(PlanningEvent)?>[
        null,
        (_) async => throw StateError('GitHub unavailable'),
      ]) {
        final planner = BuildJobPlanner(
          store: store,
          resolveReleaseCommit: resolve,
          fetchWorkflows: (_) async => throw StateError('Must not fetch'),
        );
        await expectLater(planner.process('release-task'), throwsStateError);
        expect(store.status, 'pending');
        expect(store.published, isEmpty);
      }
    },
  );

  test(
    'unconnected release events never resolve tags or fetch source',
    () async {
      final store = _Store()
        ..release = true
        ..connected = false;
      final planner = BuildJobPlanner(
        store: store,
        resolveReleaseCommit: (_) async => throw StateError('Must not resolve'),
        fetchWorkflows: (_) async => throw StateError('Must not fetch'),
      );
      expect(await planner.process('release-task'), 'created');
      expect(store.published, isEmpty);
    },
  );
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

  group('pathsIgnore', () {
    for (final pullRequest in [false, true]) {
      final trigger = pullRequest ? 'pullRequest' : 'push';
      for (final (description, paths, isComplete, shouldRun) in [
        ('skips excluded changes', ['docs/guide.md', 'README.md'], true, false),
        (
          'runs for mixed changes',
          ['docs/guide.md', 'lib/app.dart'],
          true,
          true,
        ),
        ('skips an empty diff', <String>[], true, false),
        ('runs for an incomplete diff', <String>[], false, true),
      ]) {
        test('$trigger $description', () async {
          final store = _Store()..pullRequest = pullRequest;
          var comparisons = 0;
          final planner = BuildJobPlanner(
            store: store,
            fetchWorkflows: (_) async => [
              OpenCIFile(
                name: 'ci.dart',
                path: 'openci/ci.dart',
                content:
                    '''
void main() {
  OpenCI.init(workflowName: 'CI', ciTriggers: [
    CITrigger.$trigger(branch: 'develop', pathsIgnore: ['docs/**', 'README.md']),
  ]);
}
''',
              ),
            ],
            fetchChangedFiles: (_) async {
              comparisons++;
              return ChangedFilesResult(
                paths: paths,
                isComplete: isComplete,
                headSha: 'a' * 40,
                baseSha: 'b' * 40,
              );
            },
            observePullRequest: (_) async => PullRequestObservation.current,
          );

          expect(await planner.process('task'), 'created');
          expect(comparisons, 1);
          expect(store.published, hasLength(shouldRun ? 1 : 0));
          expect(store.skipped, hasLength(shouldRun ? 0 : 1));
        });
      }
    }
  });

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
    var fetches = 0;
    final planner = BuildJobPlanner(
      store: store,
      fetchWorkflows: (_) async {
        fetches++;
        return [];
      },
    );
    await expectLater(planner.process('task'), throwsStateError);
    expect(store.status, 'pending');
    expect(fetches, 1);
    store.failCommit = false;
    expect(await planner.process('task'), 'created');
    expect(store.status, 'completed');
  });

  test(
    'a stale PR delivery completes without reacquiring the current planning fence',
    () async {
      final store = _Store()
        ..pullRequest = true
        ..conflictsRemaining = 1;
      var fetches = 0;
      var observations = 0;
      final planner = BuildJobPlanner(
        store: store,
        fetchWorkflows: (_) async {
          fetches++;
          return [
            const OpenCIFile(
              name: 'ci.dart',
              path: 'openci/ci.dart',
              content:
                  "void main() { OpenCI.init(workflowName: 'CI', ciTriggers: [CITrigger.pullRequest(branch: '*')], cancelPreviousRuns: true); }",
            ),
          ];
        },
        observePullRequest: (_) async => ++observations == 1
            ? PullRequestObservation.current
            : PullRequestObservation.stale,
      );
      expect(await planner.process('task'), 'created');
      expect(fetches, 1);
      expect(observations, 2);
      expect(store.fences, hasLength(1));
      expect(store.published, isEmpty);
      expect(store.status, 'completed');
    },
  );

  test('a failed PR recheck leaves the task pending for redelivery', () async {
    final store = _Store()
      ..pullRequest = true
      ..conflictsRemaining = 1;
    var observations = 0;
    final planner = BuildJobPlanner(
      store: store,
      fetchWorkflows: (_) async => [],
      observePullRequest: (_) async {
        if (++observations == 2) throw StateError('GitHub unavailable');
        return PullRequestObservation.current;
      },
    );

    await expectLater(planner.process('task'), throwsStateError);
    expect(store.status, 'pending');
    expect(store.fences, hasLength(1));
    expect(await planner.process('task'), 'created');
    expect(store.status, 'completed');
  });

  test(
    'sustained contention stays pending for durable event redelivery',
    () async {
      final store = _Store()
        ..pullRequest = true
        ..conflictsRemaining = 3;
      final planner = BuildJobPlanner(
        store: store,
        fetchWorkflows: (_) async => [],
        observePullRequest: (_) async => PullRequestObservation.current,
      );
      await expectLater(
        planner.process('task'),
        throwsA(isA<PlanningObservationSuperseded>()),
      );
      expect(store.fences, hasLength(3));
      expect(store.status, 'pending');
      expect(await planner.process('task'), 'created');
      expect(store.status, 'completed');
    },
  );
}
