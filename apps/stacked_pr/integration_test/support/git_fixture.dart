import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:stacked_pr_app/src/git.dart';
import 'package:stacked_pr_app/src/models.dart';
import '../../test/support/fixtures.dart';

class GitFixture {
  GitFixture(this.root);
  final Directory root;
  String get author => p.join(root.path, 'author');
  String get remote => p.join(root.path, 'remote.git');
  late GitRepository worker;
  late String main, parent, child, grandchild;
  late List<PullRequest> pulls;

  static Future<GitFixture> create() async {
    final root = await Directory.systemTemp.createTemp('stacked-pr-git-');
    addTearDown(() => root.delete(recursive: true));
    final f = GitFixture(root);
    await Directory(f.author).create();
    await f.git(['init', '--bare', '--initial-branch=main', f.remote]);
    await f.git(['init', '--initial-branch=main']);
    f.main = await f.commit('base.txt', 'base\n', 'base');
    await f.git(['remote', 'add', 'origin', f.remote]);
    await f.git(['checkout', '-b', 'parent']);
    f.parent = await f.commit('parent.txt', 'parent\n', 'parent feature');
    await f.git(['checkout', '-b', 'child']);
    f.child = await f.commit('child.txt', 'child\n', 'child feature');
    await f.git(['checkout', '-b', 'grandchild']);
    f.grandchild = await f.commit('grandchild.txt', 'grandchild\n', 'grandchild feature');
    await f.git(['push', 'origin', 'main', 'parent', 'child', 'grandchild']);
    f.worker = GitRepository(
      directory: p.join(root.path, 'worker.git'),
      remote: f.remote,
      allowLocal: true,
    );
    await f.worker.prepare();
    f.pulls = [
      PullRequest(
        number: 1,
        title: 'Parent',
        head: f.parent,
        headRef: 'parent',
        base: f.main,
        baseRef: 'main',
      ),
      PullRequest(
        number: 2,
        title: 'Child',
        head: f.child,
        headRef: 'child',
        base: f.parent,
        baseRef: 'parent',
        parent: 1,
        boundary: f.parent,
      ),
      PullRequest(
        number: 3,
        title: 'Grandchild',
        head: f.grandchild,
        headRef: 'grandchild',
        base: f.child,
        baseRef: 'child',
        parent: 2,
        boundary: f.child,
      ),
    ];
    return f;
  }

  Future<String> git(List<String> args) async {
    final result = await Process.run(
      'git',
      [
        '-c',
        'core.hooksPath=/dev/null',
        '-c',
        'commit.gpgSign=false',
        '-c',
        'user.name=Test',
        '-c',
        'user.email=test@example.com',
        ...args,
      ],
      workingDirectory: author,
      environment: {'GIT_CONFIG_GLOBAL': '/dev/null', 'GIT_CONFIG_NOSYSTEM': '1'},
    );
    if (result.exitCode != 0) {
      throw StateError('Git fixture ${args.first} failed: ${result.stderr}');
    }
    return (result.stdout as String).trim();
  }

  Future<String> commit(String file, String text, String message) async {
    await File(p.join(author, file)).writeAsString(text);
    await git(['add', file]);
    await git(['commit', '-m', message]);
    return git(['rev-parse', 'HEAD']);
  }

  Future<String> squash({bool deleteParent = false}) async {
    await git(['checkout', 'main']);
    await git(['merge', '--squash', 'parent']);
    await git(['commit', '-m', 'squashed parent']);
    final sha = await git(['rev-parse', 'HEAD']);
    await git(['push', 'origin', 'main', if (deleteParent) ':parent']);
    pulls[0] = modify(pulls[0], {'state': 'closed', 'merged': true});
    await worker.prepare();
    return sha;
  }

  Future<String> advanceParent() async {
    await git(['checkout', 'parent']);
    final sha = await commit('new.txt', 'advance\n', 'advance parent');
    await git(['push', 'origin', 'parent']);
    pulls[0].head = sha;
    await worker.prepare();
    return sha;
  }

  Future<String> output(List<String> args) async => (await worker.run(args)).output;
}
