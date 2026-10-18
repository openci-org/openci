import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/database.dart';
import 'package:openci_server/github/changed_files.dart';
import 'package:openci_server/github/github_service.dart';
import 'package:openci_server/github/parse_github_api_base_uri.dart';
import 'package:openci_server/request/error_handler.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  try {
    final db = context.read<AppDatabase>();
    final task = await db.webhookTaskDao.getWebhookTask(id);
    if (task == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'WebhookTask not found'},
      );
    }
    final repository = switch (jsonDecode(task.payload)) {
      {
        'repository': {
          'owner': {'login': final String owner},
          'name': final String repo,
        },
        'installation': {'id': final int installationId},
      }
          when owner.trim().isNotEmpty &&
              repo.trim().isNotEmpty &&
              installationId > 0 =>
        (owner: owner, repo: repo, installationId: installationId),
      _ => throw const FormatException(
        'Stored webhook has no valid repository installation',
      ),
    };

    var environment = Platform.environment;
    try {
      environment = context.read<Map<String, String>>();
    } catch (_) {
      // Use the process environment when no override is provided.
    }
    final apiBaseUrl = parseGitHubApiBaseUri(
      environment['GITHUB_API_BASE_URL'],
    ).toString();
    final appId = int.tryParse(
      environment['GITHUB_APP_ID']?.trim() ?? '',
      radix: 10,
    );
    if (appId == null || appId <= 0) {
      throw StateError('GITHUB_APP_ID must be a positive integer');
    }
    environment = {...environment, 'GITHUB_API_BASE_URL': apiBaseUrl};

    final team = await db.teamDao.getTeamByInstallationId(
      repository.installationId,
      githubApiBaseUrl: apiBaseUrl,
      githubAppId: appId,
    );
    if (team == null) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    http.Client? providedClient;
    try {
      providedClient = context.read<http.Client>();
    } catch (_) {
      // Create a client when one is not provided by the request context.
    }
    final client = providedClient ?? http.Client();
    try {
      final installationId = await GitHubService.getRepositoryInstallationId(
        owner: repository.owner,
        repo: repository.repo,
        environment: environment,
        client: client,
      );
      if (installationId != repository.installationId.toString()) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'success': false, 'error': 'Forbidden'},
        );
      }

      final result = await fetchChangedFiles(
        eventType: task.eventType,
        payload: task.payload,
        environment: environment,
        client: client,
      );
      // A rejected GitHub request must not become a successful diff fallback.
      if (result.reason?.startsWith('github_') == true ||
          result.reason == 'invalid_response') {
        throw StateError('Failed to fetch changed files from GitHub');
      }
      return Response.json(body: result.toJson());
    } finally {
      if (providedClient == null) client.close();
    }
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to fetch changed files for webhook task $id',
    );
  }
}
