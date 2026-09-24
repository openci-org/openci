import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/database.dart';

Handler middleware(Handler handler) {
  return (context) async {
    final uid = context.read<String?>();
    final validator = context.read<InternalApiKeyValidator>();
    final hasValidInternalKey = validator.isValid(context);

    if (uid == null && !hasValidInternalKey) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

    final segments = context.request.uri.pathSegments;
    if (segments.length < 2 || segments[0] != 'builds') {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Invalid request path'},
      );
    }
    final id = segments[1];

    if (id == 'commits') {
      // Commit routes require a Firebase user and enforce team membership.
      if (uid == null) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {'success': false, 'error': 'Authentication required'},
        );
      }
      return handler(context);
    }

    final db = context.read<AppDatabase>();
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

    if (!hasValidInternalKey && uid != null) {
      final isMember = await db.teamDao.isTeamMember(uid, teamId);
      if (!isMember) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'success': false, 'error': 'Forbidden'},
        );
      }
    }

    return handler(context.provide<DriftBuildJob>(() => driftJob));
  };
}
