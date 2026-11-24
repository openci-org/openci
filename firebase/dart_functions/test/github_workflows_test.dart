import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_dart_functions/src/github_workflows.dart';
import 'package:openci_dart_functions/src/planning_event.dart';
import 'package:test/test.dart';

final sha = 'a' * 40;
final rootTree = 'b' * 40;
final workflowTree = 'c' * 40;
final dashboardTree = 'd' * 40;

Map<String, Object> blob(String path, [int size = 20]) => {
  'path': path,
  'type': 'blob',
  'mode': '100644',
  'size': size,
};
Map<String, Object> folder(String path, String sha) => {
  'path': path,
  'type': 'tree',
  'mode': '040000',
  'sha': sha,
};
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
  bool hasDirectory = true,
  bool truncated = false,
  int extraFiles = 0,
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
      body = {
        'sha': sha,
        'tree': {'sha': rootTree},
      };
    } else if (path == '/repos/org/app/git/trees/$rootTree') {
      expect(request.url.queryParameters, isEmpty);
      body = {
        'tree': [if (hasDirectory) folder('openci', workflowTree)],
        'truncated': false,
      };
    } else if (path == '/repos/org/app/git/trees/$workflowTree') {
      final recursive = request.url.queryParameters['recursive'] == '1';
      body = {
        'truncated': recursive && truncated,
        'tree': [
          blob('ci.dart', size),
          folder('dashboard', dashboardTree),
          if (recursive && !truncated) blob('dashboard/ios/ci.dart'),
          for (var i = 0; i < extraFiles; i++) blob('sdk/check_$i.dart'),
          blob('generated/paths.g.dart'),
          blob('lib/helper.dart'),
          blob('test/example_test.dart'),
          blob('tool/release.dart'),
          blob('.dart_tool/build/example.dart'),
          blob('README.md'),
          {...blob('link.dart'), 'mode': '120000'},
          {'path': 'dependency.dart', 'type': 'commit', 'mode': '160000'},
        ],
      };
    } else if (path == '/repos/org/app/git/trees/$dashboardTree') {
      expect(request.url.queryParameters, {'recursive': '1'});
      body = {
        'tree': [blob('ios/ci.dart')],
        'truncated': false,
      };
    } else if (path == '/repos/org/app/contents/openci/ci.dart' ||
        path == '/repos/org/app/contents/openci/dashboard/ios/ci.dart') {
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
  for (final truncated in [false, true]) {
    test(
      'reads root and nested Dart files at the commit SHA (truncated: $truncated)',
      () async {
        final github = fakeGitHub(truncated: truncated);
        final files = await github.source.fetch(event);
        expect(files.map((file) => file.path), [
          'openci/ci.dart',
          'openci/dashboard/ios/ci.dart',
        ]);
        expect(files.map((file) => file.name), everyElement('ci.dart'));
        expect(
          files.map((file) => file.content),
          everyElement('void main() {}'),
        );
        expect(
          github.requests.where((r) => r.url.path.contains('/contents/')),
          hasLength(2),
        );
      },
    );
  }
  test(
    'a missing workflow directory gives an empty plan after checking commit access',
    () async {
      final github = fakeGitHub(hasDirectory: false);
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
  test(
    'combined source size is bounded across directories before downloading it',
    () async {
      final github = fakeGitHub(size: 1024 * 1024);
      await expectLater(
        github.source.fetch(event),
        throwsA(isA<InvalidPlanningInput>()),
      );
      expect(
        github.requests.where((r) => r.url.path.contains('/contents/')),
        isEmpty,
      );
    },
  );
  test('file count is bounded across root and nested directories', () async {
    final github = fakeGitHub(extraFiles: 99);
    await expectLater(
      github.source.fetch(event),
      throwsA(isA<InvalidPlanningInput>()),
    );
    expect(
      github.requests.where((r) => r.url.path.contains('/contents/')),
      isEmpty,
    );
  });
}
