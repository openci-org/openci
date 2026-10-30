import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';

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

abstract interface class PlanningStore {
  Future<PlanningTask?> getTask(String id);
  Future<PlanningConnection?> findConnection(int installationId);
  Future<void> complete(
    String id,
    PlanningEvent? event,
    PlanningConnection? connection,
    List<BuildJobPlan> jobs,
  );
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
  Future<void> complete(
    String id,
    PlanningEvent? event,
    PlanningConnection? connection,
    List<BuildJobPlan> jobs,
  ) async {
    final webhook = event?.webhook;
    await _execute('webhooks', 'CompleteWebhookTask', {
      'id': id,
      'jobCount': jobs.length,
      'jobsJson': jsonEncode([
        for (final job in jobs)
          {
            'id': sha256
                .convert(utf8.encode(jsonEncode([id, job.workflowFileName])))
                .toString(),
            'name': job.workflowName,
            'file': job.workflowFileName,
          },
      ]),
      'connectionId': connection?.id,
      'owner': webhook?.owner,
      'repo': webhook?.repo,
      'commitSha': webhook?.commitSha,
      'branch': webhook?.branch,
      'commitMessage': webhook?.commitMessage,
      'pullRequestNumber': webhook?.pullRequestNumber?.toString(),
      'githubBaseUrl': githubBaseUrl,
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
