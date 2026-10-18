import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_service.dart';
import 'package:openci_server/github/parse_github_api_base_uri.dart';
import 'package:openci_server/github/read_active_github_connections.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/secret/extract_secret_name.dart';
import 'package:openci_server/secret/secret_crypter.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context, String id) async {
  try {
    final driftJob = context.read<DriftBuildJob>();
    final db = context.read<AppDatabase>();

    final teamId = driftJob.teamId;

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
    if (teamId == null || teamId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final workflowFileName = driftJob.workflowFileName;
    if (workflowFileName.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'No workflowFileName found for job'},
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
      db: db,
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
      // GitHubService creates its own HTTP requests when none is provided.
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

    final token = await GitHubService.getInstallationToken(
      installationIdStr: installationId.toString(),
      environment: environment,
      client: client,
    );
    if (token.trim().isEmpty) {
      throw const FormatException(
        'GitHub returned an empty installation token',
      );
    }

    final workflowContent = await GitHubService.fetchWorkflowContent(
      owner: driftJob.owner,
      repo: driftJob.repo,
      workflowFileName: workflowFileName,
      installationIdStr: installationIdStr,
      token: token,
      commitSha: driftJob.commitSha,
      branch: driftJob.branch,
      environment: environment,
      client: client,
    );

    String? secretDefinitions;
    if (workflowFileName.endsWith('.dart') &&
        RegExp(r'\bSecrets\s*\.').hasMatch(workflowContent)) {
      final importsGeneratedDefinitions = RegExp(
        r'''^\s*import\s+['"](?:\.\.?/)*generated/secrets\.g\.dart['"]''',
        multiLine: true,
      ).hasMatch(workflowContent);
      secretDefinitions = await GitHubService.fetchWorkflowContent(
        owner: driftJob.owner,
        repo: driftJob.repo,
        workflowFileName: importsGeneratedDefinitions
            ? 'generated/secrets.g.dart'
            : 'secrets.g.dart',
        installationIdStr: installationIdStr,
        token: token,
        commitSha: driftJob.commitSha,
        branch: driftJob.branch,
        environment: environment,
        client: client,
      );
    }
    final usedSecretNames = extractSecretNames(
      workflowContent,
      secretDefinitions: secretDefinitions,
    );

    final secretMetadataList = await db.secretDao.getSecretsForTeam(teamId);
    final targetSecrets = secretMetadataList.where((meta) {
      return usedSecretNames.contains(meta.name);
    }).toList();

    final resolvedSecrets = <String, String>{};
    resolvedSecrets['GITHUB_TOKEN'] = token;

    if (targetSecrets.isEmpty) {
      final secretFileContent = 'GITHUB_TOKEN=${token.replaceAll('\n', '\\n')}';
      return Response.json(
        headers: {HttpHeaders.cacheControlHeader: 'no-store'},
        body: {
          'success': true,
          'secretsContent': secretFileContent,
        },
      );
    }

    final encryptionKey = environment['SECRET_ENCRYPTION_KEY']!;
    final crypter = SecretCrypter(encryptionKey);

    for (final sec in targetSecrets) {
      try {
        final decryptedValue = await crypter.decrypt(sec.encryptedValue);
        resolvedSecrets[sec.name] = decryptedValue;
      } catch (e) {
        throw Exception('Failed to decrypt secret "${sec.name}": $e');
      }
    }

    final secretFileContent = resolvedSecrets.entries
        .map((entry) => '${entry.key}=${entry.value.replaceAll('\n', '\\n')}')
        .join('\n');

    return Response.json(
      headers: {HttpHeaders.cacheControlHeader: 'no-store'},
      body: {
        'success': true,
        'secretsContent': secretFileContent,
      },
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to resolve secrets for job $id',
    );
  }
}
