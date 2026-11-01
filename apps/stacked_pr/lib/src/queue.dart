import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'models.dart';

/// Durable delivery and bounded retries, without storing PR state or git objects.
class TaskQueue {
  TaskQueue({
    required this.client,
    required this.project,
    required this.workerUrl,
    required this.serviceAccount,
    required this.namespace,
    this.location = 'asia-northeast1',
    this.queue = 'stacked-pr',
    this.notBefore,
  });
  final http.Client client;
  final String project, location, queue, serviceAccount, namespace;
  final Uri workerUrl;
  final DateTime? notBefore;

  static Future<TaskQueue> fromEnvironment(Map<String, String> env) async {
    String required(String name) {
      final value = env[name];
      if (value == null || value.isEmpty) throw StateError('Missing $name');
      return value;
    }

    final url = Uri.parse(required('STACKED_PR_WORKER_URL'));
    final resumeAt = env['STACKED_PR_RESUME_AT']?.trim() ?? '';
    if (url.scheme != 'https' ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        url.hasQuery ||
        url.hasFragment) {
      throw StateError('STACKED_PR_WORKER_URL must be an HTTPS function URL');
    }
    return TaskQueue(
      client: await clientViaApplicationDefaultCredentials(
        scopes: ['https://www.googleapis.com/auth/cloud-platform'],
      ),
      project: required('GCLOUD_PROJECT'),
      workerUrl: url,
      serviceAccount: required('STACKED_PR_TASK_SERVICE_ACCOUNT'),
      namespace: '${required('GITHUB_URL')}:${required('GITHUB_APP_ID')}',
      notBefore: resumeAt.isEmpty ? null : DateTime.parse(resumeAt).toUtc(),
    );
  }

  Future<bool> enqueue(Job job) async {
    final id = sha256.convert(utf8.encode('$namespace:${job.id}')).toString();
    final parent = 'projects/$project/locations/$location/queues/$queue';
    final payload = utf8.encode(
      jsonEncode({'id': job.id, 'event': job.event, 'payload': job.payload}),
    );
    if (payload.length > 128 * 1024) throw const FormatException('Task too large');
    final response = await client
        .post(
          Uri.https('cloudtasks.googleapis.com', '/v2/$parent/tasks'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'task': {
              'name': '$parent/tasks/$id',
              'dispatchDeadline': '600s',
              if (notBefore != null && notBefore!.isAfter(DateTime.now()))
                'scheduleTime': notBefore!.toUtc().toIso8601String(),
              'httpRequest': {
                'httpMethod': 'POST',
                'url': workerUrl.toString(),
                'headers': {'Content-Type': 'application/json'},
                'body': base64Encode(payload),
                'oidcToken': {
                  'serviceAccountEmail': serviceAccount,
                  'audience': workerUrl.toString(),
                },
              },
            },
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 409) return false;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const RetryException('Task enqueue failed');
    }
    return true;
  }

  void close() => client.close();
}
