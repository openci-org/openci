import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'config.dart';
import 'git.dart';
import 'github.dart';
import 'models.dart';
import 'report.dart';
import 'stack.dart';
import 'store.dart';

Json _object(Object? value) => value is Map ? jsonObject(value) : {};

class Service {
  Service({
    required this.config,
    required this.store,
    required this.api,
    required this.reporter,
    GitRepository Function(int, Repository)? gitFactory,
  }) : gitFactory =
           gitFactory ??
           ((installation, repo) => GitRepository(
             directory: p.join(config.dataDir, 'git', '$installation-${repo.id}.git'),
             remote: '${config.githubUrl}/${repo.fullName}.git',
             token: () => api.token(installation),
           ));

  final AppConfig config;
  final Store store;
  final GitHubApi api;
  final Reporter reporter;
  final GitRepository Function(int, Repository) gitFactory;

  bool allowed(Json repo) =>
      repo['id'] is int &&
      (repo['id']! as int) > 0 &&
      repo['full_name'] is String &&
      RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$').hasMatch(repo['full_name']! as String) &&
      (config.allowedRepos.isEmpty ||
          config.allowedRepos.contains((repo['full_name']! as String).toLowerCase()));

  Future<void> handle(Job job) async {
    final payload = job.payload;
    final installation = _object(payload['installation'])['id'];
    if (installation is! int || installation <= 0) return;
    if (['installation', 'installation_repositories'].contains(job.event)) {
      final action = payload['action'];
      if (['deleted', 'suspend'].contains(action)) {
        store.forget(installation);
        return;
      }
      if (action == 'removed') {
        for (final repo in jsonObjects(payload['repositories_removed'] ?? [])) {
          store.forget(installation, repo['id'] as int);
        }
        return;
      }
      if (!['created', 'added', 'unsuspend'].contains(action)) return;
      final repos = job.event == 'installation_repositories'
          ? jsonObjects(payload['repositories_added'] ?? [])
          : await api.list(installation, '/installation/repositories', field: 'repositories');
      for (final repo in repos) {
        if (allowed(repo)) {
          store.enqueue('${job.id}:${repo['id']}', 'reconcile', {
            'installation': {'id': installation},
            'repository': repo,
          });
        }
      }
      return;
    }
    final rawRepo = _object(payload['repository']);
    if (!allowed(rawRepo)) return;
    final repo = Repository.fromJson(rawRepo);
    if (job.event == 'reconcile' &&
        job.id.startsWith('poll:') &&
        !store.targets().any((t) => t.installation == installation && t.repo.id == repo.id)) {
      return;
    }
    var force = false;
    if (job.event == 'issue_comment') {
      final sender = _object(payload['sender']);
      if (_object(payload['issue'])['pull_request'] == null ||
          payload['action'] != 'created' ||
          sender['type'] == 'Bot') {
        return;
      }
      final command = (_object(payload['comment'])['body'] as String?)?.trim();
      if (command != '/stack sync') return;
      if (!await api.canWrite(installation, repo.apiPath, sender['login'] as String?)) return;
      force = true;
    }
    if (job.event == 'check_run') {
      if (payload['action'] != 'requested_action' ||
          _object(payload['requested_action'])['identifier'] != 'restack' ||
          _object(_object(payload['check_run'])['app'])['id'].toString() != config.appId) {
        return;
      }
      if (!await api.canWrite(
        installation,
        repo.apiPath,
        _object(payload['sender'])['login'] as String?,
      )) {
        return;
      }
      force = true;
    }
    store.remember(installation, repo);
    await reconcile(installation, repo, force: force);
  }

  Future<void> reconcile(int installation, Repository repo, {bool force = false}) async {
    final id = '$installation:${repo.id}';
    final saved = store.load(id);
    final git = gitFactory(installation, repo);
    var pulls = saved.state.pulls;
    var closedToUpdate = <int>[];
    final path = repo.apiPath;
    try {
      final metadata = jsonObject(await api.request(installation, 'GET', path));
      if (metadata['id'] != repo.id || metadata['default_branch'] is! String) {
        throw const RetryException('Repository identity changed');
      }
      repo = Repository(
        id: repo.id,
        fullName: repo.fullName,
        defaultBranch: metadata['default_branch'] as String,
      );
      store.remember(installation, repo);
      final pending = saved.operation;
      if (pending != null) {
        await git.prepare();
        await finishOperation(installation, repo, git, id, saved.state, pending);
        saved.state = store.load(id).state;
      }
      final current = await api.list(installation, '$path/pulls?state=open');
      final numbers = current.map((p) => p['number'] as int).toSet();
      for (final previous in saved.state.pulls) {
        // Older snapshots need the merged commit before a manual restack can be verified.
        final needsMergeCommit = previous.merged && previous.mergeCommit == null;
        if (numbers.contains(previous.number) || (!previous.isOpen && !needsMergeCommit)) continue;
        current.add(
          jsonObject(await api.request(installation, 'GET', '$path/pulls/${previous.number}')),
        );
        numbers.add(previous.number);
      }
      pulls = current.map((p) => PullRequest.fromApi(p, repo.id)).toList()
        ..addAll(saved.state.pulls.where((p) => !p.isOpen && !numbers.contains(p.number)));
      pulls = connect(pulls, saved.state.pulls);
      closedToUpdate = store.pendingClosedReports(id, pulls);
      final open = pulls.where((p) => p.isOpen && p.sameRepo).toList();
      if (!open.any((p) => p.parent != null)) {
        store.save(id, RepositoryState(pulls));
        await reporter.publish(installation, repo, pulls, closedToUpdate: closedToUpdate);
        store.completeClosedReports(id, closedToUpdate);
        return;
      }
      await git.prepare(open);
      final stacks = <List<PullRequest>>[];
      final assigned = <int>{};
      for (final pr in pulls) {
        if (assigned.contains(pr.number)) continue;
        final stack = stackFor(pulls, pr.number);
        assigned.addAll(stack.map((pr) => pr.number));
        stacks.add(stack);
      }
      store.save(id, RepositoryState(pulls));
      final errors = <int, RestackException>{};
      for (final stack in stacks) {
        final numbers = stack.map((pr) => pr.number).toSet();
        try {
          pulls = await _restackStack(
            installation,
            repo,
            git,
            pulls,
            pulls.where((pr) => numbers.contains(pr.number)).toList(),
            previous: saved.state.pulls,
            enabled: force || config.autoRestack,
          );
        } on RestackException catch (error) {
          // A pending push must be recovered before another stack can use the journal.
          if (!stack.any((pr) => pr.number == error.number) || store.load(id).operation != null) {
            rethrow;
          }
          store.save(id, RepositoryState(pulls));
          errors[stack.first.number] = error;
          _logRestackError(installation, repo, error);
        }
      }
      for (final stack in stacks) {
        final numbers = stack.map((pr) => pr.number).toSet();
        await reporter.publish(
          installation,
          repo,
          pulls.where((pr) => numbers.contains(pr.number)).toList(),
          error: errors[stack.first.number],
          observeOnly: !config.autoRestack,
          closedToUpdate: closedToUpdate.where(numbers.contains).toList(),
        );
      }
      store.completeClosedReports(id, closedToUpdate);
    } catch (error) {
      if (error is RetryException) rethrow;
      final reportError = error is RestackException
          ? error
          : const RestackException('Git / GitHub APIへの処理が完了しませんでした。VPSのログ・接続・App権限を確認してください。');
      await reporter.publish(
        installation,
        repo,
        pulls,
        error: reportError,
        closedToUpdate: closedToUpdate,
      );
      if (error is! RestackException) rethrow;
      _logRestackError(installation, repo, error);
    }
  }

  Future<List<PullRequest>> _restackStack(
    int installation,
    Repository repo,
    GitRepository git,
    List<PullRequest> pulls,
    List<PullRequest> stack, {
    required List<PullRequest> previous,
    required bool enabled,
  }) async {
    final open = stack.where((pr) => pr.isOpen && pr.sameRepo).toList();
    if (!open.any((pr) => pr.parent != null)) return pulls;
    final id = '$installation:${repo.id}';
    for (final pr in open) {
      if (await git.branch(pr.headRef) != pr.head) {
        throw const RetryException('Branch changed while fetching; retrying');
      }
      await git.pin(pr.head);
    }
    for (final pr in open.where((pr) => pr.parent != null)) {
      if (pr.headRef == repo.defaultBranch) {
        throw RestackException('デフォルトブランチを子PRとして書き換えることはできません。', number: pr.number);
      }
      if (pr.boundary == null) {
        final parent = stack.where((p) => p.number == pr.parent).first;
        final oldParent = previous.where((p) => p.number == pr.parent).firstOrNull;
        for (final candidate in {parent.head, if (oldParent != null) oldParent.head}) {
          await git.ensure(candidate);
          if (await git.ancestor(candidate, pr.head)) {
            pr.boundary = candidate;
            break;
          }
        }
        if (pr.boundary == null) {
          throw RestackException(
            '初回検出時点で親の履歴が既に変わっており、境界を確認できません。手元で子を現在の親へrestackしてから /stack sync を実行してください。',
            number: pr.number,
          );
        }
      }
      await git.ensure(pr.boundary!);
    }
    // Save discovery even when this stack's rebase reports a conflict.
    store.save(id, RepositoryState(pulls));
    final plan = await planRestack(stack, git, enabled: enabled);
    final updated = {for (final pr in plan.pulls) pr.number: pr};
    final nextState = RepositoryState(pulls.map((pr) => updated[pr.number] ?? pr).toList());
    final mutations = plan.changes.where((c) => c.mutates).toList();
    if (mutations.isNotEmpty) {
      for (final pr in open) {
        final now = PullRequest.fromApi(
          jsonObject(await api.request(installation, 'GET', '${repo.apiPath}/pulls/${pr.number}')),
          repo.id,
        );
        if (!now.isOpen || !now.sameRepo || now.head != pr.head || now.baseRef != pr.baseRef) {
          throw const RetryException('PR changed during restack; retrying');
        }
      }
      final operation = Operation(changes: mutations, nextState: nextState);
      store.save(id, RepositoryState(pulls), operation);
      await finishOperation(installation, repo, git, id, RepositoryState(pulls), operation);
    } else {
      store.save(id, nextState);
    }
    return store.load(id).state.pulls;
  }

  void _logRestackError(int installation, Repository repo, RestackException error) {
    stderr.writeln(
      jsonEncode({
        'event': 'restack_blocked',
        'installation': installation,
        'repository': repo.id,
        'pull': error.number,
        'reason': error.message,
      }),
    );
  }

  Future<void> finishOperation(
    int installation,
    Repository repo,
    GitRepository git,
    String id,
    RepositoryState oldState,
    Operation operation,
  ) async {
    final changes = operation.changes;
    if (changes.any((c) => c.headRef == repo.defaultBranch)) {
      throw const RestackException('対象ブランチがデフォルトブランチになったため停止しました。操作記録を確認してください。');
    }
    final path = repo.apiPath;
    final heads = await git.remoteHeads(changes.map((c) => c.headRef).toList());
    final updates = changes.where((c) => c.changesHead);
    final allOld = updates.every((c) => heads[c.headRef] == c.oldHead);
    final allNew = updates.every((c) => heads[c.headRef] == c.newHead);
    if (operation.phase == 'prepared' && allOld && !allNew) {
      for (final change in changes) {
        final pr = PullRequest.fromApi(
          jsonObject(await api.request(installation, 'GET', '$path/pulls/${change.number}')),
          repo.id,
        );
        if (!pr.isOpen ||
            !pr.sameRepo ||
            pr.head != change.oldHead ||
            ![change.oldBase, change.newBase].contains(pr.baseRef)) {
          store.save(id, oldState);
          throw const RetryException('PR changed before push; retrying');
        }
      }
      await git.push(changes);
      operation.phase = 'pushed';
      store.save(id, oldState, operation);
    } else if (!allNew) {
      if (operation.phase == 'prepared' && updates.every((c) => heads[c.headRef] != c.newHead)) {
        store.save(id, oldState);
        throw const RetryException('Branch changed before atomic push; retrying');
      }
      throw const RestackException('処理途中でリモートの履歴が変わりました。READMEの「処理の復旧」を確認してください。');
    }
    for (final change in changes) {
      final pr = PullRequest.fromApi(
        jsonObject(await api.request(installation, 'GET', '$path/pulls/${change.number}')),
        repo.id,
      );
      // GHES can briefly return the old PR head after Git has accepted our push.
      // Keep the journal so the worker can retry without pushing again.
      if (change.changesHead &&
          pr.isOpen &&
          pr.sameRepo &&
          pr.head == change.oldHead &&
          [change.oldBase, change.newBase].contains(pr.baseRef)) {
        throw const RetryException('Waiting for the PR API to reflect the pushed head; retrying');
      }
      if (!pr.isOpen ||
          !pr.sameRepo ||
          pr.head != change.newHead ||
          ![change.oldBase, change.newBase].contains(pr.baseRef)) {
        throw RestackException('push後にPRが変更されました。READMEの「処理の復旧」を確認してください。', number: change.number);
      }
      if (pr.baseRef != change.newBase) {
        await api.request(installation, 'PATCH', '$path/pulls/${change.number}', {
          'base': change.newBase,
        });
      }
    }
    store.save(id, operation.nextState);
  }
}
