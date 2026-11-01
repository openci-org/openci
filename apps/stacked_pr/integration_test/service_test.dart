import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:stacked_pr_app/src/models.dart';
import 'package:stacked_pr_app/src/service.dart';
import 'package:stacked_pr_app/src/stack.dart';
import 'package:stacked_pr_app/src/store.dart';
import '../test/support/fixtures.dart';
import '../test/support/mocks.mocks.dart';
import 'support/git_fixture.dart';

const repo = Repository(id: 20, fullName: 'org/repo', defaultBranch: 'main');

class Harness {
  Harness(this.f, this.store, this.records, this.api, this.reporter, this.service);
  final GitFixture f;
  Store store;
  final List<PullRequest> records;
  final MockGitHubApi api;
  final MockReporter reporter;
  Service service;
  bool failPatch = false;
  final patches = <Json>[];
  final staleHeads = <int, String>{};
  final mergeCommits = <int, String>{};

  static Future<Harness> create({bool autoRestack = true}) async {
    final f = await GitFixture.create();
    final store = Store(p.join(f.root.path, 'state.sqlite'));
    final api = MockGitHubApi(), reporter = MockReporter();
    final service = Service(
      config: config(dataDir: f.root.path, autoRestack: autoRestack),
      store: store,
      api: api,
      reporter: reporter,
      gitFactory: (_, _) => f.worker,
    );
    final h = Harness(f, store, f.pulls.map((p) => p.copy()).toList(), api, reporter, service);
    addTearDown(() => h.store.close());
    when(
      api.list(any, any, field: anyNamed('field')),
    ).thenAnswer((_) async => Future.wait(h.records.where((p) => p.isOpen).map(h.raw)));
    when(api.request(any, any, any, any)).thenAnswer((invocation) async {
      final method = invocation.positionalArguments[1] as String;
      final path = invocation.positionalArguments[2] as String;
      if (path == repo.apiPath) return repo.toJson();
      final number = int.parse(path.split('/').last);
      final pr = h.records.firstWhere((p) => p.number == number);
      if (method == 'PATCH') {
        if (h.failPatch) throw StateError('simulated API outage');
        final body = invocation.positionalArguments[3] as Json;
        h.patches.add(body);
        pr.baseRef = body['base'] as String;
      }
      return h.raw(pr);
    });
    when(api.canWrite(any, any, any)).thenAnswer((_) async => true);
    return h;
  }

  void restart() {
    store.close();
    store = Store(p.join(f.root.path, 'state.sqlite'));
    service = Service(
      config: service.config,
      store: store,
      api: api,
      reporter: reporter,
      gitFactory: (_, _) => f.worker,
    );
  }

  Future<List<PullRequest>> addStack(int firstNumber, String prefix) async {
    final pulls = <PullRequest>[];
    var baseRef = 'main', base = f.main;
    for (final layer in ['parent', 'child', 'grandchild']) {
      final headRef = '$prefix-$layer';
      await f.git(['checkout', '-b', headRef, base]);
      final head = await f.commit('$headRef.txt', '$headRef\n', headRef);
      pulls.add(
        PullRequest(
          number: firstNumber + pulls.length,
          title: headRef,
          head: head,
          headRef: headRef,
          base: base,
          baseRef: baseRef,
        ),
      );
      baseRef = headRef;
      base = head;
    }
    await f.git(['push', 'origin', ...pulls.map((pr) => pr.headRef)]);
    records.addAll(pulls);
    return pulls;
  }

  Future<Json> raw(PullRequest pr) async {
    final heads = await f.worker.remoteHeads([pr.headRef, pr.baseRef]);
    return {
      'number': pr.number,
      'title': pr.title,
      'state': pr.state,
      'merged': pr.merged,
      'merge_commit_sha': mergeCommits[pr.number],
      'draft': pr.draft,
      'html_url': '',
      'head': {
        'ref': pr.headRef,
        'sha': staleHeads[pr.number] ?? heads[pr.headRef] ?? pr.head,
        'repo': {'id': repo.id},
      },
      'base': {
        'ref': pr.baseRef,
        'sha': heads[pr.baseRef] ?? pr.base,
        'repo': {'id': repo.id},
      },
    };
  }

  Future<Operation> prepareMerge() async {
    await f.squash();
    records[0] = modify(records[0], {'state': 'closed', 'merged': true});
    final plan = await planRestack(f.pulls, f.worker);
    final operation = Operation(changes: plan.changes, nextState: RepositoryState(plan.pulls));
    store.save('10:20', RepositoryState(f.pulls), operation);
    return operation;
  }

  MockGitRepository recoveryGit() {
    final git = MockGitRepository();
    when(
      git.remoteHeads(any),
    ).thenAnswer((i) => f.worker.remoteHeads(i.positionalArguments[0] as List<String>));
    when(git.push(any)).thenThrow(StateError('Recovery must not push twice'));
    return git;
  }
}

void main() {
  for (final legacyState in [false, true]) {
    test('manual restack onto older main recovers the stack (legacy: $legacyState)', () async {
      final h = await Harness.create();
      await h.service.reconcile(10, repo);
      final squash = await h.f.squash(deleteParent: true);
      h.records[0] = modify(h.records[0], {'state': 'closed', 'merged': true});
      h.mergeCommits[1] = squash;
      h.records[1].baseRef = 'main';
      if (legacyState) {
        final saved = h.store.load('10:20').state;
        saved.pulls[0] = h.records[0].copy();
        h.store.save('10:20', saved);
      }

      // A person restacks both branches before main receives another change.
      await h.f.commit('trunk-before.txt', 'already on main\n', 'advance before manual restack');
      await h.f.git(['rebase', '--onto', 'main', h.f.parent, 'child']);
      await h.f.git(['rebase', '--onto', 'child', h.f.child, 'grandchild']);
      await h.f.git(['push', '--force', 'origin', 'child', 'grandchild']);
      await h.f.git(['checkout', 'main']);
      final main = await h.f.commit(
        'trunk-after.txt',
        'new on main\n',
        'advance after manual restack',
      );
      await h.f.git(['push', 'origin', 'main']);
      clearInteractions(h.api);

      await h.service.reconcile(10, repo);

      final heads = await h.f.worker.remoteHeads(['child', 'grandchild']);
      final child = heads['child']!, grandchild = heads['grandchild']!;
      expect(await h.f.output(['rev-parse', '$child^']), main);
      expect(await h.f.output(['diff', '--name-only', main, child]), 'child.txt');
      expect(await h.f.output(['rev-parse', '$grandchild^']), child);
      expect(await h.f.output(['diff', '--name-only', child, grandchild]), 'grandchild.txt');
      final saved = h.store.load('10:20');
      expect(saved.operation, isNull);
      expect(saved.state.pulls.firstWhere((pr) => pr.number == 2).parent, isNull);
      expect(saved.state.pulls.firstWhere((pr) => pr.number == 2).boundary, main);
      expect(saved.state.pulls.firstWhere((pr) => pr.number == 3).boundary, child);
      expect(saved.state.pulls.firstWhere((pr) => pr.number == 1).toJson()['mergeCommit'], squash);
      verify(h.api.request(10, 'GET', '${repo.apiPath}/pulls/1')).called(1);

      h.restart();
      await h.service.reconcile(10, repo);
      expect(await h.f.worker.remoteHeads(['child', 'grandchild']), heads);
      verifyNever(h.api.request(10, 'GET', '${repo.apiPath}/pulls/1'));
    });
  }

  for (final scenario in ['missing merge commit', 'child before merge', 'target before merge']) {
    test('manual restack stays blocked when merge cannot be proven: $scenario', () async {
      final h = await Harness.create();
      await h.service.reconcile(10, repo);
      final squash = await h.f.squash();
      h.records[0] = modify(h.records[0], {'state': 'closed', 'merged': true});
      h.records[1].baseRef = 'main';
      if (scenario != 'missing merge commit') h.mergeCommits[1] = squash;
      final manualBase = scenario == 'child before merge' ? h.f.main : squash;
      await h.f.git(['rebase', '--onto', manualBase, h.f.parent, 'child']);
      await h.f.git(['rebase', '--onto', 'child', h.f.child, 'grandchild']);
      await h.f.git(['push', '--force', 'origin', 'child', 'grandchild']);
      await h.f.git(['checkout', 'main']);
      if (scenario == 'target before merge') await h.f.git(['reset', '--hard', h.f.main]);
      await h.f.commit('trunk-after.txt', 'new on main\n', 'advance main');
      await h.f.git(['push', '--force', 'origin', 'main']);
      final before = await h.f.worker.remoteHeads(['main', 'child', 'grandchild']);
      clearInteractions(h.reporter);

      await h.service.reconcile(10, repo);

      expect(await h.f.worker.remoteHeads(before.keys.toList()), before);
      final saved = h.store.load('10:20');
      expect(saved.operation, isNull);
      expect(saved.state.pulls.firstWhere((pr) => pr.number == 2).boundary, h.f.parent);
      final error =
          verify(
                h.reporter.publish(
                  10,
                  any,
                  any,
                  error: captureAnyNamed('error'),
                  observeOnly: anyNamed('observeOnly'),
                  closedToUpdate: anyNamed('closedToUpdate'),
                ),
              ).captured.single
              as RestackException;
      expect(error.number, 2);
      expect(error.message, contains('変更境界'));
    });
  }

  test('conflict after boundary recovery leaves the entire stack unchanged', () async {
    final h = await Harness.create();
    await h.service.reconcile(10, repo);
    final squash = await h.f.squash();
    h.records[0] = modify(h.records[0], {'state': 'closed', 'merged': true});
    h.mergeCommits[1] = squash;
    h.records[1].baseRef = 'main';
    await h.f.git(['rebase', '--onto', 'main', h.f.parent, 'child']);
    await h.f.git(['rebase', '--onto', 'child', h.f.child, 'grandchild']);
    await h.f.commit('parent.txt', 'grandchild edit\n', 'grandchild changes merged parent');
    await h.f.git(['push', '--force', 'origin', 'child', 'grandchild']);
    await h.f.git(['checkout', 'main']);
    await h.f.commit('parent.txt', 'conflicting main edit\n', 'main changes merged parent');
    await h.f.git(['push', 'origin', 'main']);
    final before = await h.f.worker.remoteHeads(['main', 'child', 'grandchild']);
    clearInteractions(h.reporter);

    await h.service.reconcile(10, repo);

    expect(await h.f.worker.remoteHeads(before.keys.toList()), before);
    expect(h.store.load('10:20').operation, isNull);
    final error =
        verify(
              h.reporter.publish(
                10,
                any,
                any,
                error: captureAnyNamed('error'),
                observeOnly: anyNamed('observeOnly'),
                closedToUpdate: anyNamed('closedToUpdate'),
              ),
            ).captured.single
            as RestackException;
    expect(error.number, 3);
    expect(error.files, ['parent.txt']);
  });

  for (final failure in ['stored boundary', 'initial boundary', 'descendant conflict']) {
    for (final failingStackFirst in [true, false]) {
      test(
        'merged parent restacks despite unrelated $failure (failed first: $failingStackFirst)',
        () async {
          final h = await Harness.create();
          final independent = await h.addStack(4, 'independent');
          if (!failingStackFirst) {
            h.records
              ..removeWhere((pr) => independent.contains(pr))
              ..insertAll(0, independent);
          }
          await h.service.reconcile(10, repo);
          clearInteractions(h.reporter);

          if (failure == 'stored boundary') {
            await h.f.advanceParent();
            await h.f.git(['checkout', 'child']);
            await h.f.git(['reset', '--soft', h.f.main]);
            await h.f.git(['commit', '-m', 'rewrite child without its saved boundary']);
            await h.f.git(['push', '--force', 'origin', 'child']);
          } else if (failure == 'initial boundary') {
            final saved = h.store.load('10:20');
            saved.state.pulls.removeWhere((pr) => pr.number <= 3);
            h.store.save('10:20', saved.state);
            await h.f.git(['checkout', 'parent']);
            await h.f.git(['reset', '--soft', h.f.main]);
            await h.f.git(['commit', '-m', 'rewrite parent before discovery']);
            await h.f.git(['push', '--force', 'origin', 'parent']);
          } else {
            await h.f.git(['checkout', 'grandchild']);
            await h.f.commit('parent.txt', 'grandchild edit\n', 'conflicting descendant');
            await h.f.git(['push', 'origin', 'grandchild']);
            await h.f.git(['checkout', 'parent']);
            await h.f.commit('parent.txt', 'parent edit\n', 'conflicting parent');
            await h.f.git(['push', 'origin', 'parent']);
          }
          final failedHeads = await h.f.worker.remoteHeads(['child', 'grandchild']);

          await h.f.git(['checkout', 'main']);
          await h.f.git(['merge', '--squash', independent.first.headRef]);
          await h.f.git(['commit', '-m', 'merge independent parent']);
          await h.f.git(['push', 'origin', 'main']);
          final parentIndex = h.records.indexWhere((pr) => pr.number == 4);
          h.records[parentIndex] = modify(independent.first, {'state': 'closed', 'merged': true});
          independent[1].baseRef = 'main';

          await h.service.reconcile(10, repo);

          final heads = await h.f.worker.remoteHeads([
            'main',
            'independent-child',
            'independent-grandchild',
          ]);
          expect(await h.f.output(['rev-parse', '${heads['independent-child']}^']), heads['main']);
          expect(
            await h.f.output(['diff', '--name-only', heads['main']!, heads['independent-child']!]),
            'independent-child.txt',
          );
          expect(
            await h.f.output(['rev-parse', '${heads['independent-grandchild']}^']),
            heads['independent-child'],
          );
          expect(await h.f.worker.remoteHeads(['child', 'grandchild']), failedHeads);
          final saved = h.store.load('10:20');
          expect(saved.operation, isNull);
          expect(saved.state.pulls.firstWhere((pr) => pr.number == 5).parent, isNull);
          final reports = verify(
            h.reporter.publish(
              10,
              any,
              captureAny,
              error: captureAnyNamed('error'),
              observeOnly: anyNamed('observeOnly'),
              closedToUpdate: anyNamed('closedToUpdate'),
            ),
          ).captured;
          final failures = <RestackException>[];
          for (var i = 0; i < reports.length; i += 2) {
            final reportedPulls = reports[i] as List<PullRequest>;
            final error = reports[i + 1] as RestackException?;
            if (reportedPulls.any((pr) => pr.number == 5)) expect(error, isNull);
            if (error != null) failures.add(error);
          }
          expect(failures.single.number, failure == 'descendant conflict' ? 3 : 2);

          h.restart();
          await h.service.reconcile(10, repo);
          expect(await h.f.worker.remoteHeads(heads.keys.toList()), heads);
          expect(await h.f.worker.remoteHeads(['child', 'grandchild']), failedHeads);
        },
      );
    }
  }

  test('multiple failed stacks keep separate reports while another stack restacks', () async {
    final h = await Harness.create();
    final otherFailure = await h.addStack(4, 'other-failure');
    final healthy = await h.addStack(7, 'healthy');
    await h.service.reconcile(10, repo);
    clearInteractions(h.reporter);
    for (final number in [1, 4]) {
      final index = h.records.indexWhere((pr) => pr.number == number);
      h.records[index] = modify(h.records[index], {'state': 'closed'});
    }
    await h.f.git(['checkout', healthy.first.headRef]);
    final parent = await h.f.commit('healthy-update.txt', 'updated\n', 'update healthy stack');
    await h.f.git(['push', 'origin', healthy.first.headRef]);

    await h.service.reconcile(10, repo);

    final heads = await h.f.worker.remoteHeads(['child', 'other-failure-child', 'healthy-child']);
    expect(heads['child'], h.f.child);
    expect(heads['other-failure-child'], otherFailure[1].head);
    expect(await h.f.output(['rev-parse', '${heads['healthy-child']}^']), parent);
    final reports = verify(
      h.reporter.publish(
        10,
        any,
        captureAny,
        error: captureAnyNamed('error'),
        observeOnly: anyNamed('observeOnly'),
        closedToUpdate: anyNamed('closedToUpdate'),
      ),
    ).captured;
    final failures = <int>[];
    for (var i = 0; i < reports.length; i += 2) {
      final pulls = reports[i] as List<PullRequest>;
      final error = reports[i + 1] as RestackException?;
      if (error == null) {
        expect(pulls.map((pr) => pr.number), [7, 8, 9]);
      } else {
        expect(pulls.map((pr) => pr.number), contains(error.number));
        failures.add(error.number!);
      }
    }
    expect(failures, [2, 5]);
    expect(h.store.load('10:20').operation, isNull);
  });

  test('pending stack operation survives a restart before another stack updates', () async {
    final h = await Harness.create();
    final independent = await h.addStack(4, 'independent');
    await h.service.reconcile(10, repo);
    await h.f.squash();
    h.records[0] = modify(h.records[0], {'state': 'closed', 'merged': true});
    await h.f.git(['checkout', independent.first.headRef]);
    final parent = await h.f.commit(
      'independent-update.txt',
      'updated\n',
      'update independent stack',
    );
    await h.f.git(['push', 'origin', independent.first.headRef]);
    h.failPatch = true;

    await expectLater(h.service.reconcile(10, repo), throwsStateError);

    final pending = h.store.load('10:20').operation!;
    expect(pending.phase, 'pushed');
    expect(pending.changes.map((change) => change.number), [2, 3]);
    expect(
      (await h.f.worker.remoteHeads(['independent-child']))['independent-child'],
      independent[1].head,
    );
    final child = (await h.f.worker.remoteHeads(['child']))['child'];
    expect(child, isNot(h.f.child));

    h.failPatch = false;
    h.restart();
    await h.service.reconcile(10, repo);

    final heads = await h.f.worker.remoteHeads(['child', 'independent-child']);
    expect(heads['child'], child);
    expect(await h.f.output(['rev-parse', '${heads['independent-child']}^']), parent);
    expect(h.store.load('10:20').operation, isNull);
    expect(h.store.load('10:20').state.pulls.firstWhere((pr) => pr.number == 2).head, child);
  });

  test('PR discovery persists boundary; merge restacks from live refs', () async {
    final h = await Harness.create();
    await h.service.reconcile(10, repo);
    expect(h.store.load('10:20').state.pulls[1].boundary, h.f.parent);
    await h.f.squash(deleteParent: true);
    h.records[0] = modify(h.records[0], {'state': 'closed', 'merged': true});
    h.records[1].baseRef = 'main';
    await h.service.reconcile(10, repo);
    final saved = h.store.load('10:20');
    expect(saved.operation, isNull);
    expect(saved.state.pulls.firstWhere((p) => p.number == 2).parent, isNull);
    final heads = await h.f.worker.remoteHeads(['main', 'child']);
    expect(await h.f.output(['diff', '--name-only', heads['main']!, heads['child']!]), 'child.txt');
  });
  test('crash after push before journal phase resumes base changes without push', () async {
    final h = await Harness.create();
    final operation = await h.prepareMerge();
    await h.f.worker.push(operation.changes);
    // Reload the serialized operation, as a new process would.
    final saved = h.store.load('10:20');
    await h.service.finishOperation(
      10,
      repo,
      h.recoveryGit(),
      '10:20',
      saved.state,
      saved.operation!,
    );
    expect(h.patches.single['base'], 'main');
    expect(h.store.load('10:20').operation, isNull);
  });
  test('base API outage leaves pushed journal; retry completes idempotently', () async {
    final h = await Harness.create();
    final operation = await h.prepareMerge();
    h.failPatch = true;
    await expectLater(
      h.service.finishOperation(
        10,
        repo,
        h.f.worker,
        '10:20',
        RepositoryState(h.f.pulls),
        operation,
      ),
      throwsStateError,
    );
    final saved = h.store.load('10:20');
    expect(saved.operation!.phase, 'pushed');
    h.failPatch = false;
    await h.service.finishOperation(
      10,
      repo,
      h.recoveryGit(),
      '10:20',
      saved.state,
      saved.operation!,
    );
    expect(h.store.load('10:20').operation, isNull);
  });
  test('PR API lag after push retries without a failure report or duplicate push', () async {
    final h = await Harness.create();
    await h.service.reconcile(10, repo);
    clearInteractions(h.reporter);
    await h.f.advanceParent();
    h.staleHeads[2] = h.f.child;
    await expectLater(h.service.reconcile(10, repo), throwsA(isA<RetryException>()));
    verifyZeroInteractions(h.reporter);
    final saved = h.store.load('10:20');
    expect(saved.operation!.phase, 'pushed');
    final change = saved.operation!.changes.firstWhere((c) => c.number == 2);
    expect((await h.f.worker.remoteHeads(['child']))['child'], change.newHead);
    h.staleHeads.clear();
    await h.service.finishOperation(
      10,
      repo,
      h.recoveryGit(),
      '10:20',
      saved.state,
      saved.operation!,
    );
    expect(h.store.load('10:20').operation, isNull);
    expect(h.store.load('10:20').state.pulls.firstWhere((p) => p.number == 2).head, change.newHead);
  });
  test('branch change while fetching retries without a failure report', () async {
    final h = await Harness.create();
    await h.service.reconcile(10, repo);
    clearInteractions(h.reporter);
    await h.f.advanceParent();
    h.staleHeads[1] = h.f.parent;
    await expectLater(h.service.reconcile(10, repo), throwsA(isA<RetryException>()));
    verifyZeroInteractions(h.reporter);
    expect(h.store.load('10:20').operation, isNull);
    expect((await h.f.worker.remoteHeads(['child']))['child'], h.f.child);
  });
  for (final failure in ['PR API lag', 'report API outage']) {
    test('merged parent comment survives restart after $failure', () async {
      final h = await Harness.create();
      await h.service.reconcile(10, repo);
      clearInteractions(h.reporter);
      await h.f.squash();
      h.records[0] = modify(h.records[0], {'state': 'closed', 'merged': true});
      if (failure == 'PR API lag') {
        h.staleHeads[2] = h.f.child;
      } else {
        when(
          h.reporter.publish(
            any,
            any,
            any,
            observeOnly: anyNamed('observeOnly'),
            closedToUpdate: anyNamed('closedToUpdate'),
          ),
        ).thenThrow(const RetryException('simulated report API outage'));
      }
      await expectLater(h.service.reconcile(10, repo), throwsA(isA<RetryException>()));
      h.staleHeads.clear();
      reset(h.reporter);
      h.restart();
      await h.service.reconcile(10, repo);
      final updated = verify(
        h.reporter.publish(
          10,
          any,
          any,
          observeOnly: anyNamed('observeOnly'),
          closedToUpdate: captureAnyNamed('closedToUpdate'),
        ),
      ).captured.expand((numbers) => numbers as List<int>);
      expect(updated, [1]);
      expect(h.store.load('10:20').operation, isNull);
      await h.service.reconcile(10, repo);
      final repeated = verify(
        h.reporter.publish(
          10,
          any,
          any,
          observeOnly: anyNamed('observeOnly'),
          closedToUpdate: captureAnyNamed('closedToUpdate'),
        ),
      ).captured.expand((numbers) => numbers as List<int>);
      expect(repeated, isEmpty);
    });
  }
  test('human push discards stale preparation without overwriting work', () async {
    final h = await Harness.create();
    await h.f.advanceParent();
    final plan = await planRestack(h.f.pulls, h.f.worker);
    final operation = Operation(changes: plan.changes, nextState: RepositoryState(plan.pulls));
    h.store.save('10:20', RepositoryState(h.f.pulls), operation);
    await h.f.git(['checkout', 'child']);
    final human = await h.f.commit('human.txt', 'human\n', 'human');
    await h.f.git(['push', 'origin', 'child']);
    await expectLater(
      h.service.finishOperation(
        10,
        repo,
        h.f.worker,
        '10:20',
        RepositoryState(h.f.pulls),
        operation,
      ),
      throwsA(isA<RetryException>()),
    );
    expect(h.store.load('10:20').operation, isNull);
    expect((await h.f.worker.remoteHeads(['child']))['child'], human);
  });
  test('human push after app push keeps journal and halts recovery', () async {
    final h = await Harness.create();
    final operation = await h.prepareMerge();
    await h.f.worker.push(operation.changes);
    operation.phase = 'pushed';
    h.store.save('10:20', RepositoryState(h.f.pulls), operation);
    await h.f.git(['checkout', 'child']);
    await h.f.commit('human.txt', 'human\n', 'human');
    await h.f.git(['push', '--force', 'origin', 'child']);
    await expectLater(
      h.service.finishOperation(
        10,
        repo,
        h.recoveryGit(),
        '10:20',
        RepositoryState(h.f.pulls),
        operation,
      ),
      throwsA(isA<RestackException>()),
    );
    expect(h.store.load('10:20').operation, isNotNull);
  });
  test('commenter without write permission cannot reconcile', () async {
    final h = await Harness.create();
    when(h.api.canWrite(any, any, any)).thenAnswer((_) async => false);
    await h.service.handle(
      Job(
        id: 'command',
        event: 'issue_comment',
        payload: {
          'installation': {'id': 10},
          'repository': repo.toJson(),
          'action': 'created',
          'issue': {'pull_request': <String, Object?>{}},
          'sender': {'type': 'User', 'login': 'outsider'},
          'comment': {'body': '/stack sync'},
        },
      ),
    );
    verifyNever(h.api.request(any, any, any, any));
    expect(h.store.targets(), isEmpty);
  });
  test('removed commands already queued cannot trigger reconciliation', () async {
    final h = await Harness.create();
    for (final command in ['/stack rebase', '/stack retry']) {
      await h.service.handle(
        Job(
          id: command,
          event: 'issue_comment',
          payload: {
            'installation': {'id': 10},
            'repository': repo.toJson(),
            'action': 'created',
            'issue': {'pull_request': <String, Object?>{}},
            'sender': {'type': 'User', 'login': 'writer'},
            'comment': {'body': command},
          },
        ),
      );
    }
    verifyNever(h.api.canWrite(any, any, any));
    verifyNever(h.api.request(any, any, any, any));
    expect(h.store.targets(), isEmpty);
  });
  for (final event in ['issue_comment', 'check_run']) {
    test('manual sync via $event restacks descendants with automatic updates off', () async {
      final h = await Harness.create(autoRestack: false);
      await h.service.reconcile(10, repo);
      final parent = await h.f.advanceParent();
      await h.service.reconcile(10, repo);
      expect((await h.f.worker.remoteHeads(['child']))['child'], h.f.child);
      clearInteractions(h.reporter);
      final job = Job(
        id: 'sync',
        event: event,
        payload: {
          'installation': {'id': 10},
          'repository': repo.toJson(),
          'sender': {'type': 'User', 'login': 'writer'},
          if (event == 'issue_comment') ...{
            'action': 'created',
            'issue': {'pull_request': <String, Object?>{}},
            'comment': {'body': ' /stack sync\n'},
          } else ...{
            'action': 'requested_action',
            'requested_action': {'identifier': 'restack'},
            'check_run': {
              'app': {'id': 7},
            },
          },
        },
      );
      await h.service.handle(job);
      final heads = await h.f.worker.remoteHeads(['child', 'grandchild']);
      expect(heads['child'], isNot(h.f.child));
      expect(heads['grandchild'], isNot(h.f.grandchild));
      expect(await h.f.output(['rev-parse', '${heads['child']}^']), parent);
      expect(await h.f.output(['rev-parse', '${heads['grandchild']}^']), heads['child']);
      expect(await h.f.output(['diff', '--name-only', parent, heads['child']!]), 'child.txt');
      expect(
        await h.f.output(['diff', '--name-only', heads['child']!, heads['grandchild']!]),
        'grandchild.txt',
      );
      await h.service.handle(job);
      expect(await h.f.worker.remoteHeads(['child', 'grandchild']), heads);
      // Manual execution must not claim that automatic updates are now enabled.
      verify(
        h.reporter.publish(
          10,
          any,
          any,
          observeOnly: true,
          closedToUpdate: anyNamed('closedToUpdate'),
        ),
      ).called(2);
    });
  }
  test('observe mode discovers boundary and leaves heads unchanged', () async {
    final h = await Harness.create(autoRestack: false);
    await h.service.reconcile(10, repo);
    await h.f.advanceParent();
    await h.service.reconcile(10, repo);
    expect((await h.f.worker.remoteHeads(['child']))['child'], h.f.child);
    verify(
      h.reporter.publish(
        10,
        any,
        any,
        observeOnly: true,
        closedToUpdate: anyNamed('closedToUpdate'),
      ),
    ).called(2);
  });
  test('unknown initial rewrite is reported without guessing a boundary', () async {
    final h = await Harness.create();
    await h.f.git(['checkout', 'parent']);
    await h.f.git(['reset', '--soft', h.f.main]);
    await h.f.git(['commit', '-m', 'rewritten before discovery']);
    await h.f.git(['push', '--force', 'origin', 'parent']);
    await h.service.reconcile(10, repo);
    expect((await h.f.worker.remoteHeads(['child']))['child'], h.f.child);
    final errors = verify(
      h.reporter.publish(
        10,
        any,
        any,
        error: captureAnyNamed('error'),
        closedToUpdate: anyNamed('closedToUpdate'),
      ),
    ).captured;
    expect((errors.single as RestackException).message, contains('初回検出'));
  });
  test('recovery stops if target became default branch', () async {
    final h = await Harness.create();
    final operation = await h.prepareMerge();
    await expectLater(
      h.service.finishOperation(
        10,
        const Repository(id: 20, fullName: 'org/repo', defaultBranch: 'child'),
        h.recoveryGit(),
        '10:20',
        RepositoryState(h.f.pulls),
        operation,
      ),
      throwsA(isA<RestackException>().having((e) => e.message, 'reason', contains('デフォルト'))),
    );
  });
}
