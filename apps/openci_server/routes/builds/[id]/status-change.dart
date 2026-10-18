import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_service.dart';
import 'package:openci_server/github/parse_github_api_base_uri.dart';
import 'package:openci_server/github/read_active_github_connections.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';
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
    final driftJob = context.read<DriftBuildJob>();
    final teamId = driftJob.teamId;
    if (teamId == null || teamId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
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

    final statusStr = payload['status'] as String?;
    if (statusStr == null || statusStr.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'status is required'},
      );
    }

    final completedStatus = BuildJobStatus.values.byName(statusStr);
    var checkUpdateFailed = false;

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
                ..where((t) => t.teamId.equals(teamId))
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

        try {
          await _updateCheckRun(context, updated, 'cancelled');
        } catch (_) {
          // Finish stopping related jobs even when GitHub rejects an update.
          checkUpdateFailed = true;
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
                ..where((t) => t.teamId.equals(teamId))
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

          try {
            await _updateCheckRun(context, updated, 'skipped');
          } catch (_) {
            checkUpdateFailed = true;
          }

          await resolveDependencies(updated, BuildJobStatus.SKIPPED);
          continue;
        }

        bool allSatisfied = true;
        for (final needJobKey in needs) {
          final needJob =
              await (db.select(db.buildJobs)
                    ..where((t) => t.teamId.equals(teamId))
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

    try {
      await resolveDependencies(driftJob, completedStatus);
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
    }

    if (checkUpdateFailed) {
      throw StateError('Failed to update GitHub checks after status change');
    }

    return Response.json(body: {'success': true});
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to process status change for job $id',
    );
  }
}

Future<void> _updateCheckRun(
  RequestContext context,
  DriftBuildJob job,
  String conclusion,
) async {
  // Jobs without a GitHub check still need their local state updated.
  if (job.checkRunId == null) return;

  final installationId = int.tryParse(job.installationId ?? '', radix: 10);
  final checkRunId = int.tryParse(job.checkRunId!, radix: 10);
  final teamId = job.teamId;
  if (installationId == null ||
      installationId <= 0 ||
      checkRunId == null ||
      checkRunId <= 0 ||
      teamId == null ||
      teamId.isEmpty) {
    throw StateError('Valid job metadata is required to update a GitHub check');
  }

  Map<String, String> environment;
  try {
    environment = context.read<Map<String, String>>();
  } catch (_) {
    environment = Platform.environment;
  }
  environment = {
    ...environment,
    'GITHUB_API_BASE_URL': parseGitHubApiBaseUri(
      environment['GITHUB_API_BASE_URL'],
    ).toString(),
  };
  final connections = await readActiveGitHubConnections(
    db: context.read<AppDatabase>(),
    teamId: teamId,
    environment: environment,
  );
  if (!connections.any(
    (connection) => connection.installationId == installationId,
  )) {
    throw StateError('An active verified GitHub connection is required');
  }

  http.Client? providedClient;
  try {
    providedClient = context.read<http.Client>();
  } catch (_) {
    // Create a client when one is not provided by the request context.
  }
  final client = providedClient ?? http.Client();
  try {
    final repositoryInstallationId =
        await GitHubService.getRepositoryInstallationId(
          owner: job.owner,
          repo: job.repo,
          environment: environment,
          client: client,
        );
    if (repositoryInstallationId != installationId.toString()) {
      throw StateError('The repository does not match the GitHub connection');
    }

    await GitHubService.updateGitHubCheckRun(
      owner: job.owner,
      repo: job.repo,
      checkRunIdStr: checkRunId.toString(),
      installationIdStr: installationId.toString(),
      runStatus: 'completed',
      conclusion: conclusion,
      environment: environment,
      client: client,
    );
  } finally {
    if (providedClient == null) client.close();
  }
}
