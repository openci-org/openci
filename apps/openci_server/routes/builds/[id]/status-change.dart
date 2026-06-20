import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart' show Value;
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_service.dart';
import 'package:openci_shared/openci_shared.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.post => _post(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _post(RequestContext context, String id) async {
  try {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();

    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

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

    final env = Platform.environment;
    final allowedUidsStr = env['ALLOWED_WORKER_UIDS'] ?? '';
    final allowedUids = allowedUidsStr
        .split(',')
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toSet();

    if (!allowedUids.contains(uid)) {
      final isMember = await db.teamDao.isTeamMember(uid, teamId);
      if (!isMember) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'success': false, 'error': 'Forbidden'},
        );
      }
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
        body: {'success': false, 'error': 'Invalid JSON: $e'},
      );
    }

    final statusStr = payload['status'] as String?;
    if (statusStr == null || statusStr.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'status is required'},
      );
    }

    final completedStatus = BuildJobStatus.values.byName(statusStr);

    if (completedStatus == BuildJobStatus.FAILURE &&
        driftJob.workflowRunId != null &&
        driftJob.workflowJobKey != null) {
      final cancellableStatuses = {
        BuildJobStatus.WAITING.name,
        BuildJobStatus.QUEUED.name,
        BuildJobStatus.IN_PROGRESS.name,
      };

      final candidates =
          await (db.select(db.buildJobs)
                ..where((t) => t.workflowRunId.equals(driftJob.workflowRunId!))
                ..where(
                  (t) => t.workflowJobKey.equals(driftJob.workflowJobKey!),
                )
                ..where((t) => t.status.isIn(cancellableStatuses)))
              .get();

      final now = DateTime.now().toUtc();
      for (final candidate in candidates) {
        if (candidate.id == driftJob.id) continue;

        final updated = candidate.copyWith(
          status: BuildJobStatus.CANCELLED,
          completedAt: Value(now),
          updatedAt: now,
        );
        await db.buildJobDao.updateBuildJob(updated);

        if (updated.checkRunId != null && updated.installationId != null) {
          try {
            await GitHubService.updateGitHubCheckRun(
              owner: updated.owner,
              repo: updated.repo,
              checkRunIdStr: updated.checkRunId!,
              installationIdStr: updated.installationId!,
              githubApiBaseUrlStr: updated.githubApiBaseUrl,
              runStatus: 'completed',
              conclusion: 'cancelled',
            );
          } catch (e) {
            stderr.writeln(
              'Failed to cancel check run for matrix job ${updated.id}: $e',
            );
          }
        }
      }
    }

    Future<void> resolveDependencies(
      DriftBuildJob completed,
      BuildJobStatus compStatus,
    ) async {
      final workflowRunId = completed.workflowRunId;
      final jobKey = completed.jobKey;
      if (workflowRunId == null || jobKey == null) return;

      final waitingJobs =
          await (db.select(db.buildJobs)
                ..where((t) => t.workflowRunId.equals(workflowRunId))
                ..where((t) => t.status.equals(BuildJobStatus.WAITING.name)))
              .get();

      final isSuccess = compStatus == BuildJobStatus.SUCCESS;

      for (final waitingJob in waitingJobs) {
        final needs = waitingJob.needs ?? [];
        if (!needs.contains(jobKey)) continue;

        if (!isSuccess) {
          final now = DateTime.now().toUtc();
          final updated = waitingJob.copyWith(
            status: BuildJobStatus.SKIPPED,
            completedAt: Value(now),
            updatedAt: now,
          );
          await db.buildJobDao.updateBuildJob(updated);

          if (updated.checkRunId != null && updated.installationId != null) {
            try {
              await GitHubService.updateGitHubCheckRun(
                owner: updated.owner,
                repo: updated.repo,
                checkRunIdStr: updated.checkRunId!,
                installationIdStr: updated.installationId!,
                githubApiBaseUrlStr: updated.githubApiBaseUrl,
                runStatus: 'completed',
                conclusion: 'skipped',
              );
            } catch (e) {
              stderr.writeln(
                'Failed to skip check run for job ${updated.id}: $e',
              );
            }
          }

          await resolveDependencies(updated, BuildJobStatus.SKIPPED);
          continue;
        }

        bool allSatisfied = true;
        for (final needJobKey in needs) {
          final needJob =
              await (db.select(db.buildJobs)
                    ..where((t) => t.workflowRunId.equals(workflowRunId))
                    ..where((t) => t.jobKey.equals(needJobKey)))
                  .getSingleOrNull();

          if (needJob == null || needJob.status != BuildJobStatus.SUCCESS) {
            allSatisfied = false;
            break;
          }
        }

        if (allSatisfied) {
          final updated = waitingJob.copyWith(
            status: BuildJobStatus.QUEUED,
            updatedAt: DateTime.now().toUtc(),
          );
          await db.buildJobDao.updateBuildJob(updated);
        }
      }
    }

    await resolveDependencies(driftJob, completedStatus);

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
  } catch (e, s) {
    stderr.writeln('Failed to process status change for job $id: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Internal server error',
      },
    );
  }
}
