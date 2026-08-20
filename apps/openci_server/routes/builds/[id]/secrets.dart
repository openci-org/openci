import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_service.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/secret/extract_secret_name.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:openci_server/secret/secret_table.dart';

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

    final workflowFileName = driftJob.workflowFileName;
    if (workflowFileName.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'No workflowFileName found for job'},
      );
    }

    final token = await GitHubService.getInstallationToken(
      installationIdStr: installationIdStr,
    );

    final workflowContent = await GitHubService.fetchWorkflowContent(
      owner: driftJob.owner,
      repo: driftJob.repo,
      workflowFileName: workflowFileName,
      installationIdStr: installationIdStr,
      token: token,
      commitSha: driftJob.commitSha,
      branch: driftJob.branch,
    );

    final usedSecretNames = extractSecretNames(workflowContent);

    final targetSecrets = <DriftSecret>[];
    if (teamId != null) {
      final secretMetadataList = await db.secretDao.getSecretsForTeam(teamId);
      final filtered = secretMetadataList.where((meta) {
        return usedSecretNames.contains(meta.name);
      }).toList();
      targetSecrets.addAll(filtered);
    }

    final resolvedSecrets = <String, String>{};
    resolvedSecrets['GITHUB_TOKEN'] = token;

    if (targetSecrets.isEmpty) {
      final secretFileContent = 'GITHUB_TOKEN=${token.replaceAll('\n', '\\n')}';
      return Response.json(
        body: {
          'success': true,
          'secretsContent': secretFileContent,
        },
      );
    }

    Map<String, String> env;
    try {
      env = context.read<Map<String, String>>();
    } catch (_) {
      env = Platform.environment;
    }
    final encryptionKey = env['SECRET_ENCRYPTION_KEY']!;
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
