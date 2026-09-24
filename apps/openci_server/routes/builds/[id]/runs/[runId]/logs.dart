import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/logging/loki_service.dart';
import 'package:openci_server/request/error_handler.dart';

FutureOr<Response> onRequest(
  RequestContext context,
  String id,
  String runId,
) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id, runId),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(
  RequestContext context,
  String id,
  String runId,
) async {
  try {
    final db = context.read<AppDatabase>();
    final buildRun = await db.buildRunDao.getBuildRun(id, runId);
    if (buildRun == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Build run not found'},
      );
    }

    final lokiService = _readLokiService(context);
    final lokiLogs = await lokiService.getLogsForRun(runId: runId);
    return Response.json(body: lokiLogs);
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to read all logs for build $id run $runId',
    );
  }
}

LokiService _readLokiService(RequestContext context) {
  try {
    return context.read<LokiService>();
  } catch (_) {
    return LokiService();
  }
}
