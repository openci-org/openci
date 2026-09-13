import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/logging/loki_service.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';

FutureOr<Response> onRequest(
  RequestContext context,
  String id,
  String runId,
  String stepId,
) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id, runId, stepId),
    HttpMethod.post => _post(context, id, runId, stepId),
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

Future<Response> _post(
  RequestContext context,
  String id,
  String runId,
  String stepId,
) async {
  try {
    final db = context.read<AppDatabase>();
    final payload = await context.jsonBody();

    final logs = payload['logs'] as List<dynamic>? ?? [];
    final StringBuffer logBuffer = StringBuffer();
    for (final log in logs) {
      if (log is Map) {
        final message = log['message'] as String?;
        if (message != null) {
          logBuffer.write('$message\n');
        }
      }
    }

    if (logBuffer.isNotEmpty) {
      final dbKey = stepId.startsWith(runId) ? stepId : '${runId}_$stepId';
      await db.buildJobDao.insertBuildStepLog(dbKey, logBuffer.toString());
    }

    return Response.json(body: {'success': true});
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to append logs for step $stepId',
    );
  }
}
