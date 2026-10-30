import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/billing/billing_proxy.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.delete => _delete(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _delete(RequestContext context, String id) async {
  try {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();
    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }
    final proxy = context.read<BillingProxy?>();
    if (proxy != null) {
      return await proxy.request(
        operation: BillingOperation.deleteTeam,
        teamId: id,
        uid: uid,
      );
    }
    final isMember = await db.teamDao.isTeamMember(uid, id);
    if (!isMember) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final currentDriftTeam = await (db.select(
      db.teams,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (currentDriftTeam == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Team not found'},
      );
    }

    await db.teamDao.deleteTeam(id);

    return Response.json(
      body: {'success': true},
    );
  } catch (e, s) {
    return handleRouteException(e, s, logMessage: 'Failed to delete team $id');
  }
}
