import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/logging/loki_service.dart';
import 'package:openci_server/request/error_handler.dart';

FutureOr<Response> onRequest(
  RequestContext context,
  String id,
  String runId,
  String stepId,
) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id, runId, stepId),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(
  RequestContext context,
  String id,
  String runId,
  String stepId,
) async {
  try {
    final lokiService = LokiService();
    final logs = await lokiService.getLogsForRun(
      runId: runId,
      stepId: stepId,
    );
    return Response.json(body: logs);
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to read logs for step $stepId',
    );
  }
}
