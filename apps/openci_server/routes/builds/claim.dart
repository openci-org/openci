import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/auth/worker_auth.dart';
import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';

FutureOr<Response> onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.post => _post(context),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _post(RequestContext context) async {
  try {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();

    final authErrorResponse = verifyWorkerAuth(context, uid);
    if (authErrorResponse != null) {
      return authErrorResponse;
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

    final runsOnPattern = payload['runsOnPattern'] as String?;
    if (runsOnPattern == null || runsOnPattern.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'runsOnPattern is required'},
      );
    }

    final driftJob = await db.buildJobDao.claimNextJob(runsOnPattern);
    if (driftJob == null) {
      return Response.json(body: {'job': null});
    }

    return Response.json(body: {'job': driftJob.toShared().toJson()});
  } catch (e, s) {
    return handleRouteException(e, s, logMessage: 'Failed to claim next job');
  }
}
