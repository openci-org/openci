import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:openci_server/billing/billing_admission_store.dart';
import 'package:openci_server/billing/paid_worker_request.dart';
import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';
import 'package:openci_shared/openci_shared.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    HttpMethod.patch => _patch(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context, String id) async {
  try {
    final driftJob = context.read<DriftBuildJob>();
    final job = driftJob.toShared();
    return Response.json(body: job.toJson());
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to get build job $id',
    );
  }
}

Future<Response> _patch(RequestContext context, String id) async {
  try {
    final db = context.read<AppDatabase>();
    final driftJob = context.read<DriftBuildJob>();

    final Map<String, dynamic> payload;
    try {
      payload = await context.jsonBody();
    } on BadRequestException catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': e.message},
      );
    }

    if (isPaidWorkerRequest(context)) {
      if (payload.keys.any(
        {'status', 'latestRunId', 'runCount', 'completedAt'}.contains,
      )) {
        final attempt = readPaidWorkerAttempt(context, id, payload);
        final outcome = paidCompletionStatus(payload['status']);
        if (payload.keys.any(
          (key) => !{
            'status',
            'completedAt',
            'billingAdmissionId',
            'runId',
            'workerHost',
          }.contains(key),
        )) {
          throw const PaidWorkerRequestInvalid('invalid_completion_payload');
        }
        await BillingAdmissionStore(db).completeJob(attempt, outcome);
        return Response.json(body: {'success': true});
      }
      return await db.transaction(() async {
        await db
            .customSelect(
              r'SELECT id FROM build_jobs WHERE id = $1 FOR UPDATE',
              variables: [Variable.withString(id)],
            )
            .get();
        final current = await db.buildJobDao.getBuildJob(id);
        if (current == null) return Response(statusCode: HttpStatus.notFound);
        return _applyPatch(db, current, payload);
      });
    }
    return await _applyPatch(db, driftJob, payload);
  } on PaidWorkerAuthenticationRequired {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'error': 'worker_authentication_required'},
    );
  } on BillingAdmissionNotCurrent {
    return Response.json(
      statusCode: HttpStatus.conflict,
      body: {'error': 'admission_not_current'},
    );
  } on PaidWorkerRequestInvalid catch (error) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': error.message},
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to patch build job $id',
    );
  }
}

Future<Response> _applyPatch(
  AppDatabase db,
  DriftBuildJob driftJob,
  Map<String, dynamic> payload,
) async {
  final job = driftJob.toShared();

  final DriftBuildJob updatedDriftJob;
  try {
    final updatedJob = job.copyWith(
      status: payload.containsKey('status')
          ? BuildJobStatus.values.byName(payload['status'] as String)
          : job.status,
      latestRunId: payload.containsKey('latestRunId')
          ? payload['latestRunId'] as String?
          : job.latestRunId,
      runCount: payload.containsKey('runCount')
          ? payload['runCount'] as int?
          : job.runCount,
      failureSummary: payload.containsKey('failureSummary')
          ? payload['failureSummary'] as String?
          : job.failureSummary,
      failureSummaryModel: payload.containsKey('failureSummaryModel')
          ? payload['failureSummaryModel'] as String?
          : job.failureSummaryModel,
      failureSummaryStatus: payload.containsKey('failureSummaryStatus')
          ? payload['failureSummaryStatus'] as String?
          : job.failureSummaryStatus,
      failureSummaryDurationMs: payload.containsKey('failureSummaryDurationMs')
          ? payload['failureSummaryDurationMs'] as int?
          : job.failureSummaryDurationMs,
      provisionedUdids: payload.containsKey('provisionedUdids')
          ? (payload['provisionedUdids'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList()
          : job.provisionedUdids,
      ipaUrl: payload.containsKey('ipaUrl')
          ? payload['ipaUrl'] as String?
          : job.ipaUrl,
      hasIpa: payload.containsKey('hasIpa')
          ? payload['hasIpa'] as bool?
          : job.hasIpa,
      bundleId: payload.containsKey('bundleId')
          ? payload['bundleId'] as String?
          : job.bundleId,
      ipaVersion: payload.containsKey('ipaVersion')
          ? payload['ipaVersion'] as String?
          : job.ipaVersion,
      appName: payload.containsKey('appName')
          ? payload['appName'] as String?
          : job.appName,
      updatedAt: DateTime.now().toUtc(),
      completedAt: payload.containsKey('completedAt')
          ? (payload['completedAt'] != null
                ? DateTime.parse(payload['completedAt'] as String)
                : null)
          : job.completedAt,
    );

    updatedDriftJob = updatedJob.toDrift(
      installationId: driftJob.installationId,
      checkRunId: driftJob.checkRunId,
    );

    await db.buildJobDao.updateBuildJob(updatedDriftJob);
  } on TypeError catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'success': false,
        'error': 'Invalid payload structure: $e',
      },
    );
  } on ArgumentError catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'success': false,
        'error': 'Invalid status: $e',
      },
    );
  } on FormatException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'success': false,
        'error': 'Invalid date format: $e',
      },
    );
  }

  return Response.json(body: {'success': true});
}
