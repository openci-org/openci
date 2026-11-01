import 'git.dart';
import 'github.dart';
import 'models.dart';

/// An invocation-local view. Nothing here survives a request or is written to GitHub.
class History {
  History(this.api, this.installation, this.repo);
  final GitHubApi api;
  final int installation;
  final Repository repo;
  final _timelines = <int, List<Json>>{};
  final _closed = <String, List<PullRequest>>{};
  final errors = <int, RestackException>{};

  Future<List<Json>> timeline(int number) async =>
      _timelines[number] ??= await api.timeline(installation, repo, number);

  Future<List<PullRequest>> closed(String branch) async => _closed[branch] ??= (await api.list(
    installation,
    '${repo.apiPath}/pulls?state=closed&head=${Uri.encodeQueryComponent('${repo.fullName.split('/').first}:$branch')}',
  )).map((p) => PullRequest.fromApi(p, repo.id)).where((p) => p.sameRepo && p.headRef == branch).toList();

  Future<List<PullRequest>> discover(List<PullRequest> current) async {
    final roots = current.where(
      (child) =>
          child.sameRepo &&
          !current.any(
            (parent) =>
                parent.isOpen &&
                parent.sameRepo &&
                parent.number != child.number &&
                parent.headRef == child.baseRef,
          ),
    );
    _timelines.addAll(await api.timelines(installation, repo, roots.map((p) => p.number).toList()));
    final pulls = {
      for (final p in current)
        p.number: p.copy()
          ..parent = null
          ..boundary = null,
    };
    final pending = pulls.values.toList();
    for (var i = 0; i < pending.length; i++) {
      final child = pending[i];
      if (!child.sameRepo) continue;
      try {
        final branch = child.baseRef;
        var candidates = pending
            .where((p) => p.sameRepo && p.isOpen && p.headRef == branch && p.number != child.number)
            .toList();
        if (branch == repo.defaultBranch) candidates = [];
        if (candidates.isEmpty && branch != repo.defaultBranch) {
          candidates = await closed(branch);
        }
        if (candidates.isEmpty) {
          final changes = (await timeline(child.number))
              .where(
                (e) =>
                    e['__typename'] == 'BaseRefChangedEvent' ||
                    e['__typename'] == 'AutomaticBaseChangeSucceededEvent',
              )
              .toList();
          // Follow only a contiguous chain ending at the current base. This
          // recovers B -> A -> main when both ancestors merged between tasks.
          var base = branch;
          for (final change in changes.reversed) {
            final automatic = change['__typename'] == 'AutomaticBaseChangeSucceededEvent';
            if ((automatic ? change['newBase'] : change['currentRefName']) != base) break;
            final previous = (automatic ? change['oldBase'] : change['previousRefName']) as String;
            final at = DateTime.parse(change['createdAt'] as String);
            final merged = (await closed(previous))
                .where(
                  (p) =>
                      p.merged &&
                      [base, branch].contains(p.baseRef) &&
                      p.mergedAt != null &&
                      !p.mergedAt!.isAfter(at.add(const Duration(seconds: 5))) &&
                      (child.createdAt == null || !p.mergedAt!.isBefore(child.createdAt!)),
                )
                .toList();
            if (merged.isEmpty) break;
            candidates = merged;
            if (merged.length > 1) break;
            base = previous;
          }
        }
        candidates = candidates.where((p) => p.number != child.number).toList();
        if (candidates.length > 1) {
          throw RestackException('親PRを一意に確認できません。baseブランチを確認してください。', number: child.number);
        }
        if (candidates.isEmpty) {
          // A non-default base may be a permanent release branch, not a stack.
          continue;
        }
        final parent = candidates.single;
        child.parent = parent.number;
        if (!pulls.containsKey(parent.number)) {
          pulls[parent.number] = parent;
          pending.add(parent);
        }
      } on RestackException catch (e) {
        errors[child.number] = e;
      }
    }
    return pulls.values.toList();
  }

  Future<String> boundary(GitRepository git, PullRequest parent, PullRequest child) async {
    await git.ensure(parent.head);
    if (await git.ancestor(parent.head, child.head)) return parent.head;
    final tips = <String>{parent.head};
    var incomplete = false;
    for (final event in await timeline(parent.number)) {
      if (event['__typename'] != 'HeadRefForcePushedEvent') continue;
      for (final field in ['beforeCommit', 'afterCommit']) {
        final commit = event[field];
        if (commit == null) {
          incomplete = true;
        } else {
          tips.add(jsonObject(commit)['oid'] as String);
        }
      }
    }
    final candidates = <String>{};
    // A common ancestor in main is not evidence of where the parent's own
    // changes ended. Never use that fallback after an unobserved history rewrite.
    final upstream = await git.branch(parent.baseRef);
    for (final tip in tips) {
      if (!await git.has(tip)) {
        try {
          await api.request(installation, 'GET', '${repo.apiPath}/git/commits/${assertSha(tip)}');
        } on ApiException catch (e) {
          if (e.status != 404) rethrow;
          incomplete = true;
          continue;
        }
        // Transport failures retry the task; they are not missing-history errors.
        await git.ensure(tip);
      }
      final base = await git.mergeBase(tip, child.head);
      if (base != null && !await git.ancestor(base, upstream)) candidates.add(base);
    }
    if (!incomplete && candidates.isNotEmpty) {
      final latest = <String>[];
      for (final candidate in candidates) {
        var superseded = false;
        for (final other in candidates) {
          if (candidate != other && await git.ancestor(candidate, other)) superseded = true;
        }
        if (!superseded) latest.add(candidate);
      }
      if (latest.length == 1) return latest.single;
    }
    throw RestackException(
      'GitHubの履歴から親子の変更境界を確定できません。手元でrestackしてから /stack sync を実行してください。',
      number: child.number,
    );
  }
}
