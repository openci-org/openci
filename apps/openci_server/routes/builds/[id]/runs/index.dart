import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    HttpMethod.post => _post(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context, String id) async {
  try {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();

    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Unauthorized'},
      );
    }
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

    final runs = await db.buildRunDao.getBuildRuns(id);
    final responseBody = runs
        .map(
          (run) => {
            'id': run.id,
            'buildJobId': run.buildJobId,
            'status': run.status,
            'conclusion': run.conclusion,
            'createdAt': run.createdAt.toUtc().toIso8601String(),
            'updatedAt': run.updatedAt.toUtc().toIso8601String(),
          },
        )
        .toList();

    return Response.json(body: responseBody);
  } catch (e, s) {
    stderr.writeln('Failed to get build runs for job $id: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Internal server error',
      },
    );
  }
}

Future<Response> _post(RequestContext context, String id) async {
  try {
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

    final String runId;
    try {
      final rawId = payload['id'];
      if (rawId == null) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'id is required'},
        );
      }
      runId = rawId as String;
    } on TypeError catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Invalid payload structure: $e',
        },
      );
    }

    if (runId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'id is required'},
      );
    }

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
  } catch (e, s) {
    final errStr = e.toString();
    final isUniqueViolation =
        errStr.contains('UNIQUE constraint failed') ||
        errStr.contains('duplicate key value violates unique constraint') ||
        errStr.contains('23505');

    if (isUniqueViolation) {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {
          'success': false,
          'error': 'Run ID already exists',
        },
      );
    }

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
