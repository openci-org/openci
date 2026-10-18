import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:openci_server/build_job/create_queued_check_run.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../helpers/github_app_test_key.dart';

void main() {
  late AppDatabase db;
  late DriftBuildJob job;
  late Map<String, String> environment;
  late _TrackingClient client;
  late Completer<http.Response> checkResponse;
  late List<http.Request> requests;
  var repositoryInstallationId = 98765;
  var lookupStatus = HttpStatus.ok;
  var tokenStatus = HttpStatus.created;
  var token = 'test-token';
  Completer<http.Response>? pendingLookup;

  final connection = DriftGitHubConnection(
    id: 'connection-1',
    teamId: 'team-1',
    githubApiBaseUrl: 'https://api.github.test',
    githubAppId: 123456,
    installationId: 98765,
    accountId: 42,
    accountType: GitHubAccountType.organization,
    accountLogin: 'org',
    verifiedByUserId: 'user-1',
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
    addTearDown(db.close);
    final now = DateTime.now().toUtc();
    await db.teamDao.createTeamAndMember(
      DriftTeam(
        id: 'team-1',
        name: 'OpenCI',
        installationIds: const [],
        aiEnabled: false,
        runNumber: 1,
        createdAt: now,
        updatedAt: now,
      ),
      'user-1',
    );
    await db.into(db.gitHubConnections).insert(connection);
    job = DriftBuildJob(
      id: 'job-1',
      status: BuildJobStatus.QUEUED,
      owner: 'org',
      repo: 'mobile',
      workflowName: 'CI',
      workflowFileName: 'ci.dart',
      teamId: 'team-1',
      installationId: '98765',
      githubBaseUrl: 'https://untrusted.example',
      commitSha: 'abc123',
      createdAt: now,
      updatedAt: now,
    );
    await db.buildJobDao.insertBuildJob(job);
    final directory = await Directory.systemTemp.createTemp(
      'queued_check_client_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final keyFile = File.fromUri(directory.uri.resolve('key.pem'));
    await keyFile.writeAsString(testRsaPrivateKey);
    environment = {
      'GITHUB_APP_ID': '123456',
      'GITHUB_PRIVATE_KEY_PATH': keyFile.path,
      'GITHUB_API_BASE_URL': 'https://api.github.test',
    };
    checkResponse = Completer<http.Response>();
    requests = [];
    repositoryInstallationId = 98765;
    lookupStatus = HttpStatus.ok;
    tokenStatus = HttpStatus.created;
    token = 'test-token';
    pendingLookup = null;
    client = _TrackingClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/installation')) {
        if (pendingLookup != null) return pendingLookup!.future;
        return http.Response(
          jsonEncode({'id': repositoryInstallationId}),
          lookupStatus,
        );
      }
      if (request.url.path.endsWith('/access_tokens')) {
        return http.Response(jsonEncode({'token': token}), tokenStatus);
      }
      if (request.url.path.endsWith('/check-runs')) return checkResponse.future;
      return http.Response('Unexpected GitHub request', 500);
    });
    addTearDown(client.close);
  });

  Future<void> createCheck() => createQueuedCheckRun(
    db: db,
    job: job,
    environment: environment,
    client: client,
  );

  Future<void> expectNoCheck() async {
    expect((await db.buildJobDao.getBuildJob(job.id))!.checkRunId, isNull);
  }

  Future<void> expectConnectionRejected(
    DriftGitHubConnection rejectedConnection,
  ) async {
    await db.update(db.gitHubConnections).replace(rejectedConnection);

    await expectLater(createCheck(), throwsStateError);

    expect(requests, isEmpty);
    await expectNoCheck();
  }

  test('closes its HTTP client after saving the queued Check', () async {
    checkResponse.complete(http.Response('{"id":99999}', HttpStatus.created));

    await http.runWithClient(
      () => createQueuedCheckRun(db: db, job: job, environment: environment),
      () => client,
    );

    expect(client.closed, isTrue);
    expect((await db.buildJobDao.getBuildJob(job.id))!.checkRunId, '99999');
    expect(requests.map((request) => request.method), ['GET', 'POST', 'POST']);
    expect(requests.map((request) => request.url.toString()), [
      'https://api.github.test/repos/org/mobile/installation',
      'https://api.github.test/app/installations/98765/access_tokens',
      'https://api.github.test/repos/org/mobile/check-runs',
    ]);
    expect(requests.last.headers['authorization'], 'Bearer test-token');
    expect(jsonDecode(requests.last.body), {
      'name': 'CI',
      'head_sha': 'abc123',
      'external_id': 'job-1',
      'status': 'queued',
    });
  });

  test('leaves a supplied HTTP client open', () async {
    checkResponse.complete(http.Response('{"id":99999}', HttpStatus.created));

    await createQueuedCheckRun(
      db: db,
      job: job,
      environment: environment,
      client: client,
    );

    expect(client.closed, isFalse);
    expect((await db.buildJobDao.getBuildJob(job.id))!.checkRunId, '99999');
  });

  test(
    'times out and closes the client so a stalled request cannot block a build',
    () async {
      await expectLater(
        http.runWithClient(
          () => createQueuedCheckRun(
            db: db,
            job: job,
            environment: environment,
            timeout: const Duration(milliseconds: 20),
          ),
          () => client,
        ),
        throwsA(isA<TimeoutException>()),
      );

      expect(client.closed, isTrue);
      final stored = (await db.buildJobDao.getBuildJob(job.id))!;
      expect(stored.checkRunId, isNull);
      expect(stored.status, BuildJobStatus.QUEUED);
      checkResponse.complete(
        http.Response('Client closed', HttpStatus.serviceUnavailable),
      );
    },
  );

  test('preserves an existing Check without contacting GitHub', () async {
    job = job.copyWith(checkRunId: const Value('existing-check'));
    await db.buildJobDao.updateBuildJob(job);
    final noRequests = MockClient((_) async => fail('No request expected'));
    addTearDown(noRequests.close);

    await createQueuedCheckRun(
      db: db,
      job: job,
      environment: environment,
      client: noRequests,
    );

    expect(
      (await db.buildJobDao.getBuildJob(job.id))!.checkRunId,
      'existing-check',
    );
  });

  test('rejects a legacy installation without a verified connection', () async {
    final team = (await db.teamDao.getTeam('team-1'))!;
    await db.teamDao.updateTeam(team.copyWith(installationIds: [98765]));
    await db.delete(db.gitHubConnections).go();

    await expectLater(createCheck(), throwsStateError);

    expect(requests, isEmpty);
    await expectNoCheck();
  });

  test('rejects another team\'s connection', () async {
    final team = (await db.teamDao.getTeam('team-1'))!;
    await db.teamDao.createTeamAndMember(
      team.copyWith(id: 'team-2'),
      'user-2',
    );
    await expectConnectionRejected(connection.copyWith(teamId: 'team-2'));
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

  test('rejects a connection for another API host', () async {
    await expectConnectionRejected(
      connection.copyWith(githubApiBaseUrl: 'https://other.example/api/v3'),
    );
  });

  test('rejects a connection for another App', () async {
    await expectConnectionRejected(connection.copyWith(githubAppId: 999));
  });

  test('rejects a repository belonging to another installation', () async {
    repositoryInstallationId = 54321;

    await expectLater(createCheck(), throwsStateError);

    expect(requests.single.url.path, '/repos/org/mobile/installation');
    await expectNoCheck();
  });

  test('propagates GitHub repository lookup failures', () async {
    lookupStatus = HttpStatus.forbidden;

    await expectLater(createCheck(), throwsA(isA<HttpException>()));

    expect(requests.single.url.path, '/repos/org/mobile/installation');
    expect(client.closed, isFalse);
    await expectNoCheck();
  });

  test('propagates token issuance failures without creating a Check', () async {
    tokenStatus = HttpStatus.forbidden;

    await expectLater(createCheck(), throwsA(isA<HttpException>()));

    expect(requests.map((request) => request.url.path), [
      '/repos/org/mobile/installation',
      '/app/installations/98765/access_tokens',
    ]);
    await expectNoCheck();
  });

  test('rejects empty tokens without creating a Check', () async {
    token = ' ';

    await expectLater(createCheck(), throwsFormatException);

    expect(requests, hasLength(2));
    await expectNoCheck();
  });

  test('propagates Check creation failures and closes its client', () async {
    checkResponse.complete(http.Response('Forbidden', HttpStatus.forbidden));

    await expectLater(
      http.runWithClient(
        () => createQueuedCheckRun(db: db, job: job, environment: environment),
        () => client,
      ),
      throwsA(isA<HttpException>()),
    );

    expect(client.closed, isTrue);
    expect(requests.last.url.path, '/repos/org/mobile/check-runs');
    await expectNoCheck();
  });

  test('rejects a job without a team', () async {
    job = job.copyWith(teamId: const Value(null));

    await expectLater(createCheck(), throwsStateError);

    expect(requests, isEmpty);
    await expectNoCheck();
  });

  test('rejects a job without an installation', () async {
    job = job.copyWith(installationId: const Value(null));

    await expectLater(createCheck(), throwsStateError);

    expect(requests, isEmpty);
    await expectNoCheck();
  });

  test('rejects a nonnumeric installation', () async {
    job = job.copyWith(installationId: const Value('invalid'));

    await expectLater(createCheck(), throwsStateError);

    expect(requests, isEmpty);
    await expectNoCheck();
  });

  test('rejects a nonpositive installation', () async {
    job = job.copyWith(installationId: const Value('0'));

    await expectLater(createCheck(), throwsStateError);

    expect(requests, isEmpty);
    await expectNoCheck();
  });

  test('rejects a job without a commit SHA', () async {
    job = job.copyWith(commitSha: const Value(''));

    await expectLater(createCheck(), throwsStateError);

    expect(requests, isEmpty);
    await expectNoCheck();
  });

  test('requires valid operator configuration', () async {
    environment.remove('GITHUB_APP_ID');

    await expectLater(createCheck(), throwsStateError);

    expect(requests, isEmpty);
    await expectNoCheck();
  });

  test('propagates database failures before contacting GitHub', () async {
    await db.customStatement('DROP TABLE github_connections');

    await expectLater(createCheck(), throwsStateError);

    expect(requests, isEmpty);
    await expectNoCheck();
  });

  test('creates a real Check for the former dummy installation', () async {
    job = job.copyWith(installationId: const Value('12345678'));
    await db.buildJobDao.updateBuildJob(job);
    await db
        .update(db.gitHubConnections)
        .replace(
          connection.copyWith(installationId: 12345678),
        );
    repositoryInstallationId = 12345678;
    checkResponse.complete(http.Response('{"id":99999}', HttpStatus.created));

    await createCheck();

    expect(requests[1].url.path, '/app/installations/12345678/access_tokens');
    expect((await db.buildJobDao.getBuildJob(job.id))!.checkRunId, '99999');
  });

  test(
    'uses the normalized operator URL instead of the saved job URL',
    () async {
      environment['GITHUB_API_BASE_URL'] = 'https://ghe.example:8443/api/v3///';
      await db
          .update(db.gitHubConnections)
          .replace(
            connection.copyWith(
              githubApiBaseUrl: 'https://ghe.example:8443/api/v3',
            ),
          );
      checkResponse.complete(http.Response('{"id":99999}', HttpStatus.created));

      await createCheck();

      expect(requests.map((request) => request.url.toString()), [
        'https://ghe.example:8443/api/v3/repos/org/mobile/installation',
        'https://ghe.example:8443/api/v3/app/installations/98765/access_tokens',
        'https://ghe.example:8443/api/v3/repos/org/mobile/check-runs',
      ]);
    },
  );

  test(
    'does not issue a token after the repository lookup times out',
    () async {
      pendingLookup = Completer<http.Response>();

      await expectLater(
        http.runWithClient(
          () => createQueuedCheckRun(
            db: db,
            job: job,
            environment: environment,
            timeout: const Duration(milliseconds: 20),
          ),
          () => client,
        ),
        throwsA(isA<TimeoutException>()),
      );

      expect(client.closed, isTrue);
      pendingLookup!.complete(http.Response('{"id":98765}', HttpStatus.ok));
      await Future<void>.delayed(Duration.zero);
      expect(requests.single.url.path, '/repos/org/mobile/installation');
      await expectNoCheck();
    },
  );
}

class _TrackingClient extends MockClient {
  _TrackingClient(super.fn);

  bool closed = false;

  @override
  void close() {
    closed = true;
    super.close();
  }
}
