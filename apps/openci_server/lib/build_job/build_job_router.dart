import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
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

    router.post('/<buildJobId>/runs', (
      Request request,
      String buildJobId,
    ) async {
      try {
        final payload =
            jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final runId = payload['id'] as String?;
        if (runId == null || runId.isEmpty) {
          return Response.badRequest(
            body: jsonEncode({'success': false, 'error': 'id is required'}),
            headers: {'content-type': 'application/json'},
          );
        }

        final now = DateTime.now().toUtc();
        final driftRun = DriftBuildRun(
          id: runId,
          buildJobId: buildJobId,
          status: 'in_progress',
          createdAt: now,
          updatedAt: now,
        );

        final driftJob = await db.buildJobDao.getBuildJob(buildJobId);
        if (driftJob == null) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Build job not found'}),
            headers: {'content-type': 'application/json'},
          );
        }

        await db.transaction(() async {
          await db.buildRunDao.insertBuildRun(driftRun);
          final updatedJob = driftJob.copyWith(
            latestRunId: Value(runId),
            runCount: Value((driftJob.runCount ?? 0) + 1),
            updatedAt: now,
          );
          await db.buildJobDao.updateBuildJob(updatedJob);
        });

        return Response.ok(
          jsonEncode({'success': true}),
          headers: {'content-type': 'application/json'},
        );
      } on FormatException catch (e) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'Invalid JSON format: $e',
          }),
          headers: {'content-type': 'application/json'},
        );
      } on TypeError catch (e) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'Invalid payload structure: $e',
          }),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, s) {
        stderr.writeln(
          'Failed to create build run for job $buildJobId: $e\n$s',
        );
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': 'Internal server error',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    router.patch('/<buildJobId>/runs/<runId>', (
      Request request,
      String buildJobId,
      String runId,
    ) async {
      try {
        final payload =
            jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final status = payload['status'] as String?;
        if (status == null || status.isEmpty) {
          return Response.badRequest(
            body: jsonEncode({'success': false, 'error': 'status is required'}),
            headers: {'content-type': 'application/json'},
          );
        }
        final conclusion = payload['conclusion'] as String?;

        final driftRun = await db.buildRunDao.getBuildRun(buildJobId, runId);
        if (driftRun == null) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Build run not found'}),
            headers: {'content-type': 'application/json'},
          );
        }
        if (driftRun.buildJobId != buildJobId) {
          return Response.notFound(
            jsonEncode({
              'success': false,
              'error': 'Build run not found for the specified build job',
            }),
            headers: {'content-type': 'application/json'},
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

        return Response.ok(
          jsonEncode({'success': true}),
          headers: {'content-type': 'application/json'},
        );
      } on FormatException catch (e) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'Invalid JSON format: $e',
          }),
          headers: {'content-type': 'application/json'},
        );
      } on TypeError catch (e) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'Invalid payload structure: $e',
          }),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, s) {
        stderr.writeln(
          'Failed to update build run status for run $runId: $e\n$s',
        );
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': 'Internal server error',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    router.get('/<buildJobId>/runs/<runId>', (
      Request request,
      String buildJobId,
      String runId,
    ) async {
      try {
        final driftRun = await db.buildRunDao.getBuildRun(buildJobId, runId);
        if (driftRun == null) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Build run not found'}),
            headers: {'content-type': 'application/json'},
          );
        }
        if (driftRun.buildJobId != buildJobId) {
          return Response.notFound(
            jsonEncode({
              'success': false,
              'error': 'Build run not found for the specified build job',
            }),
            headers: {'content-type': 'application/json'},
          );
        }

        return Response.ok(
          jsonEncode({
            'id': driftRun.id,
            'buildJobId': driftRun.buildJobId,
            'status': driftRun.status,
            'conclusion': driftRun.conclusion,
            'createdAt': driftRun.createdAt.toUtc().toIso8601String(),
            'updatedAt': driftRun.updatedAt.toUtc().toIso8601String(),
          }),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, s) {
        stderr.writeln('Failed to get build run $runId: $e\n$s');
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': 'Internal server error',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    });

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
      } on FormatException catch (e) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'Invalid JSON format: $e',
          }),
          headers: {'content-type': 'application/json'},
        );
      } on TypeError catch (e) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'Invalid payload structure: $e',
          }),
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
      } on FormatException catch (e) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'Invalid JSON format: $e',
          }),
          headers: {'content-type': 'application/json'},
        );
      } on TypeError catch (e) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'Invalid payload structure: $e',
          }),
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

    router.get('/<buildJobId>/runs/<runId>/logs/stream', (
      Request request,
      String buildJobId,
      String runId,
    ) async {
      final controller = StreamController<List<int>>();
      StreamSubscription<List<DriftBuildJobLog>>? logsSubscription;
      StreamSubscription<DriftBuildJob?>? jobSubscription;

      bool isCleanedUp = false;
      Future<void> cleanup() async {
        if (isCleanedUp) return;
        isCleanedUp = true;
        await logsSubscription?.cancel();
        await jobSubscription?.cancel();
        if (!controller.isClosed) {
          await controller.close();
        }
      }

      controller.onListen = () {
        int lastSentId = 0;

        logsSubscription = db.buildJobDao
            .watchBuildJobLogs(runId)
            .listen(
              (logs) {
                final newLogs = logs
                    .where((log) => log.id > lastSentId)
                    .toList();
                if (newLogs.isNotEmpty) {
                  for (final log in newLogs) {
                    final data = jsonEncode({
                      'id': log.id,
                      'content': log.logContent,
                      'createdAt': log.createdAt.toUtc().toIso8601String(),
                    });
                    if (!controller.isClosed) {
                      controller.add(utf8.encode('data: $data\n\n'));
                    }
                  }
                  lastSentId = newLogs.last.id;
                }
              },
              onError: (Object error, StackTrace stackTrace) async {
                stderr.writeln(
                  'Error in logs stream for run $runId: $error\n$stackTrace',
                );
                if (!controller.isClosed) {
                  controller.addError(error, stackTrace);
                }
                await cleanup();
              },
            );

        jobSubscription = db.buildJobDao
            .watchBuildJob(buildJobId)
            .listen(
              (job) async {
                if (job != null) {
                  final status = job.status;
                  if (status == BuildJobStatus.SUCCESS ||
                      status == BuildJobStatus.FAILURE ||
                      status == BuildJobStatus.CANCELLED ||
                      status == BuildJobStatus.SKIPPED ||
                      status == BuildJobStatus.TIMED_OUT) {
                    if (!controller.isClosed) {
                      controller.add(utf8.encode('event: done\ndata: {}\n\n'));
                    }
                    await cleanup();
                  }
                }
              },
              onError: (Object error, StackTrace stackTrace) {
                stderr.writeln(
                  'Error in job status watch: $error\n$stackTrace',
                );
              },
            );
      };

      controller.onCancel = () async {
        await cleanup();
      };

      return Response.ok(
        controller.stream,
        headers: {
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
        },
      );
    });

    return router;
  }
}
