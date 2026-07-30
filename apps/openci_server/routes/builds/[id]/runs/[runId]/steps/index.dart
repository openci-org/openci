import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/logging/loki_service.dart';
import 'package:openci_server/request/error_handler.dart';

FutureOr<Response> onRequest(
  RequestContext context,
  String id,
  String runId,
) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id, runId),
    HttpMethod.post => _post(context, id, runId),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(
  RequestContext context,
  String id,
  String runId,
) async {
  try {
    final lokiService = LokiService();
    final steps = await lokiService.getStepSummariesForRun(runId: runId);

    return Response.json(body: steps);
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to read steps for run $runId',
    );
  }
}

Future<Response> _post(
  RequestContext context,
  String id,
  String runId,
) async {
  return Response.json(body: {'success': true, 'deprecated': true});
}
