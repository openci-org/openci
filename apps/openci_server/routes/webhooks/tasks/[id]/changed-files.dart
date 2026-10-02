import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/database.dart';
import 'package:openci_server/github/changed_files.dart';
import 'package:openci_server/request/error_handler.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  try {
    final task = await context
        .read<AppDatabase>()
        .webhookTaskDao
        .getWebhookTask(
          id,
        );
    if (task == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'WebhookTask not found'},
      );
    }
    Map<String, String>? environment;
    http.Client? client;
    try {
      environment = context.read<Map<String, String>>();
    } catch (_) {
      // Use the process environment when no override is provided.
    }
    try {
      client = context.read<http.Client>();
    } catch (_) {
      // Fetching owns its HTTP client when none is provided.
    }
    final result = await fetchChangedFiles(
      eventType: task.eventType,
      payload: task.payload,
      environment: environment,
      client: client,
    );
    return Response.json(body: result.toJson());
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to fetch changed files for webhook task $id',
    );
  }
}
