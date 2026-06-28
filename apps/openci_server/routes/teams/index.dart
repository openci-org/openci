import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';
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
  try {
    String? uid;
    final db = context.read<AppDatabase>();
    uid = context.read<String?>();
    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }
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
    return handleRouteException(e, s, logMessage: 'Failed to get teams');
  }
}

Future<Response> _post(RequestContext context) async {
  try {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();
    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

    final Map<String, dynamic> payload;
    try {
      payload = await context.jsonBody();
    } on BadRequestException catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': e.message},
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
    final trimmedTeamName = teamName?.trim();

    if (trimmedTeamName == null || trimmedTeamName.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'name is required'},
      );
    }

    if (payload.containsKey('id') && payload['id'] is! String) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'id must be a string',
        },
      );
    }

    final payloadId = payload['id'] as String?;
    final trimmedPayloadId = payloadId?.trim();
    if (trimmedPayloadId != null && trimmedPayloadId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'id cannot be empty'},
      );
    }

    if (trimmedPayloadId != null) {
      final existingTeam = await db.teamDao.getTeam(trimmedPayloadId);
      if (existingTeam != null) {
        return Response.json(
          statusCode: HttpStatus.conflict,
          body: {
            'success': false,
            'error': 'Team with ID $trimmedPayloadId already exists',
          },
        );
      }
    }

    final teamId = trimmedPayloadId ?? const Uuid().v4();
    final now = DateTime.now().toUtc();

    final driftTeam = DriftTeam(
      id: teamId,
      name: trimmedTeamName,
      githubBaseUrl: null,
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
    return handleRouteException(e, s, logMessage: 'Failed to create team');
  }
}
