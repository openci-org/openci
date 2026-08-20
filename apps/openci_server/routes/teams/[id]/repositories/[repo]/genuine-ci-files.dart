import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_service.dart';
import 'package:openci_server/request/error_handler.dart';

FutureOr<Response> onRequest(
  RequestContext context,
  String teamId,
  String repo,
) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, teamId, repo),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(
  RequestContext context,
  String teamId,
  String repo,
) async {
  try {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();

    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

    final isSystem = uid == 'system-job-processor';
    if (!isSystem) {
      final isMember = await db.teamDao.isTeamMember(uid, teamId);
      if (!isMember) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'success': false, 'error': 'Forbidden'},
        );
      }
    }

    final driftTeam = await (db.select(
      db.teams,
    )..where((tbl) => tbl.id.equals(teamId))).getSingleOrNull();

    if (driftTeam == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Team not found'},
      );
    }

    final installationIds = driftTeam.installationIds;
    if (installationIds.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'GitHub App is not installed for this team',
        },
      );
    }

    final queryParams = context.request.uri.queryParameters;
    final ref = queryParams['ref'] ?? 'HEAD';

    Map<String, String>? env;
    try {
      env = context.read<Map<String, String>>();
    } catch (_) {
      env = Platform.environment;
    }

    http.Client? client;
    try {
      client = context.read<http.Client>();
    } catch (_) {
      client = null;
    }

    // Determine owner: could be part of repo (e.g. owner/repo) or inferred
    final String owner;
    final String actualRepo;
    if (repo.contains('/')) {
      final parts = repo.split('/');
      owner = parts[0];
      actualRepo = parts[1];
    } else {
      owner = driftTeam.name;
      actualRepo = repo;
    }

    final files = await GitHubService.fetchGenuineCiFiles(
      owner: owner,
      repo: actualRepo,
      commitSha: ref,
      installationIdStr: installationIds.first.toString(),
      environment: env,
      client: client,
    );

    return Response.json(body: files.map((f) => f.toJson()).toList());
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage:
          'Failed to fetch genuine_ci files for team $teamId, repo $repo',
    );
  }
}
