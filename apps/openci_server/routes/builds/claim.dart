import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/auth/worker_auth.dart';
import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';

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
    stderr.writeln('Failed to claim next job: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': 'Internal server error'},
    );
  }
}
