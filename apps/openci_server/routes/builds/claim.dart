import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';

import 'package:openci_shared/openci_shared.dart';

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

    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
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

    final claimRequest = ClaimJobRequest.fromJson(payload);
    if (claimRequest.runsOnPattern.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'runsOnPattern is required'},
      );
    }

    final driftJob = await db.buildJobDao.claimNextJob(
      claimRequest.runsOnPattern,
      vmName: claimRequest.vmName,
      workerHost: claimRequest.workerHost,
      maxConcurrentJobs: claimRequest.maxConcurrentJobs,
    );
    if (driftJob == null) {
      return Response.json(body: {'job': null});
    }

    return Response.json(body: {'job': driftJob.toShared().toJson()});
  } catch (e, s) {
    return handleRouteException(e, s, logMessage: 'Failed to claim next job');
  }
}
