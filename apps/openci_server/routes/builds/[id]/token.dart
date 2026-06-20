import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_service.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context, String id) async {
  try {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();

    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

    final driftJob = await db.buildJobDao.getBuildJob(id);
    if (driftJob == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Build job not found'},
      );
    }

    final teamId = driftJob.teamId;
    if (teamId == null) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final env = Platform.environment;
    final allowedUidsStr = env['ALLOWED_WORKER_UIDS'] ?? '';
    final allowedUids = allowedUidsStr
        .split(',')
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toSet();

    if (!allowedUids.contains(uid)) {
      final isMember = await db.teamDao.isTeamMember(uid, teamId);
      if (!isMember) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'success': false, 'error': 'Forbidden'},
        );
      }
    }

    final installationIdStr = driftJob.installationId;
    if (installationIdStr == null || installationIdStr.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'No installationId found for job'},
      );
    }

    final token = await GitHubService.getInstallationToken(
      installationIdStr: installationIdStr,
      githubApiBaseUrlStr: driftJob.githubApiBaseUrl,
    );

    return Response.json(body: {'token': token});
  } on StateError catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': e.message},
    );
  } on HttpException catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': e.message},
    );
  } catch (e, s) {
    stderr.writeln('Failed to resolve token for job $id: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': 'Internal server error'},
    );
  }
}
