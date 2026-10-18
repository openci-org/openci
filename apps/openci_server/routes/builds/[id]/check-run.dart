import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_service.dart';
import 'package:openci_server/github/parse_github_api_base_uri.dart';
import 'package:openci_server/github/read_active_github_connections.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.post => _post(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _post(RequestContext context, String id) async {
  try {
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

    final runStatus = payload['status'] as String?;
    if (runStatus == null || runStatus.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'status is required'},
      );
    }

    final conclusion = payload['conclusion'] as String?;

    final installationIdStr = driftJob.installationId;
    final checkRunIdStr = driftJob.checkRunId;

    if (installationIdStr == null ||
        installationIdStr.isEmpty ||
        checkRunIdStr == null ||
        checkRunIdStr.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'installationId or checkRunId is missing for this build job',
        },
      );
    }

    final installationId = int.tryParse(installationIdStr, radix: 10);
    final checkRunId = int.tryParse(checkRunIdStr, radix: 10);
    if (installationId == null ||
        installationId <= 0 ||
        checkRunId == null ||
        checkRunId <= 0) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'Invalid installationId or checkRunId for job',
        },
      );
    }

    final teamId = driftJob.teamId;
    if (teamId == null || teamId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
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
    final hasConnection = connections.any(
      (connection) => connection.installationId == installationId,
    );
    if (!hasConnection) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    http.Client? client;
    try {
      client = context.read<http.Client>();
    } catch (_) {
      // GitHubService uses its default HTTP client when none is provided.
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

    await GitHubService.updateGitHubCheckRun(
      owner: driftJob.owner,
      repo: driftJob.repo,
      checkRunIdStr: checkRunId.toString(),
      installationIdStr: installationId.toString(),
      runStatus: runStatus,
      conclusion: conclusion,
      environment: environment,
      client: client,
    );

    return Response.json(body: {'success': true});
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to update check run for job $id',
    );
  }
}
