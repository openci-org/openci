import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'config.dart';
import 'deadline.dart';
import 'git.dart';
import 'github.dart';
import 'history.dart';
import 'models.dart';
import 'report.dart';
import 'stack.dart';

Json _object(Object? value) => value is Map ? jsonObject(value) : {};

class Service {
  Service({
    required this.config,
    required this.api,
    required this.reporter,
    this.enqueue,
    this.deadline,
    GitRepository Function(int, Repository)? gitFactory,
  }) : gitFactory =
           gitFactory ??
           ((installation, repo) => GitRepository(
             directory: p.join(config.dataDir, '$installation-${repo.id}.git'),
             remote: '${config.githubUrl}/${repo.fullName}.git',
             token: () => api.token(installation),
             deadline: deadline,
           ));

  final AppConfig config;
  final GitHubApi api;
  final Reporter reporter;
  final Future<bool> Function(Job)? enqueue;
  final Deadline? deadline;
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
    if (!await api.installationActive(installation)) return;
    if (['installation', 'installation_repositories'].contains(job.event)) {
      if (!['created', 'added', 'unsuspend'].contains(payload['action'])) return;
      final repos = await api.list(
        installation,
        '/installation/repositories',
        field: 'repositories',
      );
      for (final repo in repos.where(allowed)) {
        await enqueue!(
          Job(
            id: '${job.id}-${repo['id']}',
            event: 'reconcile',
            payload: {
              'installation': {'id': installation},
              'repository': {'id': repo['id'], 'full_name': repo['full_name']},
            },
          ),
        );
      }
      return;
    }
    final rawRepo = _object(payload['repository']);
    if (!allowed(rawRepo)) return;
    final repo = Repository.fromJson(rawRepo);
    var force = false;
    if (job.event == 'issue_comment') {
      final sender = _object(payload['sender']);
      if (_object(payload['issue'])['pull_request'] == null ||
          payload['action'] != 'created' ||
          sender['type'] == 'Bot' ||
          (_object(payload['comment'])['body'] as String?)?.trim() != '/stack sync' ||
          !await api.canWrite(installation, repo.apiPath, sender['login'] as String?)) {
        return;
      }
      force = true;
    }
    if (job.event == 'check_run') {
      if (payload['action'] != 'requested_action' ||
          _object(payload['requested_action'])['identifier'] != 'restack' ||
          _object(_object(payload['check_run'])['app'])['id'].toString() != config.appId ||
          !await api.canWrite(
            installation,
            repo.apiPath,
            _object(payload['sender'])['login'] as String?,
          )) {
        return;
      }
      force = true;
    }
    final number =
        _object(payload['pull_request'])['number'] as int? ??
        _object(payload['issue'])['number'] as int? ??
        int.tryParse(
          (_object(payload['check_run'])['external_id'] as String? ?? '').split(':').last,
        );
    if (job.event == 'check_run' &&
        (number == null ||
            number <= 0 ||
            _object(payload['check_run'])['external_id'] != 'stacked-pr:${repo.id}:$number')) {
      return;
    }
    if (job.event == 'reconcile' && number == null && enqueue != null) {
      final current = (await api.list(
        installation,
        '${repo.apiPath}/pulls?state=open',
      )).map((p) => PullRequest.fromApi(p, repo.id)).where((p) => p.sameRepo).toList();
      final scheduled = <int>{};
      for (final pr in current) {
        if (scheduled.contains(pr.number)) continue;
        final members = <int>{pr.number};
        var changed = true;
        while (changed) {
          changed = false;
          for (final child in current) {
            for (final parent in current.where((p) => p.headRef == child.baseRef)) {
              if (members.contains(child.number) || members.contains(parent.number)) {
                if (members.add(child.number)) changed = true;
                if (members.add(parent.number)) changed = true;
              }
            }
          }
        }
        scheduled.addAll(members);
        await enqueue!(
          Job(
            id: '${job.id}-${pr.number}',
            event: 'reconcile',
            payload: {
              'installation': {'id': installation},
              'repository': repo.toJson(),
              'pull_request': {'number': pr.number},
            },
          ),
        );
      }
      return;
    }
    final ref = payload['ref'] as String?;
    await reconcile(
      installation,
      repo,
      force: force,
      number: number,
      branch: job.event == 'push' && ref != null && ref.startsWith('refs/heads/')
          ? ref.substring('refs/heads/'.length)
          : null,
      previousBase: job.event == 'pull_request' && payload['action'] == 'edited'
          ? payload['previous_base'] as String?
          : null,
    );
  }

  Future<void> reconcile(
    int installation,
    Repository repo, {
    bool force = false,
    int? number,
    String? branch,
    String? previousBase,
  }) async {
    final metadata = jsonObject(await api.request(installation, 'GET', repo.apiPath));
    if (metadata['id'] != repo.id || metadata['default_branch'] is! String) {
      throw const RetryException('Repository identity changed');
    }
    repo = Repository(
      id: repo.id,
      fullName: repo.fullName,
      defaultBranch: metadata['default_branch'] as String,
    );
    final current = (await api.list(
      installation,
      '${repo.apiPath}/pulls?state=open',
    )).map((p) => PullRequest.fromApi(p, repo.id)).toList();
    if (number != null && !current.any((p) => p.number == number)) {
      current.add(
        PullRequest.fromApi(
          jsonObject(await api.request(installation, 'GET', '${repo.apiPath}/pulls/$number')),
          repo.id,
        ),
      );
    }
    if (current.isEmpty) return;
    if (branch == repo.defaultBranch && !current.any((p) => p.headRef == branch)) return;
    final history = History(api, installation, repo);
    final pulls = await history.discover(current);
    // Build components before validating cycles or rebase boundaries. A failed
    // component must neither block nor change the Checks of an unrelated stack.
    final components = <List<PullRequest>>[];
    final assigned = <int>{};
    for (final pr in pulls) {
      if (assigned.contains(pr.number)) continue;
      final numbers = <int>{pr.number};
      var changed = true;
      while (changed) {
        changed = false;
        for (final item in pulls) {
          if (item.parent != null &&
              (numbers.contains(item.number) || numbers.contains(item.parent))) {
            if (numbers.add(item.number)) changed = true;
            if (numbers.add(item.parent!)) changed = true;
          }
        }
      }
      assigned.addAll(numbers);
      components.add(pulls.where((p) => numbers.contains(p.number)).toList());
    }
    final selected = components
        .where(
          (component) =>
              (number == null && branch == null) ||
              component.any(
                (p) =>
                    p.number == number ||
                    (previousBase != null &&
                        previousBase != repo.defaultBranch &&
                        p.headRef == previousBase) ||
                    (branch != null &&
                        (p.headRef == branch ||
                            (branch != repo.defaultBranch && p.baseRef == branch))),
              ),
        )
        .toList();
    if (selected.isEmpty) return;
    final selectedPulls = selected.expand((p) => p).where((p) => p.sameRepo).toList();
    final enabled = force || config.autoRestack;
    final git = gitFactory(installation, repo);
    if (enabled && selectedPulls.any((p) => p.isOpen && p.parent != null)) {
      final deleted = selectedPulls.where((p) => !p.isOpen).map((p) => p.headRef).toSet();
      await git.prepare(
        pulls: selectedPulls,
        branches: {
          repo.defaultBranch!,
          ...selectedPulls.where((p) => p.isOpen).map((p) => p.headRef),
          ...selectedPulls.map((p) => p.baseRef).where((b) => !deleted.contains(b)),
        }.toList(),
      );
    }
    for (final component in selected) {
      var result = component;
      RestackException? error;
      try {
        for (final pr in component) {
          if (history.errors[pr.number] case final RestackException e) throw e;
        }
        ordered(component);
        if (enabled && component.any((p) => p.isOpen && p.parent != null)) {
          result = await _restack(installation, repo, git, history, component);
        }
      } on RestackException catch (e) {
        error = e;
        // A cycle error has no single PR number, but this list is already scoped.
        stderr.writeln(
          jsonEncode({'event': 'restack_blocked', 'repository': repo.id, 'pull': e.number}),
        );
      }
      await reporter.publish(
        installation,
        repo,
        result,
        error: error,
        observeOnly: !config.autoRestack,
        closedToUpdate: component.where((p) => !p.isOpen).map((p) => p.number).toList(),
      );
    }
  }

  Future<List<PullRequest>> _restack(
    int installation,
    Repository repo,
    GitRepository git,
    History history,
    List<PullRequest> pulls,
  ) async {
    final byNumber = {for (final pr in pulls) pr.number: pr};
    final open = pulls.where((p) => p.isOpen && p.sameRepo).toList();
    for (final child in open) {
      if (await git.branch(child.headRef) != child.head) {
        throw const RetryException('Branch changed during fetch');
      }
      if (child.parent == null) continue;
      if (child.headRef == repo.defaultBranch) {
        throw RestackException('デフォルトブランチは書き換えられません。', number: child.number);
      }
      final parent = byNumber[child.parent]!;
      if (!parent.isOpen && !parent.merged) {
        throw RestackException('親PRがmergeされずに閉じられています。依存先を確認してください。', number: child.number);
      }
      var ancestor = parent;
      final merged = <PullRequest>[];
      while (ancestor.merged) {
        merged.add(ancestor);
        final next = byNumber[ancestor.parent];
        if (next == null) break;
        ancestor = next;
      }
      final target = ancestor.merged ? await git.branch(ancestor.baseRef) : ancestor.head;
      await git.ensure(target);
      // Handles retries after a successful push, including a lost retarget response.
      if (await git.ancestor(target, child.head)) {
        child.boundary = target;
      } else if (merged.isNotEmpty && merged.every((p) => p.mergeCommit != null)) {
        child.boundary = await git.findMergedBoundary(
          head: child.head,
          target: target,
          mergeCommits: merged.map((p) => p.mergeCommit!).toList(),
        );
      }
      child.boundary ??= await history.boundary(git, parent, child);
    }
    final plan = await planRestack(pulls, git);
    final mutations = plan.changes.where((c) => c.mutates).toList();
    if (mutations.isEmpty) return plan.pulls;
    // Read current GitHub state immediately before mutating any branch.
    for (final before in pulls) {
      final now = PullRequest.fromApi(
        jsonObject(
          await api.request(installation, 'GET', '${repo.apiPath}/pulls/${before.number}'),
        ),
        repo.id,
      );
      if (now.head != before.head ||
          now.baseRef != before.baseRef ||
          now.state != before.state ||
          now.merged != before.merged ||
          !now.sameRepo) {
        throw const RetryException('PR changed during restack');
      }
    }
    await git.push(mutations);
    // No operation journal: on failure the next task fetches GitHub again.
    // Pushed children already include the new target, so they are not replayed.
    for (final change in mutations) {
      final now = PullRequest.fromApi(
        jsonObject(
          await api.request(installation, 'GET', '${repo.apiPath}/pulls/${change.number}'),
        ),
        repo.id,
      );
      if (!now.isOpen ||
          !now.sameRepo ||
          now.head != change.newHead ||
          ![change.oldBase, change.newBase].contains(now.baseRef)) {
        throw const RetryException('PR changed after push or GitHub is still updating');
      }
      if (now.baseRef != change.newBase) {
        await api.request(installation, 'PATCH', '${repo.apiPath}/pulls/${change.number}', {
          'base': change.newBase,
        });
      }
    }
    return plan.pulls;
  }
}
