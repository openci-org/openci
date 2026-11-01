import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:stacked_pr_app/src/models.dart';
import 'package:stacked_pr_app/src/report.dart';
import '../support/fixtures.dart';
import '../support/mocks.mocks.dart';

void main() {
  group('stack-scoped errors', () {
    const conflict = RestackException('Conflict', number: 2, files: ['lib/conflict.dart']);
    const repo = Repository(id: 1, fullName: 'org/repo');
    late PullRequest unrelated;
    late List<PullRequest> pulls;
    late MockGitHubApi api;

    setUp(() {
      unrelated = modify(chain().first, {'number': 200, 'headRef': 'unrelated', 'head': 'd' * 40});
      pulls = [...chain(), unrelated];
      api = MockGitHubApi();
      when(api.identity()).thenAnswer((_) async => {'id': 7, 'slug': 'stacked-pr'});
      when(api.list(any, any, field: anyNamed('field'))).thenAnswer((_) async => []);
      when(api.request(any, any, any, any)).thenAnswer((_) async => null);
    });

    test('conflict fails the affected stack and leaves an unrelated PR successful', () {
      for (final pr in pulls.take(3)) {
        final view = render(pulls, pr, error: conflict);
        expect(view.conclusion, 'failure');
        expect(view.body, contains('Restack停止 · #2'));
        expect(view.body, contains('lib/conflict.dart'));
      }

      final unrelatedView = render(pulls, unrelated, error: conflict);
      expect(unrelatedView.conclusion, 'success');
      expect(unrelatedView.body, isNot(contains('Restack停止')));
      expect(unrelatedView.body, isNot(contains('lib/conflict.dart')));
    });

    test('unrelated stack keeps its parent dependency status', () {
      final child = modify(unrelated, {
        'number': 201,
        'headRef': 'unrelated-child',
        'head': 'e' * 40,
        'baseRef': unrelated.headRef,
        'base': unrelated.head,
        'parent': unrelated.number,
      });
      pulls.add(child);

      final view = render(pulls, child, error: conflict);
      expect(view.conclusion, 'action_required');
      expect(view.body, contains('依存先：#200'));
      expect(view.body, isNot(contains('Restack停止')));
    });

    test('errors without a PR number remain repository-wide failures', () {
      const error = RestackException('GitHub API unavailable');
      for (final pr in pulls) {
        final view = render(pulls, pr, error: error);
        expect(view.conclusion, 'failure');
        expect(view.body, contains(error.message));
      }
    });

    test('reporter does not create a comment or check for an unrelated standalone PR', () async {
      await Reporter(api).publish(1, repo, pulls, error: conflict);

      verifyNever(api.request(1, 'POST', '/repos/org/repo/issues/200/comments', any));
      verifyNever(
        api.list(
          1,
          '/repos/org/repo/commits/${unrelated.head}/check-runs?filter=all',
          field: 'check_runs',
        ),
      );
      final checks = verify(
        api.request(1, 'POST', '/repos/org/repo/check-runs', captureAny),
      ).captured.cast<Json>();
      expect(checks.map((check) => check['external_id']), [
        'stacked-pr:1:1',
        'stacked-pr:1:2',
        'stacked-pr:1:3',
      ]);
      expect(checks.map((check) => check['conclusion']), everyElement('failure'));
    });

    test(
      'reporter clears an unrelated stale failure and stays unchanged on the next sync',
      () async {
        final comment = <String, Object?>{
          'id': 100,
          'body': '$marker\nRestack停止 · #2：Conflict',
          'performed_via_github_app': {'id': 7},
        };
        final check = <String, Object?>{
          'id': 200,
          'external_id': 'stacked-pr:1:200',
          'app': {'id': 7},
          'conclusion': 'failure',
          'output': {'summary': comment['body']},
        };
        when(api.list(1, '/repos/org/repo/issues/200/comments')).thenAnswer((_) async => [comment]);
        when(
          api.list(
            1,
            '/repos/org/repo/commits/${unrelated.head}/check-runs?filter=all',
            field: 'check_runs',
          ),
        ).thenAnswer((_) async => [check]);
        when(api.request(1, 'PATCH', '/repos/org/repo/issues/comments/100', any)).thenAnswer((
          i,
        ) async {
          comment.addAll(i.positionalArguments[3] as Json);
          return null;
        });
        when(api.request(1, 'PATCH', '/repos/org/repo/check-runs/200', any)).thenAnswer((i) async {
          check.addAll(i.positionalArguments[3] as Json);
          return null;
        });

        final reporter = Reporter(api);
        await reporter.publish(1, repo, pulls, error: conflict);
        expect(comment['body'], isNot(contains('Restack停止')));
        expect(check['conclusion'], 'success');
        expect((check['output'] as Json)['summary'], comment['body']);
        verify(api.request(1, 'PATCH', '/repos/org/repo/issues/comments/100', any)).called(1);
        verify(api.request(1, 'PATCH', '/repos/org/repo/check-runs/200', any)).called(1);

        await reporter.publish(1, repo, pulls, error: conflict);
        verifyNever(api.request(1, 'PATCH', '/repos/org/repo/issues/comments/100', any));
        verifyNever(api.request(1, 'PATCH', '/repos/org/repo/check-runs/200', any));
      },
    );

    for (final error in [
      const RestackException('Standalone PR conflict', number: 200),
      const RestackException('GitHub API unavailable'),
    ]) {
      test('reporter still publishes a standalone failure for ${error.message}', () async {
        await Reporter(api).publish(1, repo, [unrelated], error: error);

        final comment =
            verify(
                  api.request(1, 'POST', '/repos/org/repo/issues/200/comments', captureAny),
                ).captured.single
                as Json;
        final check =
            verify(api.request(1, 'POST', '/repos/org/repo/check-runs', captureAny)).captured.single
                as Json;
        expect(comment['body'], contains(error.message));
        expect(check['conclusion'], 'failure');
        expect((check['output'] as Json)['summary'], comment['body']);
      });
    }
  });

  test('normal, observe and error reports all direct users to sync', () {
    final pulls = chain();
    final views = [
      render(pulls, pulls[1]),
      render(pulls, pulls[1], observeOnly: true),
      render(pulls, pulls[1], error: const RestackException('Conflict')),
    ];
    for (final view in views) {
      expect(RegExp(r'/stack \w+').allMatches(view.body).map((m) => m[0]).toSet(), {'/stack sync'});
    }
  });
  test('closed report updates the existing comment to Merged without creating a check', () async {
    final api = MockGitHubApi();
    final comment = <String, Object?>{
      'id': 100,
      'body': marker,
      'performed_via_github_app': {'id': 7},
    };
    when(api.identity()).thenAnswer((_) async => {'id': 7, 'slug': 'stacked-pr'});
    when(api.list(any, any, field: anyNamed('field'))).thenAnswer((_) async => [comment]);
    when(api.request(any, any, any, any)).thenAnswer((i) async {
      comment['body'] = (i.positionalArguments[3] as Json)['body'];
      return null;
    });
    final pulls = [
      modify(chain()[0], {'state': 'closed', 'merged': true}),
    ];
    final reporter = Reporter(api);
    const repo = Repository(id: 1, fullName: 'org/repo');
    await reporter.publish(1, repo, pulls, closedToUpdate: [1]);
    expect(comment['body'], contains('| Merged |'));
    verify(api.request(1, 'PATCH', '/repos/org/repo/issues/comments/100', any)).called(1);
    await reporter.publish(1, repo, pulls, closedToUpdate: [1]);
    verifyNever(api.request(any, any, any, any));
    verifyNever(api.list(any, any, field: 'check_runs'));
  });
  test('reporter reuses own comment and check and ignores forged marker', () async {
    final api = MockGitHubApi();
    final comments = <Json>[
      {
        'id': 99,
        'body': marker,
        'user': {'type': 'User', 'login': 'human'},
      },
    ];
    final checks = <Json>[], paths = <String>[];
    when(api.identity()).thenAnswer((_) async => {'id': 7, 'slug': 'stacked-pr'});
    when(api.list(any, any, field: anyNamed('field'))).thenAnswer(
      (i) async => (i.positionalArguments[1] as String).contains('check-runs') ? checks : comments,
    );
    when(api.request(any, any, any, any)).thenAnswer((i) async {
      final path = i.positionalArguments[2] as String, body = i.positionalArguments[3] as Json;
      paths.add(path);
      if (path.endsWith('/comments')) {
        comments.add({
          'id': 100,
          ...body,
          'user': {'type': 'Bot', 'login': 'stacked-pr[bot]'},
        });
      }
      if (path.endsWith('/check-runs')) {
        checks.add({
          'id': 200,
          ...body,
          'app': {'id': 7},
        });
      }
      return null;
    });
    final pulls = chain().take(2).toList();
    pulls[0] = modify(pulls[0], {'state': 'closed', 'merged': true, 'sameRepo': false});
    final reporter = Reporter(api);
    const repo = Repository(id: 1, fullName: 'org/repo');
    await reporter.publish(1, repo, pulls);
    expect(paths, hasLength(2));
    expect((checks.single['actions'] as List).single, {
      'label': 'Sync',
      'description': 'Synchronize dependent pull requests',
      'identifier': 'restack',
    });
    await reporter.publish(1, repo, pulls);
    expect(paths, hasLength(2));
    pulls[1] = modify(pulls[1], {'title': 'Changed title'});
    await reporter.publish(1, repo, pulls);
    expect(paths[2], '/repos/org/repo/issues/comments/100');
    expect(paths.any((p) => p.endsWith('/99')), isFalse);
  });
}
