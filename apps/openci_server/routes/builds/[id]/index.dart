import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';
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

Future<Response> _patch(RequestContext context, String id) async {
  try {
    final db = context.read<AppDatabase>();
    final driftJob = context.read<DriftBuildJob>();

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

    final job = driftJob.toShared();

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

    final updatedDriftJob = updatedJob.toDrift();
    await db.buildJobDao.updateBuildJob(updatedDriftJob);

    return Response.json(body: {'success': true});
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
  } catch (e, s) {
    stderr.writeln('Failed to patch build job $id: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Internal server error',
      },
    );
  }
}
