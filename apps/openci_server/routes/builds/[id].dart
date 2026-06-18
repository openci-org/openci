import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context, String id) async {
  final db = context.read<AppDatabase>();
  final uid = context.read<String?>();

  if (uid == null) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'success': false, 'error': 'Unauthorized'},
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

    final job = driftJob.toShared();
    return Response.json(body: job.toJson());
  } catch (e, s) {
    stderr.writeln('Failed to get build job $id: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Internal server error',
      },
    );
  }
}
