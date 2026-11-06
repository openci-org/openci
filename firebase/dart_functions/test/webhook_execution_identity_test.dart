import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_dart_functions/src/data_connect.dart';
import 'package:openci_dart_functions/src/github_webhook_payload.dart';
import 'package:openci_dart_functions/src/plan_jobs.dart';
import 'package:openci_dart_functions/src/planning_event.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

const webhook = GitHubWebhookPayload(
  installationId: 30,
  eventType: 'pull_request',
  owner: 'org',
  repo: 'app',
  commitSha: 'head',
  branch: 'feature',
  triggerBranch: 'main',
  triggerType: 'pull_request',
  pullRequestNumber: 7,
);
const job = BuildJobPlan(
  owner: 'org',
  repo: 'app',
  workflowName: 'CI',
  workflowFileName: 'ci.dart',
  teamId: 'team',
  commitSha: 'head',
  branch: 'feature',
  runsOn: 'macos-latest',
  installationId: '30',
  pullRequestNumber: 7,
);

Future<Map<String, dynamic>> complete({
  String taskId = 'task',
  PlanningEvent event = const PlanningEvent(webhook, 10, 20, baseSha: 'base'),
  PlanningConnection connection = const PlanningConnection(
    'connection',
    '20',
    'team',
  ),
  BuildJobPlan build = job,
  String appId = '1',
  String apiUrl = 'https://api.github.com',
  String baseUrl = 'https://github.com',
  bool cancelPreviousRuns = false,
}) async {
  late Map<String, dynamic> variables;
  final store = DataConnectPlanningStore(
    client: MockClient((request) async {
      variables =
          (jsonDecode(request.body) as Map)['variables']
              as Map<String, dynamic>;
      return http.Response('{"data":{}}', 200);
    }),
    serviceUri: Uri.parse('https://sql.example.test'),
    githubAppId: appId,
    githubApiBaseUrl: apiUrl,
    githubBaseUrl: baseUrl,
  );
  await store.complete(
    taskId,
    event,
    connection,
    WorkflowPlan(
      jobs: [build],
      skipped: const [SkippedWorkflow('Skipped', 'skip.dart')],
      comparisonBaseSha: 'comparison',
      autoCancelWorkflowFiles: cancelPreviousRuns
          ? {build.workflowFileName}
          : {},
    ),
    fence: const PlanningFence('fence', 'token'),
  );
  return variables;
}

String? key(Map<String, dynamic> variables) =>
    (jsonDecode(variables['jobsJson'] as String) as List)
            .single['webhookExecutionKey']
        as String?;
String skippedId(Map<String, dynamic> variables) =>
    (jsonDecode(variables['skippedJson'] as String) as List).single['id']
        as String;

void main() {
  test(
    'different delivery IDs share execution and skipped-Check identities',
    () async {
      final first = await complete();
      final second = await complete(taskId: 'redelivery');
      expect(key(first), matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(key(second), key(first));
      expect(skippedId(second), skippedId(first));
      expect(
        jsonDecode(second['jobsJson'] as String)[0]['id'],
        isNot(jsonDecode(first['jobsJson'] as String)[0]['id']),
      );
      final renamed = await complete(
        event: PlanningEvent(
          webhook.copyWith(
            owner: 'ORG',
            repo: 'APP',
            commitMessage: 'New title',
          ),
          10,
          20,
          baseSha: 'base',
        ),
      );
      expect(key(renamed), key(first));
    },
  );

  test(
    'scope, revisions, target and execution configuration remain distinct',
    () async {
      final original = key(await complete());
      final alternatives = [
        complete(appId: '2'),
        complete(apiUrl: 'https://github.enterprise/api/v3'),
        complete(baseUrl: 'https://github.enterprise'),
        complete(connection: const PlanningConnection('other', '20', 'team')),
        complete(
          connection: const PlanningConnection('connection', '20', 'other'),
        ),
        complete(event: const PlanningEvent(webhook, 11, 20, baseSha: 'base')),
        complete(
          event: const PlanningEvent(webhook, 10, 20, baseSha: 'new-base'),
        ),
        for (final changed in [
          webhook.copyWith(installationId: 31),
          webhook.copyWith(repo: 'other'),
          webhook.copyWith(owner: 'other'),
          webhook.copyWith(pullRequestNumber: 8),
          webhook.copyWith(commitSha: 'other'),
          webhook.copyWith(triggerBranch: 'release'),
          webhook.copyWith(branch: 'renamed'),
        ])
          complete(event: PlanningEvent(changed, 10, 20, baseSha: 'base')),
        complete(build: job.copyWith(workflowFileName: 'other.dart')),
        complete(build: job.copyWith(workflowName: 'Other')),
        complete(build: job.copyWith(flutterVersion: '3.47.8')),
        complete(build: job.copyWith(runsOn: 'other-runner')),
        complete(cancelPreviousRuns: true),
      ];
      final keys = (await Future.wait(alternatives)).map(key).toSet();
      expect(keys, hasLength(alternatives.length));
      expect(keys, isNot(contains(original)));
    },
  );

  test(
    'pushes and incomplete PR base metadata retain delivery identity',
    () async {
      for (final event in [
        const PlanningEvent(webhook, 10, 20),
        PlanningEvent(
          webhook.copyWith(pullRequestNumber: null, eventType: 'push'),
          10,
          20,
          baseSha: 'base',
        ),
      ]) {
        final first = await complete(event: event);
        final second = await complete(event: event, taskId: 'second');
        expect(key(first), isNull);
        expect(skippedId(first), isNot(skippedId(second)));
      }
    },
  );
}
