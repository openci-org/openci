import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_service.dart';
import 'package:openci_server/github/parse_github_api_base_uri.dart';
import 'package:openci_server/github/read_active_github_connections.dart';
import 'package:openci_server/request/error_handler.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context, String id) async {
  try {
    final driftJob = context.read<DriftBuildJob>();

    final installationIdStr = driftJob.installationId;
    if (installationIdStr == null || installationIdStr.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'No installationId found for job'},
      );
    }

    final installationId = int.tryParse(installationIdStr, radix: 10);
    if (installationId == null || installationId <= 0) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Invalid installationId for job'},
      );
    }

    final teamId = driftJob.teamId;
    if (teamId == null || teamId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    Map<String, String> env;
    try {
      env = context.read<Map<String, String>>();
    } catch (_) {
      env = Platform.environment;
    }
    env = {
      ...env,
      'GITHUB_API_BASE_URL': parseGitHubApiBaseUri(
        env['GITHUB_API_BASE_URL'],
      ).toString(),
    };

    final connections = await readActiveGitHubConnections(
      db: context.read<AppDatabase>(),
      teamId: teamId,
      environment: env,
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
          environment: env,
          client: client,
        );
    if (repositoryInstallationId != installationId.toString()) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final token = await GitHubService.getInstallationToken(
      installationIdStr: installationId.toString(),
      environment: env,
      client: client,
    );
    if (token.trim().isEmpty) {
      throw const FormatException(
        'GitHub returned an empty installation token',
      );
    }
    return Response.json(
      headers: {HttpHeaders.cacheControlHeader: 'no-store'},
      body: {'token': token},
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to resolve token for job $id',
    );
  }
}
