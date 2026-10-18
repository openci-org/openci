import 'dart:async';
import 'dart:convert';
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

    final queryParams = context.request.uri.queryParameters;
    final repository = queryParams['repository'];
    final branch = queryParams['branch'] ?? 'HEAD';

    if (repository == null || repository.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'repository is required'},
      );
    }

    final parts = repository.split('/');
    if (parts.length != 2) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'repository must be in owner/repo format',
        },
      );
    }
    final owner = parts[0];
    final repo = parts[1];

    final driftTeam = await (db.select(
      db.teams,
    )..where((tbl) => tbl.id.equals(teamId))).getSingleOrNull();

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

    final apiBaseUrl = parseGitHubApiBaseUri(
      env['GITHUB_API_BASE_URL'],
    ).toString();
    env = {...env, 'GITHUB_API_BASE_URL': apiBaseUrl};

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

    final installationId = await GitHubService.getRepositoryInstallationId(
      owner: owner,
      repo: repo,
      environment: env,
      client: client,
    );
    final hasConnection = connections.any(
      (connection) => connection.installationId.toString() == installationId,
    );
    if (!hasConnection) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final token = await GitHubService.getInstallationToken(
      installationIdStr: installationId,
      environment: env,
      client: client,
    );

    final expression = '$branch:.openci';
    final graphqlUrl = _graphqlEndpoint(apiBaseUrl);

    const query = r'''
          query($owner: String!, $repo: String!, $expression: String!) {
            repository(owner: $owner, name: $repo) {
              object(expression: $expression) {
                ... on Tree {
                  entries {
                    name
                    type
                    object {
                      ... on Blob { text }
                    }
                  }
                }
              }
            }
          }
        ''';

    final response = await client.post(
      Uri.parse(graphqlUrl),
      headers: {
        'accept': 'application/vnd.github.v3+json',
        'authorization': 'bearer $token',
        'content-type': 'application/json; charset=utf-8',
        'user-agent': 'OpenCI-Server',
      },
      body: jsonEncode({
        'query': query,
        'variables': {
          'owner': owner,
          'repo': repo,
          'expression': expression,
        },
      }),
    );

    if (response.statusCode >= 300) {
      throw HttpException(
        'GraphQL request failed: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final errors = data['errors'];
    if (errors != null) {
      final missingTree =
          errors is List &&
          errors.isNotEmpty &&
          errors.every(
            (error) =>
                error is Map &&
                error['message'] is String &&
                (error['message'] as String).contains(
                  'Could not resolve to an object',
                ),
          );
      if (missingTree) {
        return Response.json(body: {'success': true, 'files': []});
      }
      throw HttpException('GraphQL errors: ${jsonEncode(errors)}');
    }

    final repositoryObj = data['data']?['repository'];
    if (repositoryObj == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {
          'success': false,
          'error': 'Repository not found in any installation',
        },
      );
    }

    final entries = repositoryObj['object']?['entries'] as List<dynamic>? ?? [];
    final files = <Map<String, dynamic>>[];
    for (final entry in entries) {
      final type = entry['type'] as String?;
      final name = entry['name'] as String?;
      final text = entry['object']?['text'] as String?;
      if (type == 'blob' && name != null && text != null) {
        if (name.endsWith('.yaml') || name.endsWith('.yml')) {
          files.add({
            'name': name,
            'path': '.openci/$name',
            'content': text,
          });
        }
      }
    }

    return Response.json(
      body: {
        'success': true,
        'files': files,
      },
    );
  } catch (e, s) {
    return handleRouteException(e, s, logMessage: 'Failed to list workflows');
  }
}

String _graphqlEndpoint(String apiBaseUrl) {
  final normalized = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  if (normalized == 'https://api.github.com') {
    return 'https://api.github.com/graphql';
  }
  return '${Uri.parse(normalized).origin}/api/graphql';
}
