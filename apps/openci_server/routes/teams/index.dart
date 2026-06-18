import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/team/team_mapper.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:uuid/uuid.dart';

FutureOr<Response> onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context),
    HttpMethod.post => _post(context),
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

Future<Response> _post(RequestContext context) async {
  final db = context.read<AppDatabase>();
  final uid = context.read<String?>();
  if (uid == null) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'success': false, 'error': 'Unauthorized'},
    );
  }

  final Map<String, dynamic> payload;
  try {
    final body = await context.request.body();
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Body must be a JSON object');
    }
    payload = decoded;
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'success': false, 'error': 'Invalid JSON: $e'},
    );
  }

  if (payload.containsKey('name') && payload['name'] is! String) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'success': false,
        'error': 'name must be a string',
      },
    );
  }
  final teamName = payload['name'] as String?;

  if (teamName == null || teamName.trim().isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'success': false, 'error': 'name is required'},
    );
  }

  try {
    final teamId = const Uuid().v4();
    final now = DateTime.now().toUtc();

    final driftTeam = DriftTeam(
      id: teamId,
      name: teamName,
      githubBaseUrl: null,
      githubApiBaseUrl: null,
      installationIds: const [],
      aiEnabled: true,
      runNumber: 1,
      createdAt: now,
      updatedAt: now,
    );

    await db.teamDao.createTeamAndMember(driftTeam, uid);

    return Response.json(
      body: {'success': true, 'id': teamId},
    );
  } catch (e, s) {
    stderr.writeln('Failed to create team: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Internal server error',
      },
    );
  }
}
