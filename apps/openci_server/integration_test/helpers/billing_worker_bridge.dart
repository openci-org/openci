import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift_postgres/drift_postgres.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/auth/internal_api_middleware.dart';
import 'package:openci_server/billing/billing_proxy.dart';
import 'package:openci_server/billing/billing_proxy_config.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../../routes/builds/[id]/_middleware.dart' as build_middleware;
import '../../routes/builds/[id]/index.dart' as job_route;
import '../../routes/builds/[id]/runs/index.dart' as run_route;
import '../../routes/worker/billing/report.dart' as report_route;
import '../../routes/worker/billing/start.dart' as start_route;
import '../../routes/worker/jobs/claim.dart' as claim_route;
import '../../test/helpers/github_app_test_key.dart';

class BillingWorkerBridge {
  BillingWorkerBridge(this.db, this.uri, this.client, this.proxy);

  static const serviceToken = 'bridge-service-token-01234567890123456789';
  final AppDatabase db;
  final Uri uri;
  final http.Client client;
  final BillingProxy proxy;

  static Future<BillingWorkerBridge> create(
    String databaseUrl,
    String binary,
  ) async {
    final connection = await pg.Connection.openFromUrl(databaseUrl);
    addTearDown(connection.close);
    final schema = 'billing_bridge_${const Uuid().v4().replaceAll('-', '')}';
    await connection.execute('CREATE SCHEMA "$schema"');
    addTearDown(() => connection.execute('DROP SCHEMA "$schema" CASCADE'));
    await connection.execute('SET search_path TO "$schema"');
    final db = AppDatabase(PgDatabase.opened(connection));
    addTearDown(db.close);
    final now = DateTime.now().toUtc();
    await db.teamDao.createTeamAndMember(
      DriftTeam(
        id: 'team-1',
        name: 'Bridge Team',
        installationIds: const [123],
        aiEnabled: false,
        runNumber: 1,
        createdAt: now,
        updatedAt: now,
      ),
      'user-1',
    );
    await db.customStatement("INSERT INTO billing_accounts VALUES ('team-1')");
    await db
        .into(db.billingPeriods)
        .insert(
          BillingPeriodsCompanion.insert(
            id: 'paid-1',
            teamId: 'team-1',
            planId: 'light',
            periodType: 'paid',
            startsAt: now.subtract(const Duration(minutes: 1)),
            endsAt: now.add(const Duration(days: 30)),
            allowanceSeconds: const Value(36000),
          ),
        );
    for (final id in ['job-1', 'job-2']) {
      await db.buildJobDao.insertBuildJob(
        DriftBuildJob(
          id: id,
          teamId: 'team-1',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'CI',
          workflowFileName: 'ci.dart',
          commitSha: 'sha',
          installationId: '123',
          checkRunId: '456',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    await db
        .into(db.gitHubConnections)
        .insert(
          DriftGitHubConnection(
            id: 'connection-1',
            teamId: 'team-1',
            githubApiBaseUrl: 'https://api.github.com',
            githubAppId: 1234,
            installationId: 123,
            accountId: 1,
            accountType: GitHubAccountType.organization,
            accountLogin: 'owner',
            verifiedByUserId: 'user-1',
            verifiedByGitHubUserId: 1,
            verifiedAt: now,
            status: GitHubConnectionStatus.active,
          ),
        );
    final url = Uri.parse(databaseUrl);
    final process = await Process.start(
      binary,
      [],
      includeParentEnvironment: false,
      environment: {
        'OPENCI_TEST_DATABASE_URL': url
            .replace(
              queryParameters: {...url.queryParameters, 'search_path': schema},
            )
            .toString(),
        'BILLING_INTERNAL_TOKEN': serviceToken,
      },
    );
    addTearDown(() async {
      process.kill();
      await process.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return process.exitCode;
        },
      );
    });
    final stderr = StringBuffer();
    process.stderr.transform(utf8.decoder).listen(stderr.write);
    final origin = await process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .first
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () =>
              throw StateError('Go fixture did not start: $stderr'),
        );
    final environment = <String, String>{
      'SERVER_ACCESS_MODE': 'cloud',
      'BILLING_ENABLED': 'true',
      'GENUINECI_SERVER_URL': origin,
      'BILLING_INTERNAL_TOKEN': serviceToken,
      'GITHUB_APP_ID': '1234',
      'GITHUB_API_BASE_URL': 'https://api.github.com',
    };
    final files = await Directory.systemTemp.createTemp('billing_bridge_key_');
    addTearDown(() => files.delete(recursive: true));
    final key = File('${files.path}/key.pem');
    await key.writeAsString(testRsaPrivateKey);
    environment['GITHUB_PRIVATE_KEY_PATH'] = key.path;
    final github = MockClient(
      (request) async => switch (request.url.path) {
        '/repos/owner/repo/installation' => http.Response('{"id":123}', 200),
        '/app/installations/123/access_tokens' => http.Response(
          '{"token":"test-token"}',
          200,
        ),
        '/repos/owner/repo/check-runs/456' => http.Response('{}', 200),
        _ => http.Response('Unexpected GitHub request', 500),
      },
    );
    addTearDown(github.close);
    final proxyClient = http.Client();
    addTearDown(proxyClient.close);
    final proxy = BillingProxy(
      BillingProxyConfig.fromEnvironment(environment)!,
      proxyClient,
    );
    await db.customStatement(
      "INSERT INTO billing_customer_creations VALUES ('team-1', 'key-1', false, 0, 'cus_1')",
    );
    await db.customStatement('''
      INSERT INTO billing_stripe_state (team_id, stripe_customer_id, livemode, stripe_subscription_id,
        subscription_status, plan_id, paid_period_id, synced_at)
      VALUES ('team-1', 'cus_1', false, 'sub_1', 'active', 'light', 'paid-1', 0)
    ''');
    Handler handler = (context) {
      final path = context.request.uri.path;
      final Handler action = switch (path) {
        '/worker/jobs/claim' => claim_route.onRequest,
        '/worker/billing/start' => start_route.onRequest,
        '/worker/billing/report' => report_route.onRequest,
        '/builds/job-1/runs' => (context) => run_route.onRequest(
          context,
          'job-1',
        ),
        '/builds/job-1' => (context) => job_route.onRequest(context, 'job-1'),
        _ => (_) => Response(statusCode: 404),
      };
      return path.startsWith('/builds/')
          ? action.use(build_middleware.middleware)(context)
          : action.use(internalApiMiddleware())(context);
    };
    handler = handler
        .use(provider<AppDatabase>((_) => db))
        .use(provider<Map<String, String>>((_) => environment))
        .use(provider<BillingProxy?>((_) => proxy))
        .use(provider<http.Client>((_) => github))
        .use(provider<String?>((_) => null))
        .use(
          provider<InternalApiKeyValidator>(
            (_) => const InternalApiKeyValidator(
              environment: {'INTERNAL_API_KEY': 'worker-key'},
            ),
          ),
        );
    final server = await serve(handler, InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final client = http.Client();
    addTearDown(client.close);
    return BillingWorkerBridge(
      db,
      Uri.parse('http://127.0.0.1:${server.port}'),
      client,
      proxy,
    );
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String method = 'POST',
    String token = 'worker-key',
    int expectedStatus = 200,
  }) async {
    final request = http.Request(method, uri.resolve(path))
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      })
      ..body = jsonEncode(body);
    final response = await client.send(request).then(http.Response.fromStream);
    expect(response.statusCode, expectedStatus, reason: response.body);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<BuildJob?> claim({String workerHost = 'worker-1'}) async {
    final result = await post('/worker/jobs/claim', {
      'workerHost': workerHost,
      'maxConcurrentJobs': 1,
    });
    return result['job'] == null
        ? null
        : BuildJob.fromJson(result['job'] as Map<String, dynamic>);
  }

  Map<String, dynamic> attempt(BuildJob job) => {
    'billingAdmissionId': job.billingAdmissionId,
    'workerHost': job.workerHost,
    'runId': 'run-1',
  };

  Map<String, dynamic> execution(BuildJob job) => {
    'admissionId': job.billingAdmissionId,
    'workerHost': job.workerHost,
    'runId': 'run-1',
    'jobId': job.id,
  };

  Future<Map<String, dynamic>> status() async {
    final response = await proxy.request(
      operation: BillingOperation.status,
      teamId: 'team-1',
      uid: 'user-1',
    );
    expect(response.statusCode, 200);
    return await response.json() as Map<String, dynamic>;
  }

  Future<void> bind(BuildJob job) async {
    final payload = attempt(job)..remove('runId');
    await post('/builds/job-1/runs', {...payload, 'id': 'run-1'});
  }
}
