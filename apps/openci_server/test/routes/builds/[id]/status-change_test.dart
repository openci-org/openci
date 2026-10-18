import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../routes/builds/[id]/_middleware.dart' as build;
import '../../../../routes/builds/[id]/status-change.dart' as route;
import '../../../helpers/github_app_test_key.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late Map<String, String> environment;
  late List<http.Request> githubRequests;

  final source = DriftBuildJob(
    id: 'source',
    teamId: 'team-1',
    owner: 'owner',
    repo: 'repo',
    installationId: '54321',
    checkRunId: '11111',
    githubBaseUrl: 'https://untrusted.example',
    status: BuildJobStatus.FAILURE,
    workflowName: 'CI',
    workflowFileName: 'ci.dart',
    workflowRunId: 'workflow-run-1',
    workflowJobKey: 'build',
    jobKey: 'build-linux',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  final matrixJob = source.copyWith(
    id: 'matrix-job',
    jobKey: const Value('build-macos'),
    checkRunId: const Value('99999'),
    status: BuildJobStatus.QUEUED,
  );
  final dependent = source.copyWith(
    id: 'dependent',
    workflowJobKey: const Value('deploy'),
    jobKey: const Value('deploy'),
    needs: const Value(['build-linux']),
    checkRunId: const Value('88888'),
    status: BuildJobStatus.WAITING,
  );
  final connection = DriftGitHubConnection(
    id: 'connection-1',
    teamId: 'team-1',
    githubApiBaseUrl: 'https://api.github.com',
    githubAppId: 123456,
    installationId: 54321,
    accountId: 42,
    accountType: GitHubAccountType.organization,
    accountLogin: 'owner',
    verifiedByUserId: 'member-1',
    verifiedByGitHubUserId: 100,
    verifiedAt: DateTime.utc(2026),
    status: GitHubConnectionStatus.active,
  );

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    await db.teamDao.createTeamAndMember(
      DriftTeam(
        id: 'team-1',
        name: 'OpenCI',
        installationIds: const [98765],
        aiEnabled: false,
        runNumber: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      'member-1',
    );
    await db.buildJobDao.insertBuildJob(source);
    await db.buildJobDao.insertBuildJob(matrixJob);
    await db.into(db.gitHubConnections).insert(connection);

    tempDir = await Directory.systemTemp.createTemp('status_change_test_');
    final keyFile = File('${tempDir.path}/key.pem');
    await keyFile.writeAsString(testRsaPrivateKey);
    environment = {
      'GITHUB_APP_ID': '123456',
      'GITHUB_PRIVATE_KEY_PATH': keyFile.path,
      'GITHUB_API_BASE_URL': 'https://api.github.com',
    };
    githubRequests = [];
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  http.Response githubResponse(http.Request request) {
    return switch (request.method) {
      'GET' => http.Response(jsonEncode({'id': 54321}), 200),
      'POST' => http.Response(jsonEncode({'token': 'installation-token'}), 201),
      'PATCH' => http.Response('{}', 200),
      _ => http.Response('Unexpected GitHub request', 500),
    };
  }

  Future<http.Response> post({
    String? uid,
    String? bearerToken = 'test-internal-key',
    String method = 'POST',
    String body = '{"status":"FAILURE"}',
    http.Response Function(http.Request)? respond,
  }) async {
    final githubClient = MockClient((request) async {
      githubRequests.add(request);
      return (respond ?? githubResponse)(request);
    });
    addTearDown(githubClient.close);
    final handler =
        ((RequestContext context) => route.onRequest(context, 'source'))
            .use(build.middleware)
            .use(provider<AppDatabase>((_) => db))
            .use(provider<String?>((_) => uid))
            .use(provider<Map<String, String>>((_) => environment))
            .use(provider<http.Client>((_) => githubClient))
            .use(
              provider<InternalApiKeyValidator>(
                (_) => const InternalApiKeyValidator(
                  environment: {'INTERNAL_API_KEY': 'test-internal-key'},
                ),
              ),
            );
    final server = await serve(handler, InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final client = http.Client();
    addTearDown(client.close);
    final request = http.Request(
      method,
      Uri(
        scheme: 'http',
        host: server.address.address,
        port: server.port,
        path: '/builds/source/status-change',
      ),
    );
    request.headers[HttpHeaders.contentTypeHeader] = 'application/json';
    request.body = body;
    if (bearerToken != null) {
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer $bearerToken';
    }
    return http.Response.fromStream(await client.send(request));
  }

  Future<void> expectStatus(String id, BuildJobStatus status) async {
    final job = (await db.buildJobDao.getBuildJob(id))!;
    expect(job.status, status);
    if (status == BuildJobStatus.CANCELLED ||
        status == BuildJobStatus.SKIPPED) {
      expect(job.completedAt, isNotNull);
    }
  }

  void expectFailure(http.Response response) {
    expect(response.statusCode, HttpStatus.internalServerError);
    expect(jsonDecode(response.body), {
      'success': false,
      'error': 'Internal server error',
    });
  }

  Future<void> expectConnectionRejected(
    DriftGitHubConnection rejectedConnection,
  ) async {
    await db.update(db.gitHubConnections).replace(rejectedConnection);

    final response = await post();

    expectFailure(response);
    expect(githubRequests, isEmpty);
    await expectStatus('matrix-job', BuildJobStatus.CANCELLED);
  }

  test(
    'an internal key cancels a matrix check through its connection',
    () async {
      final response = await post();

      expect(response.statusCode, HttpStatus.ok);
      expect(jsonDecode(response.body), {'success': true});
      await expectStatus('matrix-job', BuildJobStatus.CANCELLED);
      expect(githubRequests.map((request) => request.url.toString()), [
        'https://api.github.com/repos/owner/repo/installation',
        'https://api.github.com/app/installations/54321/access_tokens',
        'https://api.github.com/repos/owner/repo/check-runs/99999',
      ]);
      expect(githubRequests.map((request) => request.method), [
        'GET',
        'POST',
        'PATCH',
      ]);
      final update = githubRequests.last;
      expect(update.headers['authorization'], 'Bearer installation-token');
      final body = jsonDecode(update.body) as Map<String, dynamic>;
      expect(body['status'], 'completed');
      expect(body['conclusion'], 'cancelled');
      expect(body['completed_at'], isNotEmpty);
    },
  );

  test(
    'a team member skips dependent checks through their connection',
    () async {
      await db.delete(db.buildJobs).delete(matrixJob);
      await db.buildJobDao.insertBuildJob(dependent);

      final response = await post(uid: 'member-1', bearerToken: null);

      expect(response.statusCode, HttpStatus.ok);
      await expectStatus('dependent', BuildJobStatus.SKIPPED);
      expect(githubRequests.map((request) => request.method), [
        'GET',
        'POST',
        'PATCH',
      ]);
      expect(
        githubRequests.last.url.path,
        '/repos/owner/repo/check-runs/88888',
      );
      expect(jsonDecode(githubRequests.last.body)['conclusion'], 'skipped');
    },
  );

  test('verifies the affected job rather than the source job', () async {
    await db.buildJobDao.updateBuildJob(
      matrixJob.copyWith(
        owner: 'another-owner',
        repo: 'another-repo',
        installationId: const Value('65432'),
      ),
    );
    await db
        .update(db.gitHubConnections)
        .replace(
          connection.copyWith(installationId: 65432),
        );

    final response = await post(
      respond: (request) => request.method == 'GET'
          ? http.Response(jsonEncode({'id': 65432}), 200)
          : githubResponse(request),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(githubRequests.map((request) => request.url.path), [
      '/repos/another-owner/another-repo/installation',
      '/app/installations/65432/access_tokens',
      '/repos/another-owner/another-repo/check-runs/99999',
    ]);
  });

  test(
    'does not authorize a legacy target ID from the source or body',
    () async {
      await db.buildJobDao.updateBuildJob(
        matrixJob.copyWith(installationId: const Value('98765')),
      );

      final response = await post(
        body: '{"status":"FAILURE","teamId":"team-1","installationId":"54321"}',
      );

      expectFailure(response);
      expect(githubRequests, isEmpty);
      await expectStatus('matrix-job', BuildJobStatus.CANCELLED);
    },
  );

  test('rejects a connection belonging to another team', () async {
    final team = (await db.teamDao.getTeam('team-1'))!;
    await db.into(db.teams).insert(team.copyWith(id: 'other-team'));

    await expectConnectionRejected(connection.copyWith(teamId: 'other-team'));
  });

  test('rejects a suspended connection', () async {
    await expectConnectionRejected(
      connection.copyWith(status: GitHubConnectionStatus.suspended),
    );
  });

  test('rejects a removed connection', () async {
    await expectConnectionRejected(
      connection.copyWith(status: GitHubConnectionStatus.removed),
    );
  });

  test('rejects a connection for another GitHub host', () async {
    await expectConnectionRejected(
      connection.copyWith(githubApiBaseUrl: 'https://github.example/api/v3'),
    );
  });

  test('rejects a connection for another GitHub App', () async {
    await expectConnectionRejected(connection.copyWith(githubAppId: 42));
  });

  test(
    'rejects an unverified dependent even when the matrix check succeeds',
    () async {
      await db.buildJobDao.insertBuildJob(
        dependent.copyWith(installationId: const Value('98765')),
      );
      await db.buildJobDao.insertBuildJob(
        dependent.copyWith(
          id: 'last-job',
          jobKey: const Value('notify'),
          needs: const Value(['deploy']),
          checkRunId: const Value(null),
        ),
      );

      final response = await post();

      expectFailure(response);
      await expectStatus('matrix-job', BuildJobStatus.CANCELLED);
      await expectStatus('dependent', BuildJobStatus.SKIPPED);
      await expectStatus('last-job', BuildJobStatus.SKIPPED);
      expect(githubRequests, hasLength(3));
      expect(
        githubRequests.last.url.path,
        '/repos/owner/repo/check-runs/99999',
      );
    },
  );

  test(
    'rejects a repository belonging to another installation before issuing a token',
    () async {
      final response = await post(
        respond: (_) => http.Response(jsonEncode({'id': 65432}), 200),
      );

      expectFailure(response);
      await expectStatus('matrix-job', BuildJobStatus.CANCELLED);
      expect(githubRequests, hasLength(1));
      expect(githubRequests.single.method, 'GET');
    },
  );

  test(
    'does not update a dependent repository with a different installation',
    () async {
      await db.delete(db.buildJobs).delete(matrixJob);
      await db.buildJobDao.insertBuildJob(dependent);

      final response = await post(
        respond: (_) => http.Response(jsonEncode({'id': 65432}), 200),
      );

      expectFailure(response);
      await expectStatus('dependent', BuildJobStatus.SKIPPED);
      expect(githubRequests, hasLength(1));
      expect(githubRequests.single.method, 'GET');
    },
  );

  test('reports GitHub repository lookup refusal as failure', () async {
    final response = await post(
      respond: (_) => http.Response('private GitHub permission detail', 403),
    );

    expectFailure(response);
    expect(githubRequests, hasLength(1));
  });

  test('reports token issuance refusal without updating the check', () async {
    final response = await post(
      respond: (request) => request.method == 'POST'
          ? http.Response('private token detail', 403)
          : githubResponse(request),
    );

    expectFailure(response);
    expect(githubRequests.map((request) => request.method), ['GET', 'POST']);
  });

  test('rejects an empty token before updating the check', () async {
    final response = await post(
      respond: (request) => request.method == 'POST'
          ? http.Response(jsonEncode({'token': ''}), 201)
          : githubResponse(request),
    );

    expectFailure(response);
    expect(githubRequests.map((request) => request.method), ['GET', 'POST']);
  });

  test(
    'finishes local cancellation and recursive skipping after a GitHub failure',
    () async {
      await db.buildJobDao.insertBuildJob(dependent);
      await db.buildJobDao.insertBuildJob(
        dependent.copyWith(
          id: 'last-job',
          jobKey: const Value('notify'),
          needs: const Value(['deploy']),
          checkRunId: const Value('77777'),
        ),
      );

      final response = await post(
        respond: (request) => request.url.path.endsWith('/99999')
            ? http.Response('private check update detail', 403)
            : githubResponse(request),
      );

      expectFailure(response);
      await expectStatus('matrix-job', BuildJobStatus.CANCELLED);
      await expectStatus('dependent', BuildJobStatus.SKIPPED);
      await expectStatus('last-job', BuildJobStatus.SKIPPED);
      final updates = githubRequests.where(
        (request) => request.method == 'PATCH',
      );
      expect(updates.map((request) => request.url.path), [
        '/repos/owner/repo/check-runs/99999',
        '/repos/owner/repo/check-runs/88888',
        '/repos/owner/repo/check-runs/77777',
      ]);
      expect(updates.map((request) => jsonDecode(request.body)['conclusion']), [
        'cancelled',
        'skipped',
        'skipped',
      ]);
    },
  );

  test(
    'does not skip the former dummy installation ID or hide its rejection',
    () async {
      await db.buildJobDao.updateBuildJob(
        matrixJob.copyWith(installationId: const Value('12345678')),
      );
      await db
          .update(db.gitHubConnections)
          .replace(
            connection.copyWith(installationId: 12345678),
          );

      final response = await post(
        respond: (request) => switch (request.method) {
          'GET' => http.Response(jsonEncode({'id': 12345678}), 200),
          'POST' => githubResponse(request),
          _ => http.Response('private check update detail', 403),
        },
      );

      expectFailure(response);
      expect(githubRequests.map((request) => request.method), [
        'GET',
        'POST',
        'PATCH',
      ]);
      expect(
        githubRequests[1].url.path,
        '/app/installations/12345678/access_tokens',
      );
    },
  );

  test('reports transport failures without exposing their details', () async {
    final response = await post(
      respond: (_) => throw const SocketException('private transport detail'),
    );

    expectFailure(response);
    expect(githubRequests, hasLength(1));
  });

  test(
    'a missing installation ID cannot silently skip an existing check',
    () async {
      await db.buildJobDao.updateBuildJob(
        matrixJob.copyWith(installationId: const Value(null)),
      );

      expectFailure(await post());
      expect(githubRequests, isEmpty);
    },
  );

  test('rejects malformed check IDs before contacting GitHub', () async {
    await db.buildJobDao.updateBuildJob(
      matrixJob.copyWith(checkRunId: const Value('../other')),
    );

    expectFailure(await post());
    expect(githubRequests, isEmpty);
  });

  test(
    'rejects a non-positive installation ID before contacting GitHub',
    () async {
      await db.buildJobDao.updateBuildJob(
        matrixJob.copyWith(installationId: const Value('0')),
      );

      expectFailure(await post());
      expect(githubRequests, isEmpty);
    },
  );

  test('updates local state without GitHub when jobs have no checks', () async {
    await db.buildJobDao.updateBuildJob(
      matrixJob.copyWith(checkRunId: const Value(null)),
    );
    await db.buildJobDao.insertBuildJob(
      dependent.copyWith(checkRunId: const Value(null)),
    );
    await db.delete(db.gitHubConnections).go();
    environment.clear();

    final response = await post();

    expect(response.statusCode, HttpStatus.ok);
    expect(githubRequests, isEmpty);
    await expectStatus('matrix-job', BuildJobStatus.CANCELLED);
    await expectStatus('dependent', BuildJobStatus.SKIPPED);
  });

  test(
    'reports connection database failures without contacting GitHub',
    () async {
      await db.customStatement('DROP TABLE github_connections');

      expectFailure(await post());
      expect(githubRequests, isEmpty);
      await expectStatus('matrix-job', BuildJobStatus.CANCELLED);
    },
  );

  test(
    'reports missing operator configuration without contacting GitHub',
    () async {
      environment.remove('GITHUB_APP_ID');

      expectFailure(await post());
      expect(githubRequests, isEmpty);
    },
  );

  test('uses the normalized operator URL instead of the saved job URL', () async {
    environment['GITHUB_API_BASE_URL'] =
        ' https://github.example:8443/api/v3/// ';
    await db
        .update(db.gitHubConnections)
        .replace(
          connection.copyWith(
            githubApiBaseUrl: 'https://github.example:8443/api/v3',
          ),
        );

    final response = await post();

    expect(response.statusCode, HttpStatus.ok);
    expect(githubRequests.map((request) => request.url.toString()), [
      'https://github.example:8443/api/v3/repos/owner/repo/installation',
      'https://github.example:8443/api/v3/app/installations/54321/access_tokens',
      'https://github.example:8443/api/v3/repos/owner/repo/check-runs/99999',
    ]);
  });

  test(
    'never cancels or skips another team sharing workflow identifiers',
    () async {
      await db.delete(db.buildJobs).delete(matrixJob);
      final team = (await db.teamDao.getTeam('team-1'))!;
      await db.into(db.teams).insert(team.copyWith(id: 'other-team'));
      await db.buildJobDao.insertBuildJob(
        matrixJob.copyWith(teamId: const Value('other-team')),
      );
      await db.buildJobDao.insertBuildJob(
        dependent.copyWith(teamId: const Value('other-team')),
      );

      final response = await post(uid: 'member-1', bearerToken: null);

      expect(response.statusCode, HttpStatus.ok);
      expect(githubRequests, isEmpty);
      await expectStatus('matrix-job', BuildJobStatus.QUEUED);
      await expectStatus('dependent', BuildJobStatus.WAITING);
    },
  );

  test(
    'successful prerequisites still queue dependents within the same team',
    () async {
      await db.buildJobDao.updateBuildJob(
        source.copyWith(status: BuildJobStatus.SUCCESS),
      );
      await db.buildJobDao.insertBuildJob(dependent);
      final team = (await db.teamDao.getTeam('team-1'))!;
      await db.into(db.teams).insert(team.copyWith(id: 'other-team'));
      await db.buildJobDao.insertBuildJob(
        source.copyWith(
          id: 'foreign-source',
          teamId: const Value('other-team'),
        ),
      );

      final response = await post(body: '{"status":"SUCCESS"}');

      expect(response.statusCode, HttpStatus.ok);
      expect(githubRequests, isEmpty);
      await expectStatus('dependent', BuildJobStatus.QUEUED);
      await expectStatus('matrix-job', BuildJobStatus.QUEUED);
    },
  );

  test('does not cancel matrix jobs that already completed', () async {
    await db.buildJobDao.updateBuildJob(
      matrixJob.copyWith(status: BuildJobStatus.SUCCESS),
    );

    final response = await post();

    expect(response.statusCode, HttpStatus.ok);
    expect(githubRequests, isEmpty);
    await expectStatus('matrix-job', BuildJobStatus.SUCCESS);
  });

  test('rejects unauthenticated callers before changing jobs', () async {
    final response = await post(bearerToken: null);

    expect(response.statusCode, HttpStatus.unauthorized);
    expect(githubRequests, isEmpty);
    await expectStatus('matrix-job', BuildJobStatus.QUEUED);
  });

  test('rejects non-members before changing jobs', () async {
    final response = await post(uid: 'other-user', bearerToken: null);

    expect(response.statusCode, HttpStatus.forbidden);
    expect(githubRequests, isEmpty);
    await expectStatus('matrix-job', BuildJobStatus.QUEUED);
  });

  test('rejects unsupported methods before changing jobs', () async {
    final response = await post(method: 'GET');

    expect(response.statusCode, HttpStatus.methodNotAllowed);
    expect(githubRequests, isEmpty);
    await expectStatus('matrix-job', BuildJobStatus.QUEUED);
  });

  test('rejects malformed JSON before changing jobs', () async {
    final response = await post(body: '{');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(githubRequests, isEmpty);
    await expectStatus('matrix-job', BuildJobStatus.QUEUED);
  });

  test('rejects missing status before changing jobs', () async {
    final response = await post(body: '{}');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(githubRequests, isEmpty);
    await expectStatus('matrix-job', BuildJobStatus.QUEUED);
  });
}
