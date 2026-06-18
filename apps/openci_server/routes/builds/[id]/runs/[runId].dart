import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
import 'package:openci_server/database.dart';

FutureOr<Response> onRequest(
  RequestContext context,
  String id,
  String runId,
) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id, runId),
    HttpMethod.patch => _patch(context, id, runId),
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

    final driftRun = await db.buildRunDao.getBuildRun(id, runId);
    if (driftRun == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Build run not found'},
      );
    }

    return Response.json(
      body: {
        'id': driftRun.id,
        'buildJobId': driftRun.buildJobId,
        'status': driftRun.status,
        'conclusion': driftRun.conclusion,
        'createdAt': driftRun.createdAt.toUtc().toIso8601String(),
        'updatedAt': driftRun.updatedAt.toUtc().toIso8601String(),
      },
    );
  } catch (e, s) {
    stderr.writeln('Failed to get build run $runId for job $id: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Internal server error',
      },
    );
  }
}

Future<Response> _patch(
  RequestContext context,
  String id,
  String runId,
) async {
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
        body: {'success': false, 'error': 'Invalid JSON: $e'},
      );
    }

    final String status;
    final String? conclusion;
    try {
      final rawStatus = payload['status'];
      if (rawStatus == null) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'status is required'},
        );
      }
      status = rawStatus as String;
      conclusion = payload['conclusion'] as String?;
    } on TypeError catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Invalid payload structure: $e',
        },
      );
    }

    if (status.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'status is required'},
      );
    }

    final driftRun = await db.buildRunDao.getBuildRun(id, runId);
    if (driftRun == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Build run not found'},
      );
    }

    final updatedRun = driftRun.copyWith(
      status: status,
      conclusion: payload.containsKey('conclusion')
          ? Value(conclusion)
          : const Value.absent(),
      updatedAt: DateTime.now().toUtc(),
    );

    await db.buildRunDao.updateBuildRun(updatedRun);

    return Response.json(body: {'success': true});
  } catch (e, s) {
    stderr.writeln('Failed to update build run $runId for job $id: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Internal server error',
      },
    );
  }
}
