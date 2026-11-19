import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_dart_functions/src/github_workflows.dart';
import 'package:openci_dart_functions/src/planning_event.dart';
import 'package:test/test.dart';

final commitSha = 'a' * 40;
final tagSha = 'b' * 40;
final nestedTagSha = 'c' * 40;

PlanningEvent releaseEvent() => PlanningEvent.parse(
  'release',
  jsonEncode({
    'action': 'published',
    'installation': {'id': 30},
    'repository': {
      'id': 10,
      'name': 'app',
      'owner': {'id': 20, 'login': 'org'},
    },
    'release': {
      'id': 40,
      'tag_name': 'mobile/v1.2.0+41',
      'draft': false,
      'target_commitish': 'moving-main',
    },
  }),
)!;

({GitHubWorkflows source, List<http.Request> requests}) fakeReleaseGitHub({
  String type = 'commit',
  String? sha,
  Map<String, Map<String, Object?>> tags = const {},
  int refStatus = 200,
  int repositoryId = 10,
  int ownerId = 20,
  int revokeStatus = 204,
  String ref = 'refs/tags/mobile/v1.2.0+41',
}) {
  final requests = <http.Request>[];
  final client = MockClient((request) async {
    requests.add(request);
    expect(request.url.origin, 'https://github.example.test');
    expect(request.followRedirects, isFalse);
    final path = Uri.decodeComponent(
      request.url.path,
    ).replaceFirst('/api/v3', '');
    Object? body;
    var status = 200;
    if (path == '/app/installations/30/access_tokens') {
      expect(request.method, 'POST');
      expect(jsonDecode(request.body), {
        'repository_ids': [10],
        'permissions': {'contents': 'read'},
      });
      body = {'token': 'release-test-token'};
    } else {
      expect(request.headers['authorization'], 'Bearer release-test-token');
      if (path == '/installation/token') {
        expect(request.method, 'DELETE');
        return http.Response('', revokeStatus);
      } else if (path == '/repos/org/app') {
        body = {
          'id': repositoryId,
          'owner': {'id': ownerId},
        };
      } else if (path == '/repos/org/app/git/ref/tags/mobile/v1.2.0+41') {
        body = {
          'ref': ref,
          'object': {'type': type, 'sha': sha ?? commitSha},
        };
        status = refStatus;
      } else if (path.startsWith('/repos/org/app/git/tags/')) {
        final requestedSha = path.split('/').last;
        body = {'sha': requestedSha, 'object': tags[requestedSha]};
      } else if (path == '/repos/org/app/git/commits/$commitSha') {
        body = {'sha': commitSha};
      } else if (path == '/repos/org/app/contents/openci') {
        expect(request.url.queryParameters, {'ref': commitSha});
        body = [
          {'name': 'cd.dart', 'type': 'file', 'size': 80},
        ];
      } else if (path == '/repos/org/app/contents/openci/cd.dart') {
        expect(request.url.queryParameters, {'ref': commitSha});
        body = {
          'type': 'file',
          'encoding': 'base64',
          'content': base64Encode(utf8.encode('void main() {}')),
        };
      } else {
        fail('Unexpected GitHub path: $path');
      }
    }
    return http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );
  });
  return (
    source: GitHubWorkflows(
      client: client,
      apiBaseUrl: 'https://github.example.test/api/v3',
      appJwt: () => 'test-jwt',
    ),
    requests: requests,
  );
}

void main() {
  test(
    'lightweight release tags pin workflow reads to a commit on GHES',
    () async {
      final github = fakeReleaseGitHub();
      final event = releaseEvent();
      final sha = await github.source.resolveReleaseCommit(event);
      expect(sha, commitSha);
      expect(github.requests.last.method, 'DELETE');
      final files = await github.source.fetch(event.withReleaseCommit(sha));
      expect(files.single.name, 'cd.dart');
      expect(
        github.requests.any((r) => r.url.toString().contains('moving-main')),
        isFalse,
      );
    },
  );

  test(
    'annotated and nested tags resolve to the commit, not the tag object',
    () async {
      for (final nested in [false, true]) {
        final github = fakeReleaseGitHub(
          type: 'tag',
          sha: tagSha,
          tags: {
            tagSha: {
              'type': nested ? 'tag' : 'commit',
              'sha': nested ? nestedTagSha : commitSha,
            },
            if (nested) nestedTagSha: {'type': 'commit', 'sha': commitSha},
          },
        );
        expect(
          await github.source.resolveReleaseCommit(releaseEvent()),
          commitSha,
        );
        expect(github.requests.last.method, 'DELETE');
      }
    },
  );

  test(
    'tag lookup failures remain retryable and revoke the scoped token',
    () async {
      for (final status in [403, 404, 503]) {
        final github = fakeReleaseGitHub(refStatus: status);
        await expectLater(
          github.source.resolveReleaseCommit(releaseEvent()),
          throwsStateError,
        );
        expect(github.requests.last.method, 'DELETE');
      }
    },
  );

  test(
    'repository identity is checked before resolving a release tag',
    () async {
      for (final mismatch in [true, false]) {
        final github = fakeReleaseGitHub(
          repositoryId: mismatch ? 99 : 10,
          ownerId: mismatch ? 20 : 99,
        );
        await expectLater(
          github.source.resolveReleaseCommit(releaseEvent()),
          throwsA(isA<InvalidPlanningInput>()),
        );
        expect(github.requests, hasLength(3));
        expect(github.requests.last.method, 'DELETE');
      }
    },
  );

  test('only the exact tag reference is accepted', () async {
    final github = fakeReleaseGitHub(ref: 'refs/heads/mobile/v1.2.0+41');
    await expectLater(
      github.source.resolveReleaseCommit(releaseEvent()),
      throwsStateError,
    );
    expect(github.requests.last.method, 'DELETE');
  });

  test('cycles, non-commit objects and invalid SHAs fail closed', () async {
    for (final github in [
      fakeReleaseGitHub(type: 'tree'),
      fakeReleaseGitHub(type: 'blob'),
      fakeReleaseGitHub(sha: 'main'),
      fakeReleaseGitHub(sha: '0' * 40),
      fakeReleaseGitHub(
        type: 'tag',
        sha: tagSha,
        tags: {
          tagSha: {'type': 'tag', 'sha': tagSha},
        },
      ),
    ]) {
      await expectLater(
        github.source.resolveReleaseCommit(releaseEvent()),
        throwsA(isA<InvalidPlanningInput>()),
      );
      expect(github.requests.last.method, 'DELETE');
    }
  });

  test('revocation failure does not return a successful resolution', () async {
    final github = fakeReleaseGitHub(revokeStatus: 503);
    await expectLater(
      github.source.resolveReleaseCommit(releaseEvent()),
      throwsStateError,
    );
  });
}
