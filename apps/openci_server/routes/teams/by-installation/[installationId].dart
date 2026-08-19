import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/team/team_mapper.dart';

FutureOr<Response> onRequest(RequestContext context, String installationId) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, installationId),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context, String installationIdStr) async {
  try {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();

    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

    final installationId = int.tryParse(installationIdStr);
    if (installationId == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Invalid installationId'},
      );
    }

    final driftTeam = await db.teamDao.getTeamByInstallationId(installationId);
    if (driftTeam == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Team not found'},
      );
    }

    final members = await (db.select(
      db.teamMembers,
    )..where((t) => t.teamId.equals(driftTeam.id))).get();
    final memberUidList = members.map((m) => m.userId).toList();

    return Response.json(
      body: driftTeam.toShared(members: memberUidList).toJson(),
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to get team for installationId $installationIdStr',
    );
  }
}
