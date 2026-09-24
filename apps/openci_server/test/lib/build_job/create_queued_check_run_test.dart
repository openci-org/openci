import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:openci_server/build_job/create_queued_check_run.dart';
import 'package:openci_server/database.dart';
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

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now().toUtc();
    job = DriftBuildJob(
      id: 'job-1',
      status: BuildJobStatus.QUEUED,
      owner: 'org',
      repo: 'mobile',
      workflowName: 'CI',
      workflowFileName: 'ci.dart',
      installationId: '98765',
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
    client = _TrackingClient((request) async {
      if (request.url.path.endsWith('/access_tokens')) {
        return http.Response('{"token":"test-token"}', HttpStatus.created);
      }
      return checkResponse.future;
    });
    addTearDown(client.close);
  });

  test('closes its HTTP client after saving the queued Check', () async {
    checkResponse.complete(http.Response('{"id":99999}', HttpStatus.created));

    await http.runWithClient(
      () => createQueuedCheckRun(db: db, job: job, environment: environment),
      () => client,
    );

    expect(client.closed, isTrue);
    expect((await db.buildJobDao.getBuildJob(job.id))!.checkRunId, '99999');
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
      await http.runWithClient(
        () => createQueuedCheckRun(
          db: db,
          job: job,
          environment: environment,
          timeout: const Duration(milliseconds: 20),
        ),
        () => client,
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
