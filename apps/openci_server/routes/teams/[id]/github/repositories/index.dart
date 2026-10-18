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

Future<Response> _get(RequestContext context, String teamId) async {
  try {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();
    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

    final isMember = await db.teamDao.isTeamMember(uid, teamId);
    if (!isMember) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final driftTeam = await db.teamDao.getTeam(teamId);

    if (driftTeam == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Team not found'},
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
      db: db,
      teamId: teamId,
      environment: env,
    );
    if (connections.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'No active GitHub connection for this team',
        },
      );
    }

    http.Client client;
    try {
      client = context.read<http.Client>();
    } catch (_) {
      client = http.Client();
    }

    final allRepos = <String, Map<String, dynamic>>{};
    for (final connection in connections) {
      final repos = await GitHubService.listRepositories(
        installationIdStr: connection.installationId.toString(),
        environment: env,
        client: client,
      );
      for (final repo in repos) {
        final fullName = repo['fullName'] as String;
        allRepos[fullName] = repo;
      }
    }

    return Response.json(
      body: {
        'success': true,
        'repositories': allRepos.values.toList(),
      },
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to list repositories for team $teamId',
    );
  }
}
