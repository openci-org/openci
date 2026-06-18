import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.post => _post(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _post(RequestContext context, String id) async {
  final db = context.read<AppDatabase>();
  final uid = context.read<String?>();

  if (uid == null) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'success': false, 'error': 'Unauthorized'},
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
      body: {'success': false, 'error': 'Invalid JSON format: $e'},
    );
  }

  final runId = payload['id'] as String?;
  if (runId == null || runId.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'success': false, 'error': 'id is required'},
    );
  }

  try {
    final driftJob = await db.buildJobDao.getBuildJob(id);
    if (driftJob == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Build job not found'},
      );
    }

    final teamId = driftJob.teamId;
    if (teamId == null) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final isMember = await db.teamDao.isTeamMember(uid, teamId);
    if (!isMember) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final now = DateTime.now().toUtc();
    final driftRun = DriftBuildRun(
      id: runId,
      buildJobId: id,
      status: 'in_progress',
      createdAt: now,
      updatedAt: now,
    );

    await db.transaction(() async {
      await db.buildRunDao.insertBuildRun(driftRun);
      await db.buildJobDao.incrementRunCount(
        id: id,
        latestRunId: runId,
        updatedAt: now,
      );
    });

    return Response.json(body: {'success': true});
  } on TypeError catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'success': false,
        'error': 'Invalid payload structure: $e',
      },
    );
  } catch (e, s) {
    stderr.writeln('Failed to create build run for job $id: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Internal server error',
      },
    );
  }
}
