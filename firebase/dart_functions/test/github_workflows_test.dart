import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_dart_functions/src/github_workflows.dart';
import 'package:openci_dart_functions/src/planning_event.dart';
import 'package:test/test.dart';

final sha = 'a' * 40;
final event = PlanningEvent.parse(
  'push',
  jsonEncode({
    'installation': {'id': 30},
    'repository': {
      'id': 10,
      'name': 'app',
      'owner': {'id': 20, 'login': 'org'},
    },
    'ref': 'refs/heads/develop',
    'after': sha,
  }),
)!;

({GitHubWorkflows source, List<http.Request> requests}) fakeGitHub({
  int directoryStatus = 200,
  int commitStatus = 200,
  int repositoryId = 10,
  int size = 20,
}) {
  final requests = <http.Request>[];
  final client = MockClient((request) async {
    requests.add(request);
    expect(request.url.origin, 'https://github.example.test');
    expect(request.followRedirects, isFalse);
    final path = request.url.path.replaceFirst('/api/v3', '');
    Object? body;
    var status = 200;
    if (path == '/app/installations/30/access_tokens') {
      expect(request.method, 'POST');
      expect(jsonDecode(request.body), {
        'repository_ids': [10],
        'permissions': {'contents': 'read'},
      });
      body = {'token': 'test-installation-token'};
    } else if (path == '/repos/org/app') {
      body = {
        'id': repositoryId,
        'owner': {'id': 20},
      };
    } else if (path == '/repos/org/app/git/commits/$sha') {
      status = commitStatus;
      body = {'sha': sha};
    } else if (path == '/repos/org/app/contents/openci') {
      expect(request.url.queryParameters, {'ref': sha});
      status = directoryStatus;
      body = [
        {'name': 'ci.dart', 'type': 'file', 'size': size},
        {'name': 'README.md', 'type': 'file', 'size': 10},
        {'name': 'nested.dart', 'type': 'dir', 'size': 0},
      ];
    } else if (path == '/repos/org/app/contents/openci/ci.dart') {
      expect(request.url.queryParameters, {'ref': sha});
      body = {
        'type': 'file',
        'encoding': 'base64',
        'content': '${base64Encode(utf8.encode('void main() {}'))}\n',
      };
    } else {
      fail('Unexpected GitHub path: $path');
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
    'scopes the installation token and reads only top-level Dart files at the commit SHA',
    () async {
      final github = fakeGitHub();
      final files = await github.source.fetch(event);
      expect(files.single.name, 'ci.dart');
      expect(files.single.content, 'void main() {}');
      expect(github.requests, hasLength(5));
    },
  );
  test(
    'a missing directory is empty only after checking commit access',
    () async {
      final github = fakeGitHub(directoryStatus: 404);
      expect(await github.source.fetch(event), isEmpty);
      expect(github.requests, hasLength(4));
    },
  );
  test(
    'commit access failures are retryable rather than silently skipped',
    () async {
      final github = fakeGitHub(commitStatus: 403);
      await expectLater(github.source.fetch(event), throwsStateError);
      expect(github.requests, hasLength(3));
    },
  );
  test(
    'repository identity is verified before private source is fetched',
    () async {
      final github = fakeGitHub(repositoryId: 99);
      await expectLater(
        github.source.fetch(event),
        throwsA(isA<InvalidPlanningInput>()),
      );
      expect(github.requests, hasLength(2));
    },
  );
  test('oversized source is rejected before downloading it', () async {
    final github = fakeGitHub(size: 1024 * 1024 + 1);
    await expectLater(
      github.source.fetch(event),
      throwsA(isA<InvalidPlanningInput>()),
    );
    expect(github.requests, hasLength(4));
  });
}
