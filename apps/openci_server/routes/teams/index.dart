import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/team/team_mapper.dart';
import 'package:openci_shared/openci_shared.dart';

FutureOr<Response> onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context) async {
  final db = context.read<AppDatabase>();
  final uid = context.read<String?>();
  if (uid == null) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'success': false, 'error': 'Unauthorized'},
    );
  }

  try {
    final driftTeams = await db.teamDao.getTeamsForUser(uid);
    final teams = <Team>[];

    for (final driftTeam in driftTeams) {
      final members = await (db.select(
        db.teamMembers,
      )..where((t) => t.teamId.equals(driftTeam.id))).get();
      final memberUidList = members.map((m) => m.userId).toList();

      teams.add(driftTeam.toShared(members: memberUidList));
    }

    return Response.json(
      body: teams.map((t) => t.toJson()).toList(),
    );
  } catch (e, s) {
    stderr.writeln('Failed to get teams for user $uid: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Internal server error',
      },
    );
  }
}
