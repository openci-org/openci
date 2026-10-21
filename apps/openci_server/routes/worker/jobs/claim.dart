import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/billing/billing_proxy.dart';
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

    final ClaimJobRequest claimRequest;
    try {
      claimRequest = ClaimJobRequest.fromJson(payload);
    } on TypeError {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'invalid_request'},
      );
    }

    var environment = Platform.environment;
    try {
      environment = context.read<Map<String, String>>();
    } catch (_) {
      // Use the process environment when no override is provided.
    }
    // Validate before claiming so a configuration error leaves the job queued.
    final githubBaseUrl = githubRepositoryBaseUrl(environment: environment);
    final db = context.read<AppDatabase>();
    if (environment['SERVER_ACCESS_MODE'] == 'cloud' &&
        environment['BILLING_ENABLED'] == 'true') {
      final proxy = context.read<BillingProxy?>();
      if (proxy == null) {
        return Response.json(
          statusCode: HttpStatus.serviceUnavailable,
          body: {'error': 'billing_unavailable'},
        );
      }
      final response = await proxy.workerRequest(
        operation: WorkerBillingOperation.claim,
        payload: claimRequest.toJson(),
      );
      if (response.statusCode != HttpStatus.ok) return response;
      final body = await response.json() as Map<String, dynamic>;
      final claim = body['claim'] as Map<String, dynamic>?;
      if (claim == null) return Response.json(body: {'job': null});
      final job = await db.buildJobDao.getBuildJob(claim['jobId'] as String);
      if (job == null ||
          job.status != BuildJobStatus.IN_PROGRESS ||
          job.workerHost != claimRequest.workerHost) {
        return Response.json(
          statusCode: HttpStatus.conflict,
          body: {'error': 'admission_not_current'},
        );
      }
      return Response.json(
        body: {
          'job': job
              .toShared()
              .copyWith(
                githubBaseUrl: githubBaseUrl,
                billingAdmissionId: claim['admissionId'] as String,
              )
              .toJson(),
        },
        headers: const {'cache-control': 'no-store'},
      );
    }
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
