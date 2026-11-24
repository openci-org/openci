import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_cli_plus/src/builds/builds_api.dart';
import 'package:openci_cli_plus/src/credential_store/credential_config.dart';
import 'package:openci_cli_plus/src/dataconnect/data_connect_api.dart';
import 'package:test/test.dart';

void main() {
  final token =
      'header.${base64Url.encode(utf8.encode(jsonEncode({'aud': 'openci-b1b91'}))).replaceAll('=', '')}.signature';
  final profile = AuthProfile(token: token, authType: 'firebase');

  test('listBuildJobs parses FSC Int64 strings and Unix timestamps', () async {
    late Map<String, dynamic> body;
    final api = BuildsApi(
      DataConnectApi(
        profile,
        client: MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'data': {
                'buildJobs': [
                  {
                    'id': 'job-1',
                    'teamId': 'team-1',
                    'status': 'FAILURE',
                    'owner': 'openci-org',
                    'repo': 'openci',
                    'workflowName': 'CLI CI',
                    'workflowFileName': 'cli_ci.dart',
                    'pullRequestNumber': '42',
                    'branch': 'feat/mcp',
                    'runCount': '2',
                    'retryCount': 1,
                    'latestRunId': 'run-2',
                    'createdAt': '1700000000',
                    'updatedAt': '1700000060',
                    'completedAt': '1700000120',
                    'failureSummary': 'Unit tests failed',
                  },
                ],
              },
            }),
            200,
          );
        }),
      ),
    );
    addTearDown(api.dispose);

    final jobs = await api.listBuildJobs(
      teamId: 'team-1',
      offset: 10,
      limit: 500,
    );

    expect(body['operationName'], 'GetBuildJobs');
    expect(body['variables'], {'teamId': 'team-1', 'offset': 10, 'limit': 200});
    expect(jobs, hasLength(1));
    expect(jobs.single.id, 'job-1');
    expect(jobs.single.pullRequestNumber, 42);
    expect(jobs.single.runCount, 2);
    expect(jobs.single.retryCount, 1);
    expect(jobs.single.createdAt, '2023-11-14T22:13:20.000Z');
    expect(jobs.single.completedAt, '2023-11-14T22:15:20.000Z');
    expect(jobs.single.failureSummary, 'Unit tests failed');
  });

  test('getBuildLogState parses steps and expiration status', () async {
    final api = BuildsApi(
      DataConnectApi(
        profile,
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'data': {
                'run': {
                  'id': 'run-2',
                  'status': 'completed',
                  'lastLogSequence': '350',
                  'logsExpireAt': '2026-11-20T00:00:00Z',
                  'allSteps': [
                    {
                      'stepId': 'prepare_vm',
                      'name': 'Prepare VM',
                      'status': 'success',
                      'stepOrder': 1,
                      'durationMs': '12000',
                      'createdAt': '2026-11-06T00:00:00Z',
                      'updatedAt': '2026-11-06T00:00:12Z',
                    },
                  ],
                },
              },
            }),
            200,
          ),
        ),
      ),
      now: () => DateTime.utc(2026, 11, 24),
    );
    addTearDown(api.dispose);

    final state = await api.getBuildLogState(
      teamId: 'team-1',
      jobId: 'job-1',
      runId: 'run-2',
    );

    expect(state.runId, 'run-2');
    expect(state.lastLogSequence, 350);
    expect(state.expired, isTrue);
    expect(state.steps, hasLength(1));
    expect(state.steps.single.durationMs, 12000);
  });

  test('getBuildLogs encodes afterSequence as string for Int64', () async {
    late Map<String, dynamic> body;
    final api = BuildsApi(
      DataConnectApi(
        profile,
        client: MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'data': {
                'run': {
                  'id': 'run-2',
                  'lastLogSequence': '500',
                  'logsExpireAt': '2026-12-10T00:00:00Z',
                  'logEntries': [
                    {
                      'logId': 'uuid-1',
                      'sequence': '301',
                      'stepId': 'run_workflow',
                      'source': 'workflow',
                      'stream': 'stderr',
                      'message': 'Test failed\n',
                      'occurredAt': '2026-11-24T00:00:00Z',
                      'createdAt': '2026-11-24T00:00:00Z',
                    },
                  ],
                },
              },
            }),
            200,
          );
        }),
      ),
      now: () => DateTime.utc(2026, 11, 24),
    );
    addTearDown(api.dispose);

    final page = await api.getBuildLogs(
      teamId: 'team-1',
      runId: 'run-2',
      afterSequence: 300,
      limit: 50,
    );

    expect(body['operationName'], 'GetBuildLogs');
    expect(body['variables'], {
      'teamId': 'team-1',
      'runId': 'run-2',
      'afterSequence': '300',
      'limit': 50,
    });
    expect(page.lastLogSequence, 500);
    expect(page.expired, isFalse);
    expect(page.entries.single.sequence, 301);
    expect(page.entries.single.stream, 'stderr');
  });
}
