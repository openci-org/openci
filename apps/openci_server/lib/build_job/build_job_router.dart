import 'dart:convert';
import 'dart:io';

import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class BuildJobRouter {
  final AppDatabase db;
  final String appEnv;

  BuildJobRouter({
    required this.db,
    required this.appEnv,
  });

  Router get router {
    final router = Router();

    router.post('/', (Request request) async {
      try {
        final payload =
            jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final job = BuildJob.fromJson(payload);
        final driftJob = job.toDrift();

        await db.buildJobDao.insertBuildJob(driftJob);

        return Response.ok(
          jsonEncode({'success': true, 'id': job.id}),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, s) {
        stderr.writeln('Failed to insert build job: $e\n$s');
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': 'Internal server error',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    router.get('/<buildJobId>', (
      Request request,
      String buildJobId,
    ) async {
      try {
        final driftJob = await db.buildJobDao.getBuildJob(buildJobId);
        if (driftJob == null) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Build job not found'}),
            headers: {'content-type': 'application/json'},
          );
        }

        final job = driftJob.toShared();

        return Response.ok(
          jsonEncode(job.toJson()),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, s) {
        stderr.writeln('Failed to get build job $buildJobId: $e\n$s');
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': 'Internal server error',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    router.patch('/<buildJobId>', (
      Request request,
      String buildJobId,
    ) async {
      try {
        final payload =
            jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final driftJob = await db.buildJobDao.getBuildJob(buildJobId);
        if (driftJob == null) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Build job not found'}),
            headers: {'content-type': 'application/json'},
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
          failureSummaryDurationMs:
              payload.containsKey('failureSummaryDurationMs')
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

        return Response.ok(
          jsonEncode({'success': true}),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, s) {
        stderr.writeln('Failed to patch build job $buildJobId: $e\n$s');
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': 'Internal server error',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    router.get('/<buildJobId>/runs/<runId>/logs', (
      Request request,
      String buildJobId,
      String runId,
    ) async {
      try {
        final logs = await db.buildJobDao.getBuildJobLogs(runId);
        final logText = logs.map((l) => l.logContent).join('');
        return Response.ok(
          logText,
          headers: {'content-type': 'text/plain; charset=utf-8'},
        );
      } catch (e, s) {
        stderr.writeln('Failed to read logs for run $runId: $e\n$s');
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': 'Internal server error',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    router.post('/<buildJobId>/runs/<runId>/logs', (
      Request request,
      String buildJobId,
      String runId,
    ) async {
      try {
        final payload =
            jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final logs = payload['logs'] as List<dynamic>? ?? [];

        final StringBuffer logBuffer = StringBuffer();
        for (final log in logs) {
          if (log is Map) {
            final message = log['message'] as String?;
            if (message != null) {
              logBuffer.write('$message\n');
            }
          }
        }

        if (logBuffer.isNotEmpty) {
          await db.buildJobDao.insertBuildJobLog(runId, logBuffer.toString());
        }

        return Response.ok(
          jsonEncode({'success': true}),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, s) {
        stderr.writeln('Failed to append logs for run $runId: $e\n$s');
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': 'Internal server error',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    return router;
  }
}
