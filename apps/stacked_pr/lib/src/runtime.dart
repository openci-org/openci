import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'config.dart';
import 'deadline.dart';
import 'github.dart';
import 'models.dart';
import 'queue.dart';
import 'report.dart';
import 'service.dart';
import 'webhook.dart';

Future<Response> receiveWebhook(Request request, Map<String, String> env) async {
  final secret = env['GITHUB_WEBHOOK_SECRET'];
  if (secret == null || secret.length < 32) return Response.internalServerError();
  TaskQueue? queue;
  try {
    return await WebhookReceiver((job) async {
      queue ??= await TaskQueue.fromEnvironment(env);
      return queue!.enqueue(job);
    }, secret).accept(request);
  } finally {
    queue?.close();
  }
}

/// Authentication is enforced by Cloud Run IAM (private invoker in functions.yaml).
/// The request headers alone are never treated as proof of Cloud Tasks identity.
Future<Response> processTask(Request request, Future<void> Function(Job) process) async {
  if (request.method != 'POST') return Response(405, headers: {'allow': 'POST'});
  final Job job;
  try {
    final bytes = <int>[];
    await for (final chunk in request.read().timeout(const Duration(seconds: 10))) {
      if (bytes.length + chunk.length > 128 * 1024) return Response(413);
      bytes.addAll(chunk);
    }
    final value = jsonDecode(utf8.decode(bytes));
    if (value is! Map<String, Object?> ||
        value['id'] is! String ||
        value['event'] is! String ||
        value['payload'] is! Map<String, Object?> ||
        !RegExp(r'^[\w-]{1,160}$').hasMatch(value['id'] as String)) {
      return Response(400);
    }
    job = Job(
      id: value['id'] as String,
      event: value['event'] as String,
      payload: jsonObject(value['payload']),
    );
  } on FormatException {
    return Response(400);
  }
  try {
    await process(job);
    return Response.ok('completed');
  } catch (_) {
    stderr.writeln(jsonEncode({'event': 'stack_task_failed', 'delivery': job.id}));
    return Response(503, body: 'retry');
  }
}

Future<void> runJob(Job job, Map<String, String> env) async {
  final directory = await Directory.systemTemp.createTemp('stacked-pr-');
  GitHubApi? api;
  TaskQueue? queue;
  try {
    final deadline = Deadline(const Duration(seconds: 420));
    final config = AppConfig.fromEnvironment({...env, 'DATA_DIR': directory.path});
    if (config.allowedRepos.isEmpty) {
      throw const FormatException('ALLOWED_REPOSITORIES must name the target repositories');
    }
    api = GitHubApi(config, deadline: deadline);
    await Service(
      config: config,
      api: api,
      reporter: Reporter(api),
      deadline: deadline,
      enqueue: (job) async {
        deadline.limit(const Duration(seconds: 8));
        queue ??= await TaskQueue.fromEnvironment(env);
        return queue!.enqueue(job);
      },
    ).handle(job);
  } finally {
    api?.close();
    queue?.close();
    await directory.delete(recursive: true);
  }
}
