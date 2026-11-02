import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openci_dart_functions/src/github_changed_files.dart';
import 'package:openci_dart_functions/src/planning_event.dart';
import 'package:test/test.dart';

final head = 'a' * 40;
final base = 'b' * 40;

PlanningEvent event({
  bool pr = true,
  Map<String, Object?> changes = const {},
}) => PlanningEvent.parse(
  pr ? 'pull_request' : 'push',
  jsonEncode({
    'installation': {'id': 30},
    'repository': {
      'id': 10,
      'name': 'app',
      'owner': {'id': 20, 'login': 'org'},
    },
    'action': 'synchronize',
    'number': 42,
    'pull_request': {
      'head': {
        'sha': head,
        'ref': 'feature',
        'repo': {'id': 10},
      },
      'base': {
        'sha': base,
        'ref': 'stack-parent',
        'repo': {'id': 10},
      },
      'title': 'PR',
    },
    'ref': 'refs/heads/develop',
    'after': head,
    'before': base,
    ...changes,
  }),
)!;

class Fixture {
  List<Object?> files = [
    {
      'filename': 'apps/new/file.dart',
      'previous_filename': 'apps/old/file.dart',
      'status': 'renamed',
    },
    {'filename': 'deleted.dart', 'status': 'removed'},
  ];
  int? total;
  int metadataCalls = 0;
  int fileCalls = 0;
  int status = 200;
  Map<String, String> headers = {};
  Object? failure;
  bool race = false;
  bool foreign = false;
  bool duplicatePage = false;
  bool diverged = false;

  Future<http.Response> request(String path, Map<String, String>? query) async {
    if (failure != null) throw failure!;
    if (status != 200) return http.Response('{}', status, headers: headers);
    Object? body;
    if (path.endsWith('/pulls/42')) {
      metadataCalls++;
      body = {
        'number': 42,
        'head': {
          'sha': race && metadataCalls > 1 ? 'c' * 40 : head,
          'repo': {'id': foreign ? 99 : 10},
        },
        'base': {
          'sha': base,
          'repo': {'id': 10},
        },
        'changed_files': total ?? files.length,
      };
    } else if (path.endsWith('/files')) {
      fileCalls++;
      expect(query!['per_page'], '100');
      final offset = duplicatePage ? 0 : (int.parse(query['page']!) - 1) * 100;
      body = files.skip(offset).take(100).toList();
    } else if (path.contains('/compare/')) {
      expect(path, 'repos/org/app/compare/$base...$head');
      expect(query, {'per_page': '1'});
      body = {
        'base_commit': {'sha': base},
        'merge_base_commit': {'sha': diverged ? 'c' * 40 : base},
        'status': diverged ? 'diverged' : 'ahead',
        'files': files,
      };
    } else {
      fail('Unexpected GitHub request');
    }
    return http.Response(jsonEncode(body), 200);
  }

  Future<void> incomplete(String reason, {PlanningEvent? input}) async {
    final result = await GitHubChangedFiles(request).fetch(input ?? event());
    expect(result.isComplete, isFalse);
    expect(result.paths, isEmpty);
    expect(result.reason, reason);
  }
}

void main() {
  test(
    'PR diff includes deletions and both rename paths, not only the last commit',
    () async {
      final fixture = Fixture();
      final result = await GitHubChangedFiles(fixture.request).fetch(event());
      expect(result.isComplete, isTrue);
      expect(result.baseSha, base);
      expect(result.headSha, head);
      expect(result.paths, [
        'apps/new/file.dart',
        'apps/old/file.dart',
        'deleted.dart',
      ]);
      expect(fixture.metadataCalls, 2);
    },
  );

  test(
    'paginates all files and verifies the PR revision again afterward',
    () async {
      final fixture = Fixture()
        ..files = List.generate(101, (i) => {'filename': 'files/$i.txt'});
      final result = await GitHubChangedFiles(fixture.request).fetch(event());
      expect(result.isComplete, isTrue);
      expect(result.paths, hasLength(101));
      expect(fixture.fileCalls, 2);
    },
  );

  test('accepts a verified empty PR diff', () async {
    final fixture = Fixture()..files = [];
    final result = await GitHubChangedFiles(fixture.request).fetch(event());
    expect(result.isComplete, isTrue);
    expect(result.paths, isEmpty);
    expect(fixture.metadataCalls, 2);
    expect(fixture.fileCalls, 0);
  });

  test('detects an update during pagination', () async {
    await (Fixture()..race = true).incomplete('pr_revision_changed');
  });
  test('rejects a PR from a different repository', () async {
    final fixture = Fixture()..foreign = true;
    await expectLater(
      GitHubChangedFiles(fixture.request).fetch(event()),
      throwsA(isA<InvalidPlanningInput>()),
    );
  });
  test('does not trust a capped PR file list', () async {
    final fixture = Fixture()..total = 3000;
    await fixture.incomplete('github_file_limit');
    expect(fixture.fileCalls, 0);
  });
  test('does not trust a short page', () async {
    await (Fixture()..total = 10).incomplete('incomplete_file_list');
  });
  test('rejects duplicate pages even if the count is correct', () async {
    final fixture = Fixture()
      ..files = List.generate(200, (i) => {'filename': 'files/$i.txt'})
      ..duplicatePage = true;
    await fixture.incomplete('incomplete_file_list');
  });
  test('rejects a rename without its previous path', () async {
    await (Fixture()
          ..files = [
            {'filename': 'new', 'status': 'renamed'},
          ])
        .incomplete('invalid_github_response');
  });
  test('push compares the immutable before and after SHAs', () async {
    final fixture = Fixture();
    final result = await GitHubChangedFiles(
      fixture.request,
    ).fetch(event(pr: false));
    expect(result.isComplete, isTrue);
    expect(result.paths, contains('apps/old/file.dart'));
  });
  test(
    'push comparison at the 300-file cap cannot authorize skipping',
    () async {
      final fixture = Fixture()
        ..files = List.generate(300, (i) => {'filename': 'files/$i.txt'});
      await fixture.incomplete('github_file_limit', input: event(pr: false));
    },
  );
  test(
    'divergent pushes cannot use a merge-base diff as a tree diff',
    () async {
      await (Fixture()..diverged = true).incomplete(
        'non_linear_push',
        input: event(pr: false),
      );
    },
  );
  test('new branches and force pushes run without filtering', () async {
    await Fixture().incomplete(
      'new_branch',
      input: event(pr: false, changes: {'before': '0' * 40}),
    );
    await Fixture().incomplete(
      'force_push',
      input: event(pr: false, changes: {'forced': true}),
    );
  });
  for (final status in [429, 500, 502, 503]) {
    test('transient HTTP $status runs without filtering', () async {
      await (Fixture()..status = status).incomplete(
        status == 429 ? 'github_rate_limited' : 'github_unavailable',
      );
    });
  }
  test('rate-limited 403 is distinguished from a permission failure', () async {
    await (Fixture()
          ..status = 403
          ..headers = {'x-ratelimit-remaining': '0'})
        .incomplete('github_rate_limited');
    for (final status in [401, 403, 404]) {
      final fixture = Fixture()..status = status;
      await expectLater(
        GitHubChangedFiles(fixture.request).fetch(event()),
        throwsStateError,
      );
    }
  });
  test(
    'timeout and transport failures are explicit incomplete results',
    () async {
      await (Fixture()..failure = TimeoutException('private')).incomplete(
        'github_timeout',
      );
      await (Fixture()..failure = http.ClientException('private')).incomplete(
        'github_transport_error',
      );
    },
  );
  test('an unavailable old push revision is indeterminate', () async {
    await (Fixture()..status = 404).incomplete(
      'comparison_unavailable',
      input: event(pr: false),
    );
  });
}
