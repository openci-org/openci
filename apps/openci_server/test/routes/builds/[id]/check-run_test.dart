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
import '../../../../routes/builds/[id]/check-run.dart' as route;
import '../../../helpers/github_app_test_key.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late Map<String, String> environment;
  late List<http.Request> githubRequests;

  final job = DriftBuildJob(
    id: 'job-1',
    teamId: 'team-1',
    owner: 'owner',
    repo: 'repo',
    installationId: '54321',
    checkRunId: '99999',
    githubBaseUrl: 'https://untrusted.example',
    status: BuildJobStatus.IN_PROGRESS,
    workflowName: 'CI',
    workflowFileName: 'ci.dart',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
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
    await db.buildJobDao.insertBuildJob(job);
    await db.into(db.gitHubConnections).insert(connection);

    tempDir = await Directory.systemTemp.createTemp('job_check_run_test_');
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

  Future<http.Response> post({
    String? uid,
    String? bearerToken = 'test-internal-key',
    String method = 'POST',
    String body = '{"status":"completed","conclusion":"success"}',
    http.Response Function(http.Request)? respond,
  }) async {
    final githubClient = MockClient((request) async {
      githubRequests.add(request);
      if (respond != null) return respond(request);
      return switch (request.url.path) {
        '/repos/owner/repo/installation' => http.Response(
          jsonEncode({'id': 54321}),
          200,
        ),
        '/app/installations/54321/access_tokens' => http.Response(
          jsonEncode({'token': 'test-installation-token'}),
          200,
        ),
        '/repos/owner/repo/check-runs/99999' => http.Response('{}', 200),
        _ => http.Response('Unexpected GitHub request', 500),
      };
    });
    addTearDown(githubClient.close);

    final handler =
        ((RequestContext context) => route.onRequest(context, 'job-1'))
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
        path: '/builds/job-1/check-run',
      ),
    );
    request.headers[HttpHeaders.contentTypeHeader] = 'application/json';
    request.body = body;
    if (bearerToken != null) {
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer $bearerToken';
    }
    return http.Response.fromStream(await client.send(request));
  }

  Future<void> expectConnectionRejected(
    DriftGitHubConnection rejectedConnection,
  ) async {
    await db.update(db.gitHubConnections).replace(rejectedConnection);

    final response = await post();

    expect(response.statusCode, HttpStatus.forbidden);
    expect(jsonDecode(response.body), {'success': false, 'error': 'Forbidden'});
    expect(githubRequests, isEmpty);
  }

  test('an internal key updates a check through a new connection', () async {
    final team = (await db.teamDao.getTeam('team-1'))!;
    await db.teamDao.updateTeam(team.copyWith(installationIds: []));

    final response = await post();

    expect(response.statusCode, HttpStatus.ok);
    expect(jsonDecode(response.body), {'success': true});
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
    expect(update.headers['authorization'], 'Bearer test-installation-token');
    final body = jsonDecode(update.body) as Map<String, dynamic>;
    expect(body['status'], 'completed');
    expect(body['conclusion'], 'success');
    expect(DateTime.parse(body['completed_at'] as String).isUtc, isTrue);
  });

  test('a team member can update the check without an internal key', () async {
    final response = await post(uid: 'member-1', bearerToken: null);

    expect(response.statusCode, HttpStatus.ok);
    expect(jsonDecode(response.body), {'success': true});
    expect(githubRequests.last.method, 'PATCH');
  });

  test('rejects an unauthenticated caller before contacting GitHub', () async {
    final response = await post(bearerToken: null);

    expect(response.statusCode, HttpStatus.unauthorized);
    expect(githubRequests, isEmpty);
  });

  test('rejects a non-member before contacting GitHub', () async {
    final response = await post(uid: 'other-user', bearerToken: null);

    expect(response.statusCode, HttpStatus.forbidden);
    expect(githubRequests, isEmpty);
  });

  test('rejects unsupported methods', () async {
    final response = await post(method: 'GET');

    expect(response.statusCode, HttpStatus.methodNotAllowed);
    expect(githubRequests, isEmpty);
  });

  test('rejects malformed JSON', () async {
    final response = await post(body: '{');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(githubRequests, isEmpty);
  });

  test('rejects a missing status', () async {
    final response = await post(body: '{}');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(jsonDecode(response.body), {
      'success': false,
      'error': 'status is required',
    });
    expect(githubRequests, isEmpty);
  });

  test('rejects a job without an installation ID', () async {
    await db.buildJobDao.updateBuildJob(
      job.copyWith(installationId: const Value(null)),
    );

    final response = await post();

    expect(response.statusCode, HttpStatus.badRequest);
    expect(githubRequests, isEmpty);
  });

  test('rejects a malformed installation ID', () async {
    await db.buildJobDao.updateBuildJob(
      job.copyWith(installationId: const Value('../other')),
    );

    final response = await post();

    expect(response.statusCode, HttpStatus.badRequest);
    expect(githubRequests, isEmpty);
  });

  test('rejects a non-positive installation ID', () async {
    await db.buildJobDao.updateBuildJob(
      job.copyWith(installationId: const Value('0')),
    );

    final response = await post();

    expect(response.statusCode, HttpStatus.badRequest);
    expect(githubRequests, isEmpty);
  });

  test('rejects a job without a check run ID', () async {
    await db.buildJobDao.updateBuildJob(
      job.copyWith(checkRunId: const Value(null)),
    );

    final response = await post();

    expect(response.statusCode, HttpStatus.badRequest);
    expect(githubRequests, isEmpty);
  });

  test('rejects a malformed check run ID', () async {
    await db.buildJobDao.updateBuildJob(
      job.copyWith(checkRunId: const Value('../other')),
    );

    final response = await post();

    expect(response.statusCode, HttpStatus.badRequest);
    expect(githubRequests, isEmpty);
  });

  test('rejects a non-positive check run ID', () async {
    await db.buildJobDao.updateBuildJob(
      job.copyWith(checkRunId: const Value('0')),
    );

    final response = await post();

    expect(response.statusCode, HttpStatus.badRequest);
    expect(githubRequests, isEmpty);
  });

  test('a forged body cannot authorize a legacy job installation', () async {
    await db.buildJobDao.updateBuildJob(
      job.copyWith(installationId: const Value('98765')),
    );

    final response = await post(
      body: jsonEncode({
        'status': 'completed',
        'conclusion': 'success',
        'teamId': 'team-1',
        'installationId': '54321',
      }),
    );

    expect(response.statusCode, HttpStatus.forbidden);
    expect(githubRequests, isEmpty);
  });

  test('rejects a job whose connection no longer exists', () async {
    await db.delete(db.gitHubConnections).go();

    final response = await post();

    expect(response.statusCode, HttpStatus.forbidden);
    expect(githubRequests, isEmpty);
  });

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

  test('rejects a connection for another GitHub API host', () async {
    await expectConnectionRejected(
      connection.copyWith(githubApiBaseUrl: 'https://github.example/api/v3'),
    );
  });

  test('rejects a connection for another GitHub App', () async {
    await expectConnectionRejected(connection.copyWith(githubAppId: 42));
  });

  test('rejects a repository belonging to another installation', () async {
    final response = await post(
      respond: (_) => http.Response(jsonEncode({'id': 99999}), 200),
    );

    expect(response.statusCode, HttpStatus.forbidden);
    expect(jsonDecode(response.body), {'success': false, 'error': 'Forbidden'});
    expect(githubRequests, hasLength(1));
    expect(githubRequests.single.method, 'GET');
    expect(githubRequests.single.url.path, '/repos/owner/repo/installation');
  });

  test('fails without updating when GitHub denies repository access', () async {
    final response = await post(
      respond: (_) => http.Response('private permission detail', 403),
    );

    expect(response.statusCode, HttpStatus.internalServerError);
    expect(jsonDecode(response.body), {
      'success': false,
      'error': 'Internal server error',
    });
    expect(githubRequests, hasLength(1));
    expect(githubRequests.single.url.path, '/repos/owner/repo/installation');
  });

  test('fails without updating when GitHub refuses token issuance', () async {
    final response = await post(
      respond: (request) => request.method == 'GET'
          ? http.Response(jsonEncode({'id': 54321}), 200)
          : http.Response('private token failure', 403),
    );

    expect(response.statusCode, HttpStatus.internalServerError);
    expect(jsonDecode(response.body), {
      'success': false,
      'error': 'Internal server error',
    });
    expect(githubRequests.map((request) => request.url.path), [
      '/repos/owner/repo/installation',
      '/app/installations/54321/access_tokens',
    ]);
  });

  test('does not skip updates for the former dummy installation ID', () async {
    await db.buildJobDao.updateBuildJob(
      job.copyWith(installationId: const Value('12345678')),
    );
    await db
        .update(db.gitHubConnections)
        .replace(
          connection.copyWith(installationId: 12345678),
        );

    final response = await post(
      respond: (request) => switch (request.method) {
        'GET' => http.Response(jsonEncode({'id': 12345678}), 200),
        'POST' => http.Response(jsonEncode({'token': 'test-token'}), 200),
        _ => http.Response('private update failure', 403),
      },
    );

    expect(response.statusCode, HttpStatus.internalServerError);
    expect(jsonDecode(response.body), {
      'success': false,
      'error': 'Internal server error',
    });
    expect(githubRequests.map((request) => request.method), [
      'GET',
      'POST',
      'PATCH',
    ]);
    expect(githubRequests.map((request) => request.url.path), [
      '/repos/owner/repo/installation',
      '/app/installations/12345678/access_tokens',
      '/repos/owner/repo/check-runs/99999',
    ]);
  });

  test('rejects an empty token before updating the check', () async {
    final response = await post(
      respond: (request) => request.method == 'GET'
          ? http.Response(jsonEncode({'id': 54321}), 200)
          : http.Response(jsonEncode({'token': ''}), 200),
    );

    expect(response.statusCode, HttpStatus.internalServerError);
    expect(jsonDecode(response.body), {
      'success': false,
      'error': 'Internal server error',
    });
    expect(githubRequests.map((request) => request.method), ['GET', 'POST']);
  });

  test('rejects missing App configuration before contacting GitHub', () async {
    environment.remove('GITHUB_PRIVATE_KEY_PATH');

    final response = await post();

    expect(response.statusCode, HttpStatus.internalServerError);
    expect(jsonDecode(response.body), {
      'success': false,
      'error': 'Internal server error',
    });
    expect(githubRequests, isEmpty);
  });

  test(
    'reports a connection database failure without contacting GitHub',
    () async {
      await db.customStatement('DROP TABLE github_connections');

      final response = await post();

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(jsonDecode(response.body), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(githubRequests, isEmpty);
    },
  );

  test('uses the normalized operator URL for all GitHub requests', () async {
    environment['GITHUB_API_BASE_URL'] =
        ' https://github.example:8443/api/v3/// ';
    await db
        .update(db.gitHubConnections)
        .replace(
          connection.copyWith(
            githubApiBaseUrl: 'https://github.example:8443/api/v3',
          ),
        );

    final response = await post(
      respond: (request) => switch (request.method) {
        'GET' => http.Response(jsonEncode({'id': 54321}), 200),
        'POST' => http.Response(jsonEncode({'token': 'test-token'}), 200),
        _ => http.Response('{}', 200),
      },
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(jsonDecode(response.body), {'success': true});
    expect(githubRequests.map((request) => request.url.toString()), [
      'https://github.example:8443/api/v3/repos/owner/repo/installation',
      'https://github.example:8443/api/v3/app/installations/54321/access_tokens',
      'https://github.example:8443/api/v3/repos/owner/repo/check-runs/99999',
    ]);
    expect(githubRequests.last.method, 'PATCH');
    expect(githubRequests.last.headers['authorization'], 'Bearer test-token');
  });
}
