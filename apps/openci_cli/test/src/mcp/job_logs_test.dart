import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_cli_plus/src/credential_store/credential_config.dart';
import 'package:openci_cli_plus/src/mcp/build_api.dart';
import 'package:openci_cli_plus/src/mcp/job_logs.dart';
import 'package:test/test.dart';

void main() {
  const profile = AuthProfile(
    firebaseProjectId: 'openci-b1b91',
    authType: 'firebase',
    token: 'user-id-token',
    teamId: 'team',
  );
  late Map<String, Object?> job;
  late Map<String, Object?> run;
  late List<Map<String, Object?>> entries;
  late List<String> calls;
  late BuildApi api;
  setUp(() {
    job = {
      'teamId': 'team',
      'workflowName': 'Flutter',
      'status': 'FAILURE',
      'latestRunId': 'run-two',
    };
    run = {
      'status': 'completed',
      'lastLogSequence': '2',
      'allSteps': [
        {'stepId': 'test', 'name': 'Tests', 'status': 'FAILURE'},
      ],
    };
    entries = [
      {
        'sequence': '1',
        'stepId': 'test',
        'stream': 'stdout',
        'message': 'a' * 4500,
      },
      {
        'sequence': '2',
        'stepId': 'test',
        'stream': 'stderr',
        'message': 'Error: expected 3 but got 2\n${'b' * 5000}',
      },
    ];
    calls = [];
    api = BuildApi(
      profile,
      MockClient((request) async {
        expect(request.headers['X-Firebase-Auth-Token'], profile.token);
        expect(request.url.host, 'firebasedataconnect.googleapis.com');
        expect(request.url.path, endsWith(':executeQuery'));
        expect(request.followRedirects, isFalse);
        final body = jsonDecode(request.body) as Map;
        final vars = body['variables'] as Map;
        final op = body['operationName'] as String;
        calls.add(op);
        final data = switch (op) {
          'GetBuildJob' => {'job': job},
          'GetBuildLogState'
              when vars['teamId'] == 'team' && vars['jobId'] == 'job' =>
            {'run': run},
          'GetBuildLogs' when vars['teamId'] == 'team' => {
            'run': {
              'logEntries': entries
                  .where(
                    (e) =>
                        int.parse(e['sequence'] as String) >
                        int.parse(vars['afterSequence'] as String),
                  )
                  .take(vars['limit'] as int)
                  .toList(),
            },
          },
          _ => throw StateError('Unexpected request'),
        };
        return http.Response.bytes(
          utf8.encode(jsonEncode({'data': data})),
          200,
        );
      }),
    );
  });
  test('keeps Unicode characters intact across log pages', () async {
    entries.first['message'] = '${'a' * 4095}🚀';
    final first = await getJobLogs(api, {
      'job_id': 'job',
      'run_id': 'run-two',
      'cursor': '1:0',
    });
    expect(first['next_cursor'], '1:4095');
    final next = await getJobLogs(api, {
      'job_id': 'job',
      'run_id': 'run-two',
      'cursor': first['next_cursor'],
    });
    expect((next['entries'] as List).first['text'], '🚀');
  });
  test(
    'focuses the initial excerpt and resumes the same run inside a long entry',
    () async {
      final first = await getJobLogs(api, {'job_id': 'job'});
      expect(first['dashboard_url'], 'https://dashboard.openci.org/runs/job');
      expect(first['failed_step'], {'id': 'test', 'name': 'Tests'});
      expect(first['first_cursor'], '1:0');
      final parts = (first['entries'] as List).cast<Map>();
      expect(parts.last['text'], startsWith('Error: expected 3'));
      expect(
        parts.fold<int>(0, (sum, p) => sum + (p['text'] as String).length),
        4096,
      );
      final rest = await getJobLogs(api, {
        'job_id': 'job',
        'run_id': first['run_id'],
        'cursor': first['next_cursor'],
      });
      expect(
        '${parts.last['text']}${(rest['entries'] as List).single['text']}',
        entries.last['message'],
      );
      expect(rest.containsKey('next_cursor'), isFalse);
    },
  );
  test(
    'a queued retry only reads historical logs when the run is explicit',
    () async {
      job['status'] = 'QUEUED';
      expect(
        (await getJobLogs(api, {'job_id': 'job'}))['log_status'],
        'no_run',
      );
      expect(calls, ['GetBuildJob']);
      expect(
        (await getJobLogs(api, {
          'job_id': 'job',
          'run_id': 'run-two',
        }))['run_id'],
        'run-two',
      );
    },
  );
  test(
    'limits reads to the selected team even for multi-team members',
    () async {
      job['teamId'] = 'other';
      await expectLater(
        getJobLogs(api, {'job_id': 'job'}),
        throwsA(isA<BuildReadException>()),
      );
      expect(calls, ['GetBuildJob']);
    },
  );
  test('reports expiry without requesting deleted pages', () async {
    run['logsExpireAt'] = '2000-01-01T00:00:00Z';
    expect((await getJobLogs(api, {'job_id': 'job'}))['log_status'], 'expired');
    expect(calls, ['GetBuildJob', 'GetBuildLogState']);
  });
  test(
    'rejects partial GraphQL results and keeps private error details out of MCP',
    () async {
      final denied = BuildApi(
        profile,
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'data': {'job': job},
              'errors': [
                {'message': 'Team access denied: private detail'},
              ],
            }),
            200,
          ),
        ),
      );
      await expectLater(
        getJobLogs(denied, {'job_id': 'job'}),
        throwsA(
          isA<BuildReadException>().having(
            (e) => e.message,
            'message',
            'Access denied for the active OpenCI team.',
          ),
        ),
      );
    },
  );
}
