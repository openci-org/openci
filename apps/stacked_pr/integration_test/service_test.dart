import 'dart:io';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:stacked_pr_app/src/git.dart';
import 'package:stacked_pr_app/src/models.dart';
import 'package:stacked_pr_app/src/service.dart';
import '../test/support/fixtures.dart';
import '../test/support/mocks.mocks.dart';
import 'support/git_fixture.dart';

const repo = Repository(id: 20, fullName: 'org/repo', defaultBranch: 'main');

class Harness {
  Harness(this.f);
  final GitFixture f;
  final api = MockGitHubApi(), reporter = MockReporter();
  late Service service;
  late List<PullRequest> records;
  final events = <int, List<Json>>{};
  final reports = <({List<PullRequest> pulls, RestackException? error})>[];
  final patches = <Json>[];
  bool failPatch = false;
  int generation = 0;

  static Future<Harness> create({bool autoRestack = true}) async {
    final h = Harness(await GitFixture.create());
    h.records = h.f.pulls.map((p) => p.copy()).toList();
    when(
      h.api.timeline(any, any, any),
    ).thenAnswer((i) async => h.events[i.positionalArguments[2]] ?? []);
    when(h.api.timelines(any, any, any)).thenAnswer(
      (i) async => {for (final n in i.positionalArguments[2] as List<int>) n: h.events[n] ?? []},
    );
    when(h.api.installationActive(any)).thenAnswer((_) async => true);
    when(h.api.canWrite(any, any, any)).thenAnswer((_) async => true);
    when(h.api.list(any, any, field: anyNamed('field'))).thenAnswer((i) async {
      final uri = Uri.parse(i.positionalArguments[1] as String);
      final closed = uri.queryParameters['state'] == 'closed';
      final branch = uri.queryParameters['head']?.split(':').last;
      return Future.wait(
        h.records
            .where((p) => p.isOpen != closed && (branch == null || p.headRef == branch))
            .map(h.raw),
      );
    });
    when(h.api.request(any, any, any, any)).thenAnswer((i) async {
      final method = i.positionalArguments[1] as String;
      final path = i.positionalArguments[2] as String;
      if (path == repo.apiPath) return repo.toJson();
      final number = int.parse(path.split('/').last);
      final pr = h.records.firstWhere((p) => p.number == number);
      if (method == 'PATCH') {
        if (h.failPatch) throw StateError('simulated outage after push');
        final body = i.positionalArguments[3] as Json;
        h.patches.add(body);
        h.baseChange(number, pr.baseRef, body['base'] as String);
        pr.baseRef = body['base'] as String;
      }
      return h.raw(pr);
    });
    when(
      h.reporter.publish(
        any,
        any,
        any,
        error: anyNamed('error'),
        observeOnly: anyNamed('observeOnly'),
        closedToUpdate: anyNamed('closedToUpdate'),
      ),
    ).thenAnswer((i) async {
      h.reports.add((
        pulls: (i.positionalArguments[2] as List<PullRequest>).map((p) => p.copy()).toList(),
        error: i.namedArguments[#error] as RestackException?,
      ));
    });
    await h.restart(autoRestack: autoRestack);
    return h;
  }

  Future<void> restart({bool autoRestack = true}) async {
    f.worker = GitRepository(
      directory: p.join(f.root.path, 'invocation-${generation++}.git'),
      remote: f.remote,
      allowLocal: true,
    );
    await Directory(f.worker.directory).create();
    service = Service(
      config: config(dataDir: f.root.path, autoRestack: autoRestack),
      api: api,
      reporter: reporter,
      gitFactory: (_, _) => f.worker,
    );
  }

  Future<Json> raw(PullRequest pr) async {
    final heads = await f.worker.remoteHeads([pr.headRef, pr.baseRef]);
    return {
      'number': pr.number,
      'title': pr.title,
      'state': pr.state,
      'merged': pr.merged,
      'merged_at': pr.merged ? '2026-11-01T00:00:00Z' : null,
      'merge_commit_sha': pr.mergeCommit,
      'draft': pr.draft,
      'html_url': '',
      'head': {
        'ref': pr.headRef,
        'sha': heads[pr.headRef] ?? pr.head,
        'repo': {'id': repo.id},
      },
      'base': {
        'ref': pr.baseRef,
        'sha': heads[pr.baseRef] ?? pr.base,
        'repo': {'id': repo.id},
      },
    };
  }

  void forced(int number, String before, String after) {
    events.putIfAbsent(number, () => []).add({
      '__typename': 'HeadRefForcePushedEvent',
      'createdAt': '2026-11-01T00:00:00Z',
      'beforeCommit': {'oid': before},
      'afterCommit': {'oid': after},
    });
  }

  void baseChange(int number, String before, String after) {
    events.putIfAbsent(number, () => []).add({
      '__typename': 'BaseRefChangedEvent',
      'createdAt': '2026-11-01T00:00:01Z',
      'previousRefName': before,
      'currentRefName': after,
    });
  }

  Future<String> rewriteParent({bool recordHistory = true}) async {
    await f.git(['checkout', 'parent']);
    await File(p.join(f.author, 'parent.txt')).writeAsString('revised parent\n');
    await f.git(['add', '.']);
    await f.git(['commit', '--amend', '-m', 'revised parent']);
    final head = await f.git(['rev-parse', 'HEAD']);
    await f.git(['push', '--force', 'origin', 'parent']);
    if (recordHistory) forced(1, f.parent, head);
    return head;
  }

  Future<String> merge({bool retarget = false}) async {
    final sha = await f.squash(deleteParent: true);
    records[0] = modify(records[0], {'state': 'closed', 'merged': true, 'mergeCommit': sha});
    if (retarget) {
      baseChange(2, 'parent', 'main');
      records[1].baseRef = 'main';
    }
    return sha;
  }

  Future<List<PullRequest>> addStack(int number, String prefix) async {
    final items = <PullRequest>[];
    var ref = 'main', sha = f.main;
    for (final part in ['parent', 'child']) {
      final name = '$prefix-$part';
      await f.git(['checkout', '-b', name, sha]);
      final head = await f.commit('$name.txt', '$name\n', name);
      items.add(
        PullRequest(
          number: number++,
          title: name,
          head: head,
          headRef: name,
          base: sha,
          baseRef: ref,
        ),
      );
      sha = head;
      ref = name;
    }
    await f.git(['push', 'origin', ...items.map((p) => p.headRef)]);
    records.addAll(items);
    return items;
  }

  Future<Map<String, String>> heads() =>
      f.worker.remoteHeads(['main', 'parent', 'child', 'grandchild']);
}

void main() {
  test('fresh invocation discovers a stack without changing aligned branches', () async {
    final h = await Harness.create();
    final before = await h.heads();
    await h.service.reconcile(10, repo);
    expect(await h.heads(), before);
    expect(h.reports.single.error, isNull);
    expect(h.reports.single.pulls.map((p) => p.parent), [null, 1, 2]);
  });
  test('normal parent push discovers the earlier fork point from Git', () async {
    final h = await Harness.create();
    final parent = await h.f.advanceParent();
    await h.restart();
    await h.service.reconcile(10, repo);
    final heads = await h.heads();
    expect(await h.f.output(['rev-parse', '${heads['child']}^']), parent);
    expect(await h.f.output(['rev-parse', '${heads['grandchild']}^']), heads['child']);
    expect(await h.f.output(['diff', '--name-only', parent, heads['child']!]), 'child.txt');
  });
  test('force-pushed parent is recovered from GitHub history with a fresh clone', () async {
    final h = await Harness.create();
    final parent = await h.rewriteParent();
    await h.restart();
    await h.service.reconcile(10, repo);
    final heads = await h.heads();
    expect(h.reports.single.error, isNull);
    expect(await h.f.output(['rev-parse', '${heads['child']}^']), parent);
    expect(await h.f.output(['rev-list', '--count', '$parent..${heads['child']}']), '1');
    expect(await h.f.output(['diff', '--name-only', parent, heads['child']!]), 'child.txt');
  });
  test('missing force-push history blocks only the affected stack', () async {
    final h = await Harness.create();
    final independent = await h.addStack(4, 'independent');
    await h.rewriteParent(recordHistory: false);
    final unchanged = await h.heads();
    await h.f.git(['checkout', independent[0].headRef]);
    final updated = await h.f.commit('new-independent.txt', 'new\n', 'advance');
    await h.f.git(['push', 'origin', independent[0].headRef]);
    await h.service.reconcile(10, repo);
    expect((await h.heads())['child'], unchanged['child']);
    final other = await h.f.worker.remoteHeads([independent[1].headRef]);
    expect(await h.f.output(['rev-parse', '${other.values.single}^']), updated);
    expect(h.reports.where((r) => r.error != null).single.error!.number, 2);
    expect(h.reports.firstWhere((r) => r.pulls.any((p) => p.number == 5)).error, isNull);
  });
  for (final retarget in [false, true]) {
    test(
      'squash merge and deleted parent restack without saved state (retarget=$retarget)',
      () async {
        final h = await Harness.create();
        final main = await h.merge(retarget: retarget);
        await h.restart();
        await h.service.reconcile(10, repo);
        final heads = await h.heads();
        expect(h.reports.single.error, isNull);
        expect(await h.f.output(['rev-parse', '${heads['child']}^']), main);
        expect(await h.f.output(['diff', '--name-only', main, heads['child']!]), 'child.txt');
        expect(h.records[1].baseRef, 'main');
      },
    );
  }
  test('lost response after atomic push recovers with a new invocation and no journal', () async {
    final h = await Harness.create();
    await h.merge();
    h.failPatch = true;
    await expectLater(h.service.reconcile(10, repo), throwsStateError);
    final pushed = await h.heads();
    h.failPatch = false;
    await h.restart();
    await h.service.reconcile(10, repo);
    expect(await h.heads(), pushed);
    expect(h.records[1].baseRef, 'main');
    await h.restart();
    await h.service.reconcile(10, repo);
    expect(await h.heads(), pushed);
  });
  test('two merged ancestors recover a chain of automatic base changes', () async {
    final h = await Harness.create();
    await h.f.git(['checkout', 'parent']);
    await h.f.git(['merge', '--squash', 'child']);
    await h.f.git(['commit', '-m', 'squash child into parent']);
    final mergedChild = await h.f.git(['rev-parse', 'HEAD']);
    await h.f.git(['push', 'origin', 'parent', ':child']);
    h.records[1] = modify(h.records[1], {
      'state': 'closed',
      'merged': true,
      'mergeCommit': mergedChild,
    });
    h.baseChange(3, 'child', 'parent');
    await h.f.git(['checkout', 'main']);
    await h.f.git(['merge', '--squash', 'parent']);
    await h.f.git(['commit', '-m', 'squash parent into main']);
    final main = await h.f.git(['rev-parse', 'HEAD']);
    await h.f.git(['push', 'origin', 'main', ':parent']);
    h.records[0] = modify(h.records[0], {
      'head': mergedChild,
      'state': 'closed',
      'merged': true,
      'mergeCommit': main,
    });
    h.baseChange(3, 'parent', 'main');
    h.records[2].baseRef = 'main';
    await h.restart();
    await h.service.reconcile(10, repo, number: 3);
    final heads = await h.heads();
    expect(h.reports.single.error, isNull);
    expect(await h.f.output(['rev-parse', '${heads['grandchild']}^']), main);
    expect(await h.f.output(['diff', '--name-only', main, heads['grandchild']!]), 'grandchild.txt');
  });
  test('a PR notification only fetches and updates the connected stack', () async {
    final h = await Harness.create();
    final other = await h.addStack(4, 'other');
    await h.f.advanceParent();
    await h.f.git(['checkout', other.first.headRef]);
    await h.f.commit('other-new.txt', 'new\n', 'advance other');
    await h.f.git(['push', 'origin', other.first.headRef]);
    final oldHead = (await h.f.worker.remoteHeads([other.last.headRef])).values.single;
    await h.restart();
    await h.service.reconcile(10, repo, number: 2);
    expect(h.reports, hasLength(1));
    expect(h.reports.single.pulls.every((p) => p.number <= 3), isTrue);
    expect((await h.f.worker.remoteHeads([other.last.headRef])).values.single, oldHead);
    await expectLater(h.f.worker.branch(other.last.headRef), throwsA(isA<GitException>()));
  });
  test('changing a PR base refreshes both affected stacks, leaving others alone', () async {
    final h = await Harness.create();
    await h.addStack(4, 'unrelated');
    h.records[2].baseRef = 'main';
    h.baseChange(3, 'child', 'main');
    await h.service.handle(
      Job(
        id: 'base-change',
        event: 'pull_request',
        payload: {
          'action': 'edited',
          'installation': {'id': 10},
          'repository': repo.toJson(),
          'pull_request': {'number': 3},
          'previous_base': 'child',
        },
      ),
    );
    expect(h.reports, hasLength(2));
    expect(h.reports.expand((r) => r.pulls).map((p) => p.number).toSet(), {1, 2, 3});
  });
  test('branching children both follow their parent', () async {
    final h = await Harness.create();
    await h.f.git(['checkout', '-b', 'sibling', h.f.parent]);
    final sibling = await h.f.commit('sibling.txt', 'sibling\n', 'sibling');
    await h.f.git(['push', 'origin', 'sibling']);
    h.records.add(
      PullRequest(
        number: 4,
        title: 'sibling',
        head: sibling,
        headRef: 'sibling',
        base: h.f.parent,
        baseRef: 'parent',
      ),
    );
    final parent = await h.f.advanceParent();
    await h.service.reconcile(10, repo);
    final heads = await h.f.worker.remoteHeads(['child', 'sibling']);
    for (final head in heads.values) {
      expect(await h.f.output(['rev-parse', '$head^']), parent);
    }
    expect(h.reports.single.error, isNull);
  });
  test('cycle reports stay within their component', () async {
    final h = await Harness.create();
    await h.addStack(4, 'healthy');
    h.records[0].baseRef = 'grandchild';
    await h.service.reconcile(10, repo);
    expect(h.reports.firstWhere((r) => r.pulls.any((p) => p.number == 2)).error, isNotNull);
    expect(h.reports.firstWhere((r) => r.pulls.any((p) => p.number == 5)).error, isNull);
  });
  test('conflict does not push any member of its stack', () async {
    final h = await Harness.create();
    await h.f.git(['checkout', 'child']);
    await h.f.commit('parent.txt', 'child edit\n', 'child edit');
    await h.f.git(['push', 'origin', 'child']);
    await h.f.git(['checkout', 'parent']);
    await h.f.commit('parent.txt', 'parent edit\n', 'parent edit');
    await h.f.git(['push', 'origin', 'parent']);
    final before = await h.heads();
    await h.service.reconcile(10, repo);
    expect(await h.heads(), before);
    expect(h.reports.single.error!.files, ['parent.txt']);
  });
  test('closed unmerged parent requires a decision, even without prior app execution', () async {
    final h = await Harness.create();
    h.records[0] = modify(h.records[0], {'state': 'closed'});
    await h.service.reconcile(10, repo);
    expect(h.reports.single.error!.message, contains('mergeされず'));
  });
  test('observe mode does not rebase; unauthorized sync cannot enable it', () async {
    final h = await Harness.create(autoRestack: false);
    await h.f.advanceParent();
    final before = await h.heads();
    await h.service.reconcile(10, repo);
    expect(await h.heads(), before);
    when(h.api.canWrite(any, any, any)).thenAnswer((_) async => false);
    await h.service.handle(
      Job(
        id: 'sync',
        event: 'issue_comment',
        payload: {
          'action': 'created',
          'installation': {'id': 10},
          'repository': repo.toJson(),
          'issue': {'pull_request': <String, Object?>{}},
          'comment': {'body': '/stack sync'},
          'sender': {'login': 'reader', 'type': 'User'},
        },
      ),
    );
    expect(await h.heads(), before);
  });
  test('removed installations do no repository work', () async {
    final h = await Harness.create();
    when(h.api.installationActive(any)).thenAnswer((_) async => false);
    await h.service.handle(
      Job(
        id: 'old',
        event: 'reconcile',
        payload: {
          'installation': {'id': 10},
          'repository': repo.toJson(),
        },
      ),
    );
    verifyNever(h.api.list(any, any, field: anyNamed('field')));
  });
}
