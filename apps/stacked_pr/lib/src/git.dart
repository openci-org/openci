import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'models.dart';
import 'deadline.dart';

class GitException implements Exception {
  const GitException(this.command, this.reason);
  final String command, reason;
  @override
  String toString() => 'Git $command failed ($reason)';
}

String assertSha(String sha) {
  if (!RegExp(r'^(?:[a-f0-9]{40}|[a-f0-9]{64})$').hasMatch(sha)) {
    throw ArgumentError('Invalid Git object ID');
  }
  return sha;
}

class GitRepository {
  GitRepository({
    required this.directory,
    required this.remote,
    this.token,
    this.allowLocal = false,
    this.deadline,
    Map<String, String>? environment,
  }) : environment = environment ?? Platform.environment {
    if (!allowLocal && !remote.startsWith('https://')) {
      throw ArgumentError('Git remote must use HTTPS');
    }
  }
  final String directory, remote;
  final Future<String> Function()? token;
  final bool allowLocal;
  final Deadline? deadline;
  final Map<String, String> environment;

  Future<({int code, String output})> run(
    List<String> args, {
    String? cwd,
    bool network = false,
    Set<int> accepted = const {0},
  }) async {
    final timeout = deadline?.limit(const Duration(seconds: 120)) ?? const Duration(seconds: 120);
    final environment = <String, String>{
      for (final name in [
        'PATH',
        'TMPDIR',
        'GIT_SSL_CAINFO',
        'HTTPS_PROXY',
        'NO_PROXY',
        'HTTP_PROXY',
        'https_proxy',
        'http_proxy',
        'no_proxy',
      ])
        if (this.environment[name] != null) name: this.environment[name]!,
      'LANG': 'C.UTF-8',
      'LC_ALL': 'C',
      'GIT_TERMINAL_PROMPT': '0',
      'GIT_CONFIG_NOSYSTEM': '1',
      'GIT_CONFIG_GLOBAL': '/dev/null',
      'GIT_AUTHOR_NAME': 'Stacked PR',
      'GIT_AUTHOR_EMAIL': 'stacked-pr@localhost',
      'GIT_COMMITTER_NAME': 'Stacked PR',
      'GIT_COMMITTER_EMAIL': 'stacked-pr@localhost',
    };
    if (network && token != null) {
      final value = await token!();
      if (value.isNotEmpty) {
        environment.addAll({
          'GIT_CONFIG_COUNT': '1',
          'GIT_CONFIG_KEY_0': 'http.extraHeader',
          'GIT_CONFIG_VALUE_0':
              'Authorization: Basic ${base64Encode(utf8.encode('x-access-token:$value'))}',
        });
      }
    }
    final Process process;
    try {
      process = await Process.start(
        'git',
        [
          '-c',
          'core.hooksPath=/dev/null',
          '-c',
          'credential.helper=',
          '-c',
          'http.followRedirects=false',
          '-c',
          'protocol.ext.allow=never',
          '-c',
          'protocol.file.allow=${allowLocal ? 'always' : 'never'}',
          '-c',
          'gc.auto=0',
          '-c',
          'maintenance.auto=false',
          '-c',
          'commit.gpgSign=false',
          ...args,
        ],
        workingDirectory: cwd ?? directory,
        environment: environment,
        includeParentEnvironment: false,
      );
    } on ProcessException {
      throw GitException(args.first, 'execution error');
    }
    final output = BytesBuilder(copy: false);
    final stdoutDone = process.stdout.forEach((chunk) {
      if (output.length + chunk.length > 8 * 1024 * 1024) {
        process.kill(ProcessSignal.sigkill);
        throw GitException(args.first, 'output limit exceeded');
      }
      output.add(chunk);
    });
    final stderrDone = process.stderr.drain<void>();
    try {
      final exit = process.exitCode;
      await Future.wait<void>([stdoutDone, stderrDone, exit.then((_) {})]).timeout(timeout);
      final code = await exit;
      if (!accepted.contains(code)) throw GitException(args.first, '$code');
      return (
        code: code,
        output: utf8.decode(output.takeBytes(), allowMalformed: true).trimRight(),
      );
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      await process.exitCode;
      throw GitException(args.first, 'timeout');
    }
  }

  Future<void> prepare({List<PullRequest> pulls = const [], List<String>? branches}) async {
    await Directory(directory).create(recursive: true);
    await run(['init', '--bare', '.']);
    final scratch = Directory(p.join(directory, 'scratch'));
    if (await scratch.exists()) await scratch.delete(recursive: true);
    await run(['worktree', 'prune']);
    for (final branch in branches ?? <String>[]) {
      await run(['check-ref-format', 'refs/heads/$branch']);
    }
    await run([
      'fetch',
      '--prune',
      '--no-tags',
      remote,
      if (branches == null)
        '+refs/heads/*:refs/remotes/origin/*'
      else
        ...branches.map((b) => '+refs/heads/$b:refs/remotes/origin/$b'),
    ], network: true);
    if (!allowLocal) {
      for (var start = 0; start < pulls.length; start += 50) {
        final refs = pulls.skip(start).take(50).map((pr) {
          if (pr.number <= 0) throw ArgumentError('Invalid PR number');
          return '+refs/pull/${pr.number}/head:refs/pull/${pr.number}/head';
        });
        await run(['fetch', '--no-tags', remote, ...refs], network: true);
      }
    }
  }

  Future<String> branch(String ref) async {
    await run(['check-ref-format', 'refs/heads/$ref']);
    return assertSha(
      (await run(['rev-parse', '--verify', 'refs/remotes/origin/$ref^{commit}'])).output,
    );
  }

  Future<bool> has(String sha) async =>
      (await run(['cat-file', '-e', '${assertSha(sha)}^{commit}'], accepted: {0, 1, 128})).code ==
      0;
  Future<void> ensure(String sha) async {
    if (!await has(sha)) await run(['fetch', '--no-tags', remote, assertSha(sha)], network: true);
    await pin(sha);
  }

  Future<void> pin(String sha) async {
    await run(['update-ref', 'refs/stacked-pr/keep/${assertSha(sha)}', sha]);
  }

  Future<bool> ancestor(String base, String head) async =>
      (await run(
        ['merge-base', '--is-ancestor', assertSha(base), assertSha(head)],
        accepted: {0, 1},
      )).code ==
      0;

  Future<String?> mergeBase(String left, String right) async {
    final result = await run(
      ['merge-base', '--all', assertSha(left), assertSha(right)],
      accepted: {0, 1},
    );
    final bases = result.output.split('\n').where((s) => s.isNotEmpty).toList();
    return bases.length == 1 ? assertSha(bases.single) : null;
  }

  Future<String?> findMergedBoundary({
    required String head,
    required String target,
    required List<String> mergeCommits,
  }) async {
    if (mergeCommits.isEmpty) return null;
    for (final sha in [head, target, ...mergeCommits]) {
      await ensure(sha);
    }
    for (final mergeCommit in mergeCommits) {
      if (!await ancestor(mergeCommit, head) || !await ancestor(mergeCommit, target)) return null;
    }
    // Main may have advanced both before and after the manual restack.
    final result = await run(['merge-base', '--all', head, target], accepted: {0, 1});
    if (result.code != 0 || result.output.isEmpty) return null;
    final bases = result.output.split('\n');
    return bases.length == 1 ? assertSha(bases.single) : null;
  }

  Future<String> rebase({
    required int number,
    required String head,
    required String boundary,
    required String target,
  }) async {
    for (final sha in [head, boundary, target]) {
      await ensure(sha);
    }
    if (head == target) throw RestackException('子PR固有の変更がありません。手動でPRを確認してください。', number: number);
    if (await ancestor(target, head)) return head;
    if (!await ancestor(boundary, head)) {
      throw RestackException(
        '確認した変更境界が現在のブランチにありません。手元でrestackしてから /stack sync を実行してください。',
        number: number,
      );
    }
    if ((await run(['rev-list', '--merges', '$boundary..$head'])).output.isNotEmpty) {
      throw RestackException('子PR固有の履歴にmerge commitがあります。直線的な履歴にしてください。', number: number);
    }
    final scratch = await Directory(p.join(directory, 'scratch')).create(recursive: true);
    final worktree = await scratch.createTemp('rebase-');
    await run(['worktree', 'add', '--detach', worktree.path, head]);
    try {
      final result = await run(
        [
          'rebase',
          '--no-autostash',
          '--no-update-refs',
          '--reapply-cherry-picks',
          '--empty=keep',
          '--onto',
          target,
          boundary,
        ],
        cwd: worktree.path,
        accepted: {0, 1},
      );
      if (result.code != 0) {
        final files = (await run([
          'diff',
          '--name-only',
          '--diff-filter=U',
          '-z',
        ], cwd: worktree.path)).output.split('\x00').where((f) => f.isNotEmpty).toList();
        throw RestackException('rebaseで競合しました。この処理ではブランチを更新していません。', number: number, files: files);
      }
      final sha = assertSha((await run(['rev-parse', 'HEAD'], cwd: worktree.path)).output);
      if (sha == target) throw RestackException('子PRの変更が空になります。手動で確認してください。', number: number);
      await pin(sha);
      return sha;
    } finally {
      await run(['worktree', 'remove', '--force', worktree.path]);
    }
  }

  Future<Map<String, String>> remoteHeads(List<String> refs) async {
    for (final ref in refs) {
      await run(['check-ref-format', 'refs/heads/$ref']);
    }
    if (refs.isEmpty) return {};
    final result = await run([
      'ls-remote',
      '--heads',
      remote,
      ...refs.map((r) => 'refs/heads/$r'),
    ], network: true);
    return {
      for (final line in result.output.split('\n').where((l) => l.isNotEmpty))
        line.split('\t')[1].replaceFirst('refs/heads/', ''): line.split('\t')[0],
    };
  }

  Future<void> push(List<BranchChange> changes) async {
    final updates = changes.where((c) => c.changesHead).toList();
    if (updates.isEmpty) return;
    for (final c in updates) {
      await run(['check-ref-format', 'refs/heads/${c.headRef}']);
      assertSha(c.oldHead);
      assertSha(c.newHead);
    }
    // Atomic push plus explicit expected SHAs: never overwrite a concurrent user push.
    await run([
      'push',
      '--atomic',
      ...updates.map((c) => '--force-with-lease=refs/heads/${c.headRef}:${c.oldHead}'),
      remote,
      ...updates.map((c) => '${c.newHead}:refs/heads/${c.headRef}'),
    ], network: true);
  }
}
