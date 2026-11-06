import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'plan_jobs.dart';
import 'planning_event.dart';

class PlanningTask {
  const PlanningTask(this.id, this.eventType, this.payload, this.status);
  final String id;
  final String eventType;
  final String payload;
  final String status;
}

class PlanningConnection {
  const PlanningConnection(this.id, this.accountId, this.teamId);
  final String id;
  final String accountId;
  final String teamId;
}

class PlanningFence {
  const PlanningFence(this.id, this.token);
  final String id;
  final String token;
}

abstract interface class PlanningStore {
  Future<PlanningTask?> getTask(String id);
  Future<PlanningConnection?> findConnection(int installationId);
  Future<PlanningFence> beginPullRequestPlanning(
    String taskId,
    PlanningEvent event,
    PlanningConnection connection,
  );
  Future<void> complete(
    String id,
    PlanningEvent? event,
    PlanningConnection? connection,
    WorkflowPlan plan, {
    PlanningFence? fence,
  });
  Future<void> reject(String id, String reason);
}

/// Calls the same privileged connector operations as the Node Admin SDK.
/// The supplied HTTP client carries ADC in production; no user impersonation.
class DataConnectPlanningStore implements PlanningStore {
  DataConnectPlanningStore({
    required this.client,
    required this.serviceUri,
    required this.githubAppId,
    required this.githubApiBaseUrl,
    required this.githubBaseUrl,
  });

  final http.Client client;
  final Uri serviceUri;
  final String githubAppId;
  final String githubApiBaseUrl;
  final String githubBaseUrl;

  Future<Map<String, dynamic>> _execute(
    String connector,
    String operation,
    Map<String, Object?> variables, {
    bool mutation = false,
  }) async {
    final method = mutation ? 'impersonateMutation' : 'impersonateQuery';
    final request =
        http.Request(
            'POST',
            Uri.parse('$serviceUri/connectors/$connector:$method'),
          )
          ..followRedirects = false
          ..headers['content-type'] = 'application/json'
          ..body = jsonEncode({
            'operationName': operation,
            'variables': variables,
            'extensions': <String, Object?>{},
          });
    final response = await client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) throw StateError('SQL Connect unavailable');
    final Object? result = jsonDecode(response.body);
    if (result is! Map<String, dynamic> ||
        (result['errors'] is List && (result['errors'] as List).isNotEmpty) ||
        result['data'] is! Map<String, dynamic>) {
      throw StateError('SQL Connect operation failed');
    }
    return result['data'] as Map<String, dynamic>;
  }

  @override
  Future<PlanningTask?> getTask(String id) async {
    final data = await _execute('webhooks', 'GetWebhookTask', {'id': id});
    final task = data['webhookTask'] as Map<String, dynamic>?;
    if (task == null) return null;
    return PlanningTask(
      task['id'] as String,
      task['eventType'] as String,
      task['payload'] as String,
      task['status'] as String,
    );
  }

  @override
  Future<PlanningConnection?> findConnection(int installationId) async {
    final data = await _execute('github', 'GetActiveGitHubConnection', {
      'githubAppId': githubAppId,
      'githubApiBaseUrl': githubApiBaseUrl,
      'installationId': installationId.toString(),
    });
    final connection = data['connection'] as Map<String, dynamic>?;
    if (connection == null) return null;
    return PlanningConnection(
      connection['id'] as String,
      connection['accountId'] as String,
      connection['teamId'] as String,
    );
  }

  @override
  Future<PlanningFence> beginPullRequestPlanning(
    String taskId,
    PlanningEvent event,
    PlanningConnection connection,
  ) async {
    final id = sha256
        .convert(
          utf8.encode(
            jsonEncode([
              connection.id,
              event.repositoryId,
              event.webhook.pullRequestNumber,
            ]),
          ),
        )
        .toString();
    final random = Random.secure();
    final token = base64UrlEncode(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    await _execute('webhooks', 'BeginPullRequestPlanning', {
      'id': id,
      'taskId': taskId,
      'connectionId': connection.id,
      'repositoryId': event.repositoryId.toString(),
      'pullRequestNumber': event.webhook.pullRequestNumber.toString(),
      'token': token,
    }, mutation: true);
    return PlanningFence(id, token);
  }

  @override
  Future<void> complete(
    String id,
    PlanningEvent? event,
    PlanningConnection? connection,
    WorkflowPlan plan, {
    PlanningFence? fence,
  }) async {
    final webhook = event?.webhook;
    // Delivery IDs identify transport attempts, not logical PR validation.
    // Missing base metadata cannot establish equivalence; retain task identity.
    final prIdentity =
        webhook?.pullRequestNumber != null &&
            event?.baseSha != null &&
            connection != null
        ? [
            'pr-webhook-v1',
            githubAppId,
            githubApiBaseUrl,
            githubBaseUrl,
            connection.id,
            connection.teamId,
            webhook!.installationId,
            event!.repositoryId,
            webhook.owner.toLowerCase(),
            webhook.repo.toLowerCase(),
            webhook.pullRequestNumber,
            webhook.commitSha,
            webhook.branch,
            webhook.triggerBranch,
            event.baseSha,
          ]
        : null;
    String digest(List<Object?> identity) =>
        sha256.convert(utf8.encode(jsonEncode(identity))).toString();
    await _execute('webhooks', 'CompleteWebhookTask', {
      'id': id,
      'jobCount': plan.jobs.length,
      'jobsJson': jsonEncode([
        for (final job in plan.jobs)
          {
            'id': sha256
                .convert(utf8.encode(jsonEncode([id, job.workflowFileName])))
                .toString(),
            'name': job.workflowName,
            'file': job.workflowFileName,
            'cancelPreviousRuns': plan.autoCancelWorkflowFiles.contains(
              job.workflowFileName,
            ),
            if (prIdentity != null)
              'webhookExecutionKey': digest([
                ...prIdentity,
                'job',
                job.workflowFileName,
                job.workflowName,
                job.flutterVersion,
                job.runsOn,
                plan.autoCancelWorkflowFiles.contains(job.workflowFileName),
              ]),
            if (job.flutterVersion != null)
              'flutterVersion': job.flutterVersion,
          },
      ]),
      'skippedCount': plan.skipped.length,
      'skippedJson': jsonEncode([
        for (final workflow in plan.skipped)
          {
            'id': digest(
              prIdentity == null
                  ? [id, workflow.workflowFileName, 'skipped']
                  : [
                      ...prIdentity,
                      'skipped',
                      workflow.workflowFileName,
                      workflow.workflowName,
                      plan.comparisonBaseSha,
                    ],
            ),
            'name': workflow.workflowName,
            'file': workflow.workflowFileName,
          },
      ]),
      'pathFilterReason': plan.pathFilterReason,
      'comparisonBaseSha': plan.comparisonBaseSha,
      'connectionId': connection?.id,
      'owner': webhook?.owner,
      'repo': webhook?.repo,
      'commitSha': webhook?.commitSha,
      'branch': webhook?.branch,
      'commitMessage': webhook?.commitMessage,
      'pullRequestNumber': webhook?.pullRequestNumber?.toString(),
      'githubBaseUrl': githubBaseUrl,
      'planningId': fence?.id,
      'planningToken': fence?.token,
    }, mutation: true);
  }

  @override
  Future<void> reject(String id, String reason) async {
    await _execute('webhooks', 'RejectWebhookTask', {
      'id': id,
      'reason': reason,
    }, mutation: true);
  }
}
