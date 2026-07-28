import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
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
    final steps = await db.buildJobDao.getBuildSteps(runId);

    final List<String> allLines = [];

    for (final step in steps) {
      allLines.add('=== ${step.name} ===');
      final dbKey = step.id.startsWith(runId) ? step.id : '${runId}_${step.id}';
      final stepLogs = await db.buildJobDao.getBuildStepLogs(dbKey);
      final rawText = stepLogs.map((l) => l.logContent).join('');
      final stepLines = rawText
          .split('\n')
          .where((line) => line.isNotEmpty)
          .toList();

      if (stepLines.isEmpty) {
        allLines.add('No logs available.');
      } else {
        allLines.addAll(stepLines);
      }
      allLines.add('');
    }

    return Response.json(body: allLines);
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to read all logs for build $id run $runId',
    );
  }
}
