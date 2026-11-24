import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_cli_plus/src/credential_store/credential_config.dart';
import 'package:openci_cli_plus/src/mcp/build_api.dart';
import 'package:openci_cli_plus/src/mcp/find_jobs.dart';
import 'package:test/test.dart';

const profile = AuthProfile(
  authType: 'firebase',
  firebaseProjectId: 'openci-b1b91',
  teamId: 'team',
  token: 'test-token',
);
final sha = 'a' * 40;
const pr = 'https://github.com/Org/App/pull/7';

http.Response response(Map body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

BuildApi apiWith(http.Response Function(String, Map) handler) => BuildApi(
  profile,
  MockClient((request) async {
    final body = jsonDecode(request.body) as Map;
    return handler(body['operationName'] as String, body['variables'] as Map);
  }),
);

http.Response unavailable() => response({
  'error': {
    'status': 'NOT_FOUND',
    'message': 'operation "FindBuildJobs" not found',
  },
}, 404);

Map<String, Object?> teamJob(int id) => {
  'id': 'job-$id',
  'teamId': 'team',
  'owner': 'org',
  'repo': 'APP',
  'commitSha': sha,
  'pullRequestNumber': '7',
  'workflowName': 'Tests',
  'status': 'FAILURE',
  'latestRunId': 'stored-$id',
  'retryCount': 0,
};

void main() {
  test('filters by PR and revision and preserves stored retry IDs', () async {
    final attempts = [
      {'run_id': 'second', 'status': 'completed', 'conclusion': 'failure'},
      {'run_id': 'first', 'status': 'completed', 'conclusion': 'failure'},
    ];
    final api = apiWith((operation, vars) {
      expect(operation, 'FindBuildJobs');
      expect(vars, {
        'teamId': 'team',
        'githubBaseUrl': 'https://ghe.example.com/orgs',
        'owner': 'Org',
        'repo': 'App',
        'pullRequestNumber': '7',
        'commitSha': sha,
        'offset': 20,
        'limit': 21,
      });
      return response({
        'data': {
          'jobs': List.generate(
            21,
            (i) => {
              'job_id': 'id-$i',
              'workflow': 'Tests',
              'status': 'FAILURE',
              'commit_sha': sha,
              'retry_count': 1,
              'recent_runs': attempts,
              'latest_run_id': 'second',
              'matrix_label': 'iOS',
            },
          ),
        },
      });
    });
    final found = await findJobs(api, {
      'pr_url': 'https://ghe.example.com/orgs/Org/App/pull/7/files?x=1',
      'commit_sha': sha.toUpperCase(),
      'cursor': 'jobs:20',
    });
    final jobs = found['jobs'] as List;
    expect(jobs, hasLength(20));
    expect(found['next_cursor'], 'jobs:40');
    expect(jobs.first, {
      'job_id': 'id-0',
      'workflow': 'Tests',
      'status': 'FAILURE',
      'commit_sha': sha,
      'matrix_label': 'iOS',
      'latest_run_id': 'second',
      'retry_count': 1,
      'recent_runs': attempts,
    });
  });

  test(
    'commit-only search accepts owner/repo or an enterprise repository URL',
    () async {
      for (final (repo, base) in [
        ('Org/App', 'https://github.com'),
        (
          'https://ghe.example.com:8443/Org/App.git',
          'https://ghe.example.com:8443',
        ),
      ]) {
        final api = apiWith((operation, vars) {
          expect(vars['githubBaseUrl'], base);
          expect(vars['repo'], 'App');
          expect(vars.containsKey('pullRequestNumber'), isFalse);
          expect(vars['commitSha'], sha);
          return response({
            'data': {'jobs': []},
          });
        });
        expect(await findJobs(api, {'repository': repo, 'commit_sha': sha}), {
          'jobs': [],
        });
      }
    },
  );

  test(
    'a missing operation scans one bounded team page and can resume after an empty result',
    () async {
      final others = List.generate(
        200,
        (i) => {...teamJob(i), 'pullRequestNumber': '9'},
      );
      final pages = [
        ...others,
        {...teamJob(200), 'githubBaseUrl': 'https://ghe.example.com'},
        {...teamJob(201), 'commitSha': 'b' * 40},
        {...teamJob(202), 'teamId': 'other'},
        teamJob(203),
      ];
      final calls = <String>[];
      final api = apiWith((op, vars) {
        calls.add(op);
        if (op == 'FindBuildJobs') return unavailable();
        expect(vars['teamId'], 'team');
        expect(vars['limit'], 200);
        return response({
          'data': {
            'buildJobs': pages.skip(vars['offset'] as int).take(200).toList(),
          },
        });
      });
      final args = {'pr_url': pr, 'commit_sha': sha};
      final first = await findJobs(api, args);
      expect(first, {'jobs': [], 'next_cursor': 'team:200'});
      final second = await findJobs(api, {
        ...args,
        'cursor': first['next_cursor'],
      });
      expect(second.containsKey('next_cursor'), isFalse);
      final only = (second['jobs'] as List).single as Map;
      expect(only['job_id'], 'job-203');
      expect(only['latest_run_id'], 'stored-203');
      expect(only.containsKey('recent_runs'), isFalse);
      expect(calls, ['FindBuildJobs', 'GetBuildJobs', 'GetBuildJobs']);
    },
  );

  test('a full result resumes at the first unread team row', () async {
    final pages = List.generate(24, teamJob);
    final api = apiWith(
      (op, vars) => response({
        'data': {'buildJobs': pages.skip(vars['offset'] as int).toList()},
      }),
    );
    final first = await findJobs(api, {'pr_url': pr, 'cursor': 'team:0'});
    expect((first['jobs'] as List).length, 20);
    final rest = await findJobs(api, {
      'pr_url': pr,
      'cursor': first['next_cursor'],
    });
    expect((rest['jobs'] as List).map((j) => j['job_id']), [
      'job-20',
      'job-21',
      'job-22',
      'job-23',
    ]);
  });

  test('authorization errors and unrelated 404s never fall back', () async {
    for (final error in [
      response({
        'error': {'status': 'NOT_FOUND', 'message': 'connector not found'},
      }, 404),
      response({
        'error': {'message': 'permission denied'},
      }, 403),
      response({
        'data': {'jobs': []},
        'errors': [
          {'message': 'Team access denied'},
        ],
      }),
    ]) {
      final calls = <String>[];
      final api = apiWith((op, _) {
        calls.add(op);
        return error;
      });
      await expectLater(
        findJobs(api, {'pr_url': pr}),
        throwsA(isA<BuildReadException>()),
      );
      expect(calls, ['FindBuildJobs']);
    }
  });

  test(
    'rejects ambiguous and invalid search input before an API request',
    () async {
      final api = apiWith((_, _) => throw StateError('unexpected request'));
      for (final args in [
        <String, Object?>{},
        {'repository': 'Org/App'},
        {'commit_sha': sha},
        {'pr_url': pr, 'repository': 'Org/App'},
        {'pr_url': 'https://github.com/Org/App/pull/-7'},
        {'pr_url': 'http://github.com/Org/App/pull/7'},
        {'pr_url': 'https://user:password@github.com/Org/App/pull/7'},
      ]) {
        await expectLater(
          findJobs(api, args),
          throwsA(isA<BuildReadException>()),
        );
      }
    },
  );
}
