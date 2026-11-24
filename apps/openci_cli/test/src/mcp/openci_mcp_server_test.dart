import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_cli_plus/src/credential_store/credential_config.dart';
import 'package:openci_cli_plus/src/credential_store/credential_store.dart';
import 'package:openci_cli_plus/src/mcp/openci_mcp_server.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

String _jwtWithAud(String aud) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode({'aud': aud}))).replaceAll('=', '')}.signature';

Map<String, dynamic> _buildJobJson({
  required String id,
  String teamId = 'team-1',
  String status = 'FAILURE',
  String owner = 'openci-org',
  String repo = 'openci',
  String workflowName = 'CLI CI',
  String workflowFileName = 'cli_ci.dart',
  String? branch = 'develop',
  int? pullRequestNumber,
  String? latestRunId = 'run-1',
  String? failureSummary,
}) => {
  'id': id,
  'teamId': teamId,
  'status': status,
  'owner': owner,
  'repo': repo,
  'workflowName': workflowName,
  'workflowFileName': workflowFileName,
  'branch': branch,
  'pullRequestNumber': pullRequestNumber?.toString(),
  'retryCount': 0,
  'latestRunId': latestRunId,
  'createdAt': '1700000000',
  'updatedAt': '1700000060',
  'completedAt': '1700000120',
  'failureSummary': failureSummary,
};

Map<String, dynamic> _logEntryJson(
  int seq, {
  String? stepId = 'run_workflow',
  String stream = 'stdout',
  String? message,
}) => {
  'logId': 'uuid-$seq',
  'sequence': '$seq',
  'stepId': stepId,
  'source': 'workflow',
  'stream': stream,
  'message': message ?? 'line $seq',
  'occurredAt': '2026-11-24T00:00:00Z',
  'createdAt': '2026-11-24T00:00:00Z',
};

Future<({OpenCIMcpServer server, MCPClient client, ServerConnection conn})>
_connectServer({
  required CredentialStore store,
  required http.Client Function() httpClientFactory,
  DateTime Function()? now,
}) async {
  final clientToServer = StreamChannelController<String>();
  final server = OpenCIMcpServer(
    clientToServer.foreign,
    credentialStore: store,
    readProfile: (s) async {
      final config = await s.get();
      return config.profiles[config.activeProfile];
    },
    httpClientFactory: httpClientFactory,
    now: now ?? () => DateTime.utc(2026, 11, 24),
  );
  final client = MCPClient(
    Implementation(name: 'test-client', version: '0.1.0'),
  );
  final conn = client.connectServer(clientToServer.local);
  final initResult = await conn.initialize(
    InitializeRequest(
      protocolVersion: ProtocolVersion.latestSupported,
      capabilities: client.capabilities,
      clientInfo: client.implementation,
    ),
  );
  expect(initResult.serverInfo.name, 'openci');
  conn.notifyInitialized();
  await server.initialized;
  return (server: server, client: client, conn: conn);
}

void main() {
  late Directory tempDir;
  late CredentialStore store;
  final token = _jwtWithAud('openci-b1b91');

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('openci_mcp_test_');
    store = CredentialStore(customFilePath: '${tempDir.path}/credentials.json');
    await store.saveProfile(
      'remote',
      AuthProfile(
        serverUrl: 'https://ci.example.com',
        token: token,
        teamId: 'team-1',
        authType: 'firebase',
        expiresAt: DateTime.utc(2099, 1, 1),
      ),
    );
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('lists all read-only OpenCI MCP tools', () async {
    final harness = await _connectServer(
      store: store,
      httpClientFactory: () =>
          MockClient((_) async => http.Response('{}', 200)),
    );
    addTearDown(() async {
      await harness.conn.shutdown();
      await harness.server.shutdown();
    });

    final result = await harness.conn.listTools();
    final names = result.tools.map((tool) => tool.name).toList();
    expect(names, ['get_status', 'list_builds', 'get_build', 'get_build_logs']);
    for (final tool in result.tools) {
      expect(tool.toolAnnotations?.readOnlyHint, isTrue);
    }
  });

  test('get_status returns profile and team name without token', () async {
    final harness = await _connectServer(
      store: store,
      httpClientFactory: () => MockClient((request) async {
        expect(request.url.path, '/teamManagement');
        return http.Response(
          jsonEncode({
            'result': {
              'success': true,
              'teams': [
                {
                  'id': 'team-1',
                  'name': 'OpenCI',
                  'members': ['user-1'],
                  'createdAt': '2026-10-01T00:00:00.000Z',
                  'updatedAt': '2026-10-01T00:00:00.000Z',
                },
              ],
            },
          }),
          200,
        );
      }),
    );
    addTearDown(() async {
      await harness.conn.shutdown();
      await harness.server.shutdown();
    });

    final result = await harness.conn.callTool(
      CallToolRequest(name: 'get_status'),
    );
    expect(result.isError, isNot(true));
    final text = (result.content.single as TextContent).text;
    expect(text, isNot(contains(token)));
    final json = jsonDecode(text) as Map<String, dynamic>;
    expect(json['profile'], 'remote');
    expect(json['teamId'], 'team-1');
    expect(json['teamName'], 'OpenCI');
    expect(json['firebaseProjectId'], 'openci-b1b91');
    expect(json['localEmulator'], isFalse);
  });

  test('returns actionable error when not logged in', () async {
    final emptyDir = await Directory.systemTemp.createTemp('openci_empty_');
    addTearDown(() => emptyDir.delete(recursive: true));
    final emptyStore = CredentialStore(
      customFilePath: '${emptyDir.path}/credentials.json',
    );
    final harness = await _connectServer(
      store: emptyStore,
      httpClientFactory: () =>
          MockClient((_) async => http.Response('{}', 200)),
    );
    addTearDown(() async {
      await harness.conn.shutdown();
      await harness.server.shutdown();
    });

    final result = await harness.conn.callTool(
      CallToolRequest(name: 'list_builds'),
    );
    expect(result.isError, isTrue);
    final text = (result.content.single as TextContent).text;
    expect(text, contains('openci login'));
  });

  test(
    'list_builds filters by status, branch, repo, PR and workflow',
    () async {
      final harness = await _connectServer(
        store: store,
        httpClientFactory: () => MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['operationName'], 'GetBuildJobs');
          expect((body['variables'] as Map)['limit'], 200);
          return http.Response(
            jsonEncode({
              'data': {
                'buildJobs': [
                  _buildJobJson(
                    id: 'job-1',
                    status: 'SUCCESS',
                    branch: 'main',
                    pullRequestNumber: 10,
                    workflowName: 'Web Deploy',
                  ),
                  _buildJobJson(
                    id: 'job-2',
                    status: 'FAILURE',
                    branch: 'feat/mcp',
                    pullRequestNumber: 42,
                    workflowName: 'CLI CI',
                    failureSummary: 'Assertion failed',
                  ),
                ],
              },
            }),
            200,
          );
        }),
      );
      addTearDown(() async {
        await harness.conn.shutdown();
        await harness.server.shutdown();
      });

      final result = await harness.conn.callTool(
        CallToolRequest(
          name: 'list_builds',
          arguments: {
            'status': 'failure',
            'branch': 'feat/mcp',
            'repo': 'openci-org/openci',
            'pr_number': 42,
            'workflow': 'cli',
          },
        ),
      );
      expect(result.isError, isNot(true));
      final json =
          jsonDecode((result.content.single as TextContent).text)
              as Map<String, dynamic>;
      expect(json['scannedCount'], 2);
      expect(json['count'], 1);
      final builds = json['builds'] as List<dynamic>;
      expect((builds.single as Map)['id'], 'job-2');
      expect((builds.single as Map)['failureSummary'], 'Assertion failed');
    },
  );

  test('get_build returns job details and step statuses', () async {
    final harness = await _connectServer(
      store: store,
      httpClientFactory: () => MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (body['operationName'] == 'GetBuildJob') {
          return http.Response(
            jsonEncode({
              'data': {
                'job': _buildJobJson(
                  id: 'job-2',
                  latestRunId: 'run-9',
                  failureSummary: 'dart test exited with 1',
                ),
              },
            }),
            200,
          );
        }
        expect(body['operationName'], 'GetBuildLogState');
        return http.Response(
          jsonEncode({
            'data': {
              'run': {
                'id': 'run-9',
                'status': 'completed',
                'lastLogSequence': '5000',
                'logsExpireAt': '2026-12-08T00:00:00Z',
                'allSteps': [
                  {
                    'stepId': 'run_workflow',
                    'name': 'Run Workflow',
                    'status': 'failure',
                    'stepOrder': 3,
                    'durationMs': '45100',
                    'createdAt': '2026-11-24T00:00:00Z',
                    'updatedAt': '2026-11-24T00:00:45Z',
                  },
                ],
              },
            },
          }),
          200,
        );
      }),
    );
    addTearDown(() async {
      await harness.conn.shutdown();
      await harness.server.shutdown();
    });

    final result = await harness.conn.callTool(
      CallToolRequest(name: 'get_build', arguments: {'job_id': 'job-2'}),
    );
    expect(result.isError, isNot(true));
    final json =
        jsonDecode((result.content.single as TextContent).text)
            as Map<String, dynamic>;
    expect((json['job'] as Map)['id'], 'job-2');
    expect((json['run'] as Map)['lastLogSequence'], 5000);
    expect(
      (((json['run'] as Map)['steps'] as List).single as Map)['stepId'],
      'run_workflow',
    );
  });

  test(
    'get_build_logs tail seeks directly to lastLogSequence - tail',
    () async {
      final operations = <String>[];
      String? requestedAfterSequence;
      int? requestedLimit;

      final harness = await _connectServer(
        store: store,
        httpClientFactory: () => MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final op = body['operationName'] as String;
          operations.add(op);
          if (op == 'GetBuildJob') {
            return http.Response(
              jsonEncode({
                'data': {
                  'job': _buildJobJson(id: 'job-2', latestRunId: 'run-9'),
                },
              }),
              200,
            );
          }
          if (op == 'GetBuildLogState') {
            return http.Response(
              jsonEncode({
                'data': {
                  'run': {
                    'id': 'run-9',
                    'status': 'completed',
                    'lastLogSequence': '5000',
                    'logsExpireAt': '2026-12-08T00:00:00Z',
                    'allSteps': [],
                  },
                },
              }),
              200,
            );
          }
          final vars = body['variables'] as Map<String, dynamic>;
          requestedAfterSequence = vars['afterSequence'] as String;
          requestedLimit = vars['limit'] as int;
          return http.Response(
            jsonEncode({
              'data': {
                'run': {
                  'id': 'run-9',
                  'lastLogSequence': '5000',
                  'logsExpireAt': '2026-12-08T00:00:00Z',
                  'logEntries': [
                    _logEntryJson(
                      4998,
                      stream: 'stdout',
                      message: 'Running...',
                    ),
                    _logEntryJson(4999, stream: 'stderr', message: 'Boom!\n'),
                    _logEntryJson(5000, stream: 'stderr', message: 'Exit 1'),
                  ],
                },
              },
            }),
            200,
          );
        }),
      );
      addTearDown(() async {
        await harness.conn.shutdown();
        await harness.server.shutdown();
      });

      final result = await harness.conn.callTool(
        CallToolRequest(
          name: 'get_build_logs',
          arguments: {'job_id': 'job-2', 'tail': 3},
        ),
      );

      expect(result.isError, isNot(true));
      expect(operations, ['GetBuildJob', 'GetBuildLogState', 'GetBuildLogs']);
      expect(requestedAfterSequence, '4997');
      expect(requestedLimit, 3);

      final text = (result.content.single as TextContent).text;
      final parts = text.split('\n---\n');
      expect(parts, hasLength(2));
      final metadata = jsonDecode(parts[0]) as Map<String, dynamic>;
      expect(metadata['mode'], 'tail');
      expect(metadata['returnedCount'], 3);
      expect(metadata['firstSequence'], 4998);
      expect(metadata['lastSequence'], 5000);
      expect(metadata['hasOlderUnscanned'], isTrue);
      expect(parts[1], contains('[seq=4999 step=run_workflow stderr] Boom!'));
    },
  );

  test(
    'get_build_logs forward pagination preserves exact cursor on mid-page limit',
    () async {
      final harness = await _connectServer(
        store: store,
        httpClientFactory: () => MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['operationName'], 'GetBuildLogs');
          return http.Response(
            jsonEncode({
              'data': {
                'run': {
                  'id': 'run-9',
                  'lastLogSequence': '10',
                  'logsExpireAt': '2026-12-08T00:00:00Z',
                  'logEntries': [
                    _logEntryJson(1, stream: 'stdout', message: 'ok'),
                    _logEntryJson(2, stream: 'stderr', message: 'error one'),
                    _logEntryJson(3, stream: 'stderr', message: 'error two'),
                    _logEntryJson(4, stream: 'stderr', message: 'error three'),
                  ],
                },
              },
            }),
            200,
          );
        }),
      );
      addTearDown(() async {
        await harness.conn.shutdown();
        await harness.server.shutdown();
      });

      final result = await harness.conn.callTool(
        CallToolRequest(
          name: 'get_build_logs',
          arguments: {
            'run_id': 'run-9',
            'after_sequence': 0,
            'stream': 'stderr',
            'limit': 2,
          },
        ),
      );

      expect(result.isError, isNot(true));
      final parts = (result.content.single as TextContent).text.split(
        '\n---\n',
      );
      final metadata = jsonDecode(parts[0]) as Map<String, dynamic>;
      expect(metadata['mode'], 'forward');
      expect(metadata['returnedCount'], 2);
      expect(metadata['nextAfterSequence'], 3);
      expect(metadata['hasMore'], isTrue);
      expect(parts[1], isNot(contains('error three')));
    },
  );

  test(
    'get_build_logs filtered tail scans backward and returns chronological order',
    () async {
      final seenAfter = <String>[];
      final harness = await _connectServer(
        store: store,
        httpClientFactory: () => MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final vars = body['variables'] as Map<String, dynamic>;
          final after = vars['afterSequence'] as String;
          final limit = vars['limit'] as int;
          if (after == '0' && limit == 1) {
            return http.Response(
              jsonEncode({
                'data': {
                  'run': {
                    'id': 'run-9',
                    'lastLogSequence': '450',
                    'logsExpireAt': '2026-12-08T00:00:00Z',
                    'logEntries': [_logEntryJson(1)],
                  },
                },
              }),
              200,
            );
          }
          seenAfter.add(after);
          if (after == '250') {
            return http.Response(
              jsonEncode({
                'data': {
                  'run': {
                    'id': 'run-9',
                    'lastLogSequence': '450',
                    'logsExpireAt': '2026-12-08T00:00:00Z',
                    'logEntries': [
                      _logEntryJson(
                        300,
                        stream: 'stderr',
                        message: 'Late ERROR',
                      ),
                    ],
                  },
                },
              }),
              200,
            );
          }
          if (after == '50') {
            return http.Response(
              jsonEncode({
                'data': {
                  'run': {
                    'id': 'run-9',
                    'lastLogSequence': '450',
                    'logsExpireAt': '2026-12-08T00:00:00Z',
                    'logEntries': [
                      _logEntryJson(
                        120,
                        stream: 'stderr',
                        message: 'Early ERROR',
                      ),
                    ],
                  },
                },
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'data': {
                'run': {
                  'id': 'run-9',
                  'lastLogSequence': '450',
                  'logsExpireAt': '2026-12-08T00:00:00Z',
                  'logEntries': [],
                },
              },
            }),
            200,
          );
        }),
      );
      addTearDown(() async {
        await harness.conn.shutdown();
        await harness.server.shutdown();
      });

      final result = await harness.conn.callTool(
        CallToolRequest(
          name: 'get_build_logs',
          arguments: {'run_id': 'run-9', 'query': 'error', 'max_pages': 2},
        ),
      );

      expect(result.isError, isNot(true));
      expect(seenAfter, ['250', '50']);
      final parts = (result.content.single as TextContent).text.split(
        '\n---\n',
      );
      final metadata = jsonDecode(parts[0]) as Map<String, dynamic>;
      expect(metadata['mode'], 'tail_filtered');
      expect(metadata['returnedCount'], 2);
      expect(metadata['firstSequence'], 120);
      expect(metadata['lastSequence'], 300);
      expect(metadata['hasOlderUnscanned'], isTrue);
      final lines = parts[1].split('\n');
      expect(lines[0], contains('Early ERROR'));
      expect(lines[1], contains('Late ERROR'));
    },
  );

  test('get_build_logs reports validation errors and expired logs', () async {
    final harness = await _connectServer(
      store: store,
      httpClientFactory: () => MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': {
              'run': {
                'id': 'run-expired',
                'lastLogSequence': '100',
                'logsExpireAt': '2026-11-01T00:00:00Z',
                'logEntries': [],
              },
            },
          }),
          200,
        );
      }),
    );
    addTearDown(() async {
      await harness.conn.shutdown();
      await harness.server.shutdown();
    });

    final missingIds = await harness.conn.callTool(
      CallToolRequest(name: 'get_build_logs', arguments: {}),
    );
    expect(missingIds.isError, isTrue);

    final conflictingArgs = await harness.conn.callTool(
      CallToolRequest(
        name: 'get_build_logs',
        arguments: {'run_id': 'run-1', 'tail': 10, 'after_sequence': 5},
      ),
    );
    expect(conflictingArgs.isError, isTrue);

    final expired = await harness.conn.callTool(
      CallToolRequest(
        name: 'get_build_logs',
        arguments: {'run_id': 'run-expired'},
      ),
    );
    expect(expired.isError, isNot(true));
    final json =
        jsonDecode((expired.content.single as TextContent).text)
            as Map<String, dynamic>;
    expect(json['expired'], isTrue);
    expect(json['note'], contains('expired'));
  });
}
