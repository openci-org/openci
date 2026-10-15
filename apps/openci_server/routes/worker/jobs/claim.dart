import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_repository_url.dart';
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

    var environment = Platform.environment;
    try {
      environment = context.read<Map<String, String>>();
    } catch (_) {
      // Use the process environment when no override is provided.
    }
    // Validate before claiming so a configuration error leaves the job queued.
    final githubBaseUrl = githubRepositoryBaseUrl(environment: environment);
    final db = context.read<AppDatabase>();
    final driftJob = await db.buildJobDao.claimNextJob(
      vmName: claimRequest.vmName,
      workerHost: claimRequest.workerHost,
      maxConcurrentJobs: claimRequest.maxConcurrentJobs,
    );
    if (driftJob == null) {
      return Response.json(body: {'job': null});
    }

    // Stored jobs may still contain a URL supplied by a team or an old planner.
    final job = driftJob.toShared().copyWith(githubBaseUrl: githubBaseUrl);
    return Response.json(body: {'job': job.toJson()});
  } catch (e, s) {
    return handleRouteException(e, s, logMessage: 'Failed to claim next job');
  }
}
