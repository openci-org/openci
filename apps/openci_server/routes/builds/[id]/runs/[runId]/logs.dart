import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';

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

    final logs = await db.buildJobDao.getBuildJobLogs(runId);
    final logText = logs.map((l) => l.logContent).join('');

    return Response(
      body: logText,
      headers: {
        'content-type': 'text/plain; charset=utf-8',
      },
    );
  } catch (e, s) {
    stderr.writeln('Failed to read logs for run $runId: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Internal server error',
      },
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
      final body = await context.request.body();
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Body must be a JSON object');
      }
      payload = decoded;
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Invalid JSON'},
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
    stderr.writeln('Failed to append logs for run $runId: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Internal server error',
      },
    );
  }
}
