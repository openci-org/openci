import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_service.dart';
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

    Map<String, String> env;
    try {
      env = context.read<Map<String, String>>();
    } catch (_) {
      env = Platform.environment;
    }

    final defaultApiBaseUrl = env['GITHUB_API_BASE_URL']!;
    final String apiBaseUrl;
    if (driftTeam.githubBaseUrl != null &&
        driftTeam.githubBaseUrl!.isNotEmpty) {
      apiBaseUrl = _getApiBaseUrlFromValue(driftTeam.githubBaseUrl!);
    } else {
      apiBaseUrl = defaultApiBaseUrl;
    }

    http.Client client;
    try {
      client = context.read<http.Client>();
    } catch (_) {
      client = http.Client();
    }

    List<Map<String, dynamic>>? files;
    Object? lastError;

    for (final installationId in installationIds) {
      try {
        final token = await GitHubService.getInstallationToken(
          installationIdStr: installationId.toString(),
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
        if (data['errors'] != null) {
          final errStr = jsonEncode(data['errors']);
          if (errStr.contains('Could not resolve to an object')) {
            files = [];
            break;
          }
          throw HttpException('GraphQL errors: $errStr');
        }

        final repositoryObj = data['data']?['repository'];
        if (repositoryObj == null) {
          continue;
        }

        final objectObj = repositoryObj['object'];
        if (objectObj == null) {
          files = [];
          break;
        }

        final entries = objectObj['entries'] as List<dynamic>? ?? [];
        final list = <Map<String, dynamic>>[];
        for (final entry in entries) {
          final type = entry['type'] as String?;
          final name = entry['name'] as String?;
          final text = entry['object']?['text'] as String?;
          if (type == 'blob' && name != null && text != null) {
            if (name.endsWith('.yaml') || name.endsWith('.yml')) {
              list.add({
                'name': name,
                'path': '.openci/$name',
                'content': text,
              });
            }
          }
        }
        files = list;
        break;
      } catch (e) {
        lastError = e;
      }
    }

    if (files == null) {
      if (lastError != null) {
        throw lastError;
      }
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {
          'success': false,
          'error': 'Repository not found in any installation',
        },
      );
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

String _getApiBaseUrlFromValue(String githubBaseUrl) {
  final normalized = githubBaseUrl.replaceAll(RegExp(r'/+$'), '');
  if (normalized == 'https://github.com' ||
      normalized == 'https://api.github.com') {
    return 'https://api.github.com';
  }
  return '${Uri.parse(normalized).origin}/api/v3';
}

String _graphqlEndpoint(String apiBaseUrl) {
  final normalized = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  if (normalized == 'https://api.github.com') {
    return 'https://api.github.com/graphql';
  }
  return '${Uri.parse(normalized).origin}/api/graphql';
}
