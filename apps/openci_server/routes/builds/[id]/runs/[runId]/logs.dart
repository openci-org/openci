import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';

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
    final db = context.read<AppDatabase>();
    final driftRun = await db.buildRunDao.getBuildRun(id, runId);
    if (driftRun == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Build run not found'},
      );
    }

    final queryParams = context.request.uri.queryParameters;
    final limitStr = queryParams['limit'] ?? '';
    final limit = int.tryParse(limitStr) ?? 10000;
    final offset = int.tryParse(queryParams['offset'] ?? '') ?? 0;

    final logs = await db.buildJobDao.getBuildJobLogs(runId);
    final rawText = logs.map((l) => l.logContent).join('');
    final allLines = rawText
        .split('\n')
        .where((line) => line.isNotEmpty)
        .toList();

    final start = offset;
    final bool hasMore;
    final List<String> slicedLines;
    if (limitStr == 'all' || limit <= 0) {
      slicedLines = allLines.sublist(start.clamp(0, allLines.length));
      hasMore = false;
    } else {
      final end = start + limit;
      slicedLines = allLines.sublist(
        start.clamp(0, allLines.length),
        end.clamp(0, allLines.length),
      );
      hasMore = end < allLines.length;
    }

    var logText = slicedLines.join('\n');
    if (slicedLines.isNotEmpty) {
      logText += '\n';
    }

    return Response(
      body: logText,
      headers: {
        'content-type': 'text/plain; charset=utf-8',
        'x-total-lines': allLines.length.toString(),
        'x-has-more': hasMore.toString(),
      },
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to read logs for run $runId',
    );
  }
}

Future<Response> _post(
  RequestContext context,
  String id,
  String runId,
) async {
  try {
    final db = context.read<AppDatabase>();
    final driftRun = await db.buildRunDao.getBuildRun(id, runId);
    if (driftRun == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Build run not found'},
      );
    }

    final Map<String, dynamic> payload;
    try {
      payload = await context.jsonBody();
    } on BadRequestException catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': e.message},
      );
    }

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
      await db.buildJobDao.insertBuildJobLog(runId, logBuffer.toString());
    }

    return Response.json(body: {'success': true});
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to append logs for run $runId',
    );
  }
}
