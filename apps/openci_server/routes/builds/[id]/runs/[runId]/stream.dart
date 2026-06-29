import 'dart:async';
import 'dart:convert';
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
    final driftRun = await db.buildRunDao.getBuildRun(id, runId);
    if (driftRun == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Build run not found'},
      );
    }

    final sseStream = _createSseStream(db, id, runId);

    return Response.stream(
      body: sseStream,
      headers: {
        'content-type': 'text/event-stream; charset=utf-8',
        'cache-control': 'no-cache',
        'connection': 'keep-alive',
        'x-content-type-options': 'nosniff',
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

Stream<List<int>> _createSseStream(
  AppDatabase db,
  String id,
  String runId,
) async* {
  int lastSentId = -1;

  final initialRun = await db.buildRunDao.getBuildRun(id, runId);
  final isCompleted = _isRunCompleted(initialRun?.status);

  if (isCompleted) {
    final logs = await db.buildJobDao.getBuildJobLogs(runId);
    for (final log in logs) {
      final lines = log.logContent.split('\n');
      for (final line in lines) {
        if (line.isEmpty && line == lines.last) continue;
        yield utf8.encode('data: $line\n\n');
      }
    }
    return;
  }

  await for (final logs in db.buildJobDao.watchBuildJobLogs(runId)) {
    final newLogs = logs.where((l) => l.id > lastSentId).toList();
    if (newLogs.isNotEmpty) {
      for (final log in newLogs) {
        lastSentId = log.id;
        final lines = log.logContent.split('\n');
        for (final line in lines) {
          if (line.isEmpty && line == lines.last) continue;
          yield utf8.encode('data: $line\n\n');
        }
      }
    }

    final currentRun = await db.buildRunDao.getBuildRun(id, runId);
    if (_isRunCompleted(currentRun?.status)) {
      break;
    }
  }
}

bool _isRunCompleted(String? status) {
  if (status == null) return true;
  final s = status.toUpperCase();
  return s == 'SUCCESS' ||
      s == 'FAILURE' ||
      s == 'CANCELLED' ||
      s == 'TIMED_OUT' ||
      s == 'SKIPPED';
}
