import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/billing/billing_admission_store.dart';
import 'package:openci_server/build_job/build_job_dao.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_service.dart';
import 'package:openci_server/github/parse_github_api_base_uri.dart';
import 'package:openci_server/github/read_active_github_connections.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';
import 'package:openci_shared/openci_shared.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    HttpMethod.post => _post(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context, String id) async {
  try {
    final db = context.read<AppDatabase>();
    final runs = await db.buildRunDao.getBuildRuns(id);
    final responseBody = runs
        .map(
          (run) => {
            'id': run.id,
            'buildJobId': run.buildJobId,
            'status': run.status,
            'conclusion': run.conclusion,
            'createdAt': run.createdAt.toUtc().toIso8601String(),
            'updatedAt': run.updatedAt.toUtc().toIso8601String(),
          },
        )
        .toList();

    return Response.json(body: responseBody);
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to get build runs for job $id',
    );
  }
}

Future<Response> _post(RequestContext context, String id) async {
  try {
    final db = context.read<AppDatabase>();
    Map<String, String> environment;
    try {
      environment = context.read<Map<String, String>>();
    } catch (_) {
      environment = Platform.environment;
    }
    final isCloud = environment['SERVER_ACCESS_MODE'] == 'cloud';
    final driftJob = context.read<DriftBuildJob>();
    if (isCloud) {
      if (!context.read<InternalApiKeyValidator>().isValid(context)) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'success': false, 'error': 'Worker authentication required'},
        );
      }
      if (driftJob.status != BuildJobStatus.IN_PROGRESS) {
        return _jobNotClaimed();
      }
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

    final String runId;
    try {
      final rawId = payload['id'];
      if (rawId == null) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'id is required'},
        );
      }
      runId = rawId as String;
    } on TypeError catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Invalid payload structure: $e',
        },
      );
    }

    if (runId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'id is required'},
      );
    }

    final billingEnabled = isCloud && environment['BILLING_ENABLED'] == 'true';
    final admissionId = payload['billingAdmissionId'];
    final workerHost = payload['workerHost'];
    if (billingEnabled &&
        (admissionId is! String ||
            admissionId.isEmpty ||
            admissionId.length > 255 ||
            workerHost is! String ||
            workerHost.isEmpty ||
            workerHost.length > 255)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'billing_admission_required'},
      );
    }

    final installationId = int.tryParse(
      driftJob.installationId ?? '',
      radix: 10,
    );
    if (installationId == null || installationId <= 0) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Invalid installationId for job'},
      );
    }

    final savedCheckRunId = driftJob.checkRunId;
    final hasCheck = savedCheckRunId != null && savedCheckRunId.isNotEmpty;
    final checkRunId = int.tryParse(savedCheckRunId ?? '', radix: 10);
    if (hasCheck && (checkRunId == null || checkRunId <= 0)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Invalid checkRunId for job'},
      );
    }
    final commitSha = driftJob.commitSha;
    if (!hasCheck && (commitSha == null || commitSha.isEmpty)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'commitSha is required for job'},
      );
    }

    final teamId = driftJob.teamId;
    if (teamId == null || teamId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    environment = {
      ...environment,
      'GITHUB_API_BASE_URL': parseGitHubApiBaseUri(
        environment['GITHUB_API_BASE_URL'],
      ).toString(),
    };
    final connections = await readActiveGitHubConnections(
      db: db,
      teamId: teamId,
      environment: environment,
    );
    if (!connections.any(
      (connection) => connection.installationId == installationId,
    )) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    http.Client? client;
    try {
      client = context.read<http.Client>();
    } catch (_) {
      // GitHubService uses its default HTTP client.
    }
    final repositoryInstallationId =
        await GitHubService.getRepositoryInstallationId(
          owner: driftJob.owner,
          repo: driftJob.repo,
          environment: environment,
          client: client,
        );
    if (repositoryInstallationId != installationId.toString()) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final now = DateTime.now().toUtc();
    final driftRun = DriftBuildRun(
      id: runId,
      buildJobId: id,
      status: 'in_progress',
      createdAt: now,
      updatedAt: now,
    );

    final githubClient = client ?? http.Client();
    try {
      await db.transaction(() async {
        if (billingEnabled) {
          await BillingAdmissionStore(db).bindRun(
            admissionId: admissionId as String,
            jobId: id,
            runId: runId,
            workerHost: workerHost as String,
          );
        }
        await db.buildRunDao.insertBuildRun(driftRun);
        await db.buildJobDao.incrementRunCount(
          id: id,
          latestRunId: runId,
          updatedAt: now,
          requireInProgress: isCloud,
        );

        if (!hasCheck) {
          final createdCheckRunId = await GitHubService.createGitHubCheckRun(
            owner: driftJob.owner,
            repo: driftJob.repo,
            installationIdStr: installationId.toString(),
            name: driftJob.workflowName,
            headSha: commitSha!,
            externalId: driftJob.id,
            environment: environment,
            client: githubClient,
          ).timeout(const Duration(seconds: 10));
          await (db.update(
            db.buildJobs,
          )..where((job) => job.id.equals(id))).write(
            BuildJobsCompanion(checkRunId: Value(createdCheckRunId)),
          );
        } else {
          await GitHubService.updateGitHubCheckRun(
            owner: driftJob.owner,
            repo: driftJob.repo,
            checkRunIdStr: checkRunId.toString(),
            installationIdStr: installationId.toString(),
            runStatus: 'in_progress',
            environment: environment,
            client: githubClient,
          ).timeout(const Duration(seconds: 10));
        }
      });
    } on BillingAdmissionNotCurrent {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {'error': 'admission_not_current'},
      );
    } on BuildJobNotClaimedException {
      return _jobNotClaimed();
    } catch (e) {
      final errStr = e.toString();
      final isUniqueViolation =
          errStr.contains('UNIQUE constraint failed') ||
          errStr.contains('duplicate key value violates unique constraint') ||
          errStr.contains('23505');

      if (isUniqueViolation) {
        return Response.json(
          statusCode: HttpStatus.conflict,
          body: {
            'success': false,
            'error': 'Run ID already exists',
          },
        );
      }
      rethrow;
    } finally {
      if (client == null) githubClient.close();
    }

    return Response.json(body: {'success': true});
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to create build run for job $id',
    );
  }
}

Response _jobNotClaimed() => Response.json(
  statusCode: HttpStatus.conflict,
  body: {'success': false, 'error': 'Build job must be in progress'},
);
