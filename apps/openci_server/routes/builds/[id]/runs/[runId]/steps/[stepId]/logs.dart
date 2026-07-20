import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
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
    final db = context.read<AppDatabase>();
    final driftLogs = await db.buildJobDao.getBuildStepLogs(stepId);

    final rawText = driftLogs.map((l) => l.logContent).join('');
    final List<String> lines = rawText
        .split('\n')
        .where((line) => line.isNotEmpty)
        .toList();

    return Response.json(body: lines);
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to read logs for step $stepId',
    );
  }
}
