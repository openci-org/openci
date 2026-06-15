import 'dart:convert';
import 'dart:io';

import 'package:openci_server/database.dart';
import 'package:openci_server/team/team_mapper.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

class TeamRouter {
  final AppDatabase db;

  TeamRouter({required this.db});

  Router get router {
    final router = Router();

    router.get('/', (Request request) async {
      final uid = request.context['uid'] as String?;
      if (uid == null) {
        return Response.forbidden(
          jsonEncode({'success': false, 'error': 'Unauthorized'}),
          headers: {'content-type': 'application/json'},
        );
      }

      try {
        final driftTeams = await db.teamDao.getTeamsForUser(uid);
        final teams = <Team>[];

        for (final driftTeam in driftTeams) {
          final members = await (db.select(
            db.teamMembers,
          )..where((t) => t.teamId.equals(driftTeam.id))).get();
          final memberUids = members.map((m) => m.userId).toList();

          teams.add(driftTeam.toShared(members: memberUids));
        }

        return Response.ok(
          jsonEncode(teams.map((t) => t.toJson()).toList()),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, s) {
        stderr.writeln('Failed to get teams for user $uid: $e\n$s');
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': 'Internal server error',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    router.post('/', (Request request) async {
      final uid = request.context['uid'] as String?;
      if (uid == null) {
        return Response.forbidden(
          jsonEncode({'success': false, 'error': 'Unauthorized'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final Map<String, dynamic> payload;
      try {
        final body = await request.readAsString();
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Body must be a JSON object');
        }
        payload = decoded;
      } catch (e) {
        return Response.badRequest(
          body: jsonEncode({'success': false, 'error': 'Invalid JSON: $e'}),
          headers: {'content-type': 'application/json'},
        );
      }

      if (payload.containsKey('name') && payload['name'] is! String) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'name must be a string',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
      final teamName = payload['name'] as String?;

      if (teamName == null || teamName.trim().isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'success': false, 'error': 'name is required'}),
          headers: {'content-type': 'application/json'},
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

        return Response.ok(
          jsonEncode({'success': true, 'id': teamId}),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, s) {
        stderr.writeln('Failed to create team: $e\n$s');
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': 'Internal server error',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    router.patch('/<teamId>', (Request request, String teamId) async {
      final uid = request.context['uid'] as String?;
      if (uid == null) {
        return Response.forbidden(
          jsonEncode({'success': false, 'error': 'Unauthorized'}),
          headers: {'content-type': 'application/json'},
        );
      }

      try {
        final isMember = await db.teamDao.isTeamMember(uid, teamId);
        if (!isMember) {
          return Response.forbidden(
            jsonEncode({'success': false, 'error': 'Forbidden'}),
            headers: {'content-type': 'application/json'},
          );
        }
      } catch (e, s) {
        stderr.writeln('Failed to check membership for team $teamId: $e\n$s');
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': 'Internal server error',
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      final Map<String, dynamic> payload;
      try {
        final body = await request.readAsString();
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Body must be a JSON object');
        }
        payload = decoded;
      } catch (e) {
        return Response.badRequest(
          body: jsonEncode({'success': false, 'error': 'Invalid JSON: $e'}),
          headers: {'content-type': 'application/json'},
        );
      }

      if (payload.containsKey('name')) {
        final val = payload['name'];
        if (val is! String) {
          return Response.badRequest(
            body: jsonEncode({
              'success': false,
              'error': 'name must be a string',
            }),
            headers: {'content-type': 'application/json'},
          );
        }
        if (val.trim().isEmpty) {
          return Response.badRequest(
            body: jsonEncode({
              'success': false,
              'error': 'name cannot be empty',
            }),
            headers: {'content-type': 'application/json'},
          );
        }
      }
      if (payload.containsKey('githubBaseUrl') &&
          payload['githubBaseUrl'] != null &&
          payload['githubBaseUrl'] is! String) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'githubBaseUrl must be a string or null',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
      if (payload.containsKey('githubApiBaseUrl') &&
          payload['githubApiBaseUrl'] != null &&
          payload['githubApiBaseUrl'] is! String) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'githubApiBaseUrl must be a string or null',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
      if (payload.containsKey('installationIds')) {
        final val = payload['installationIds'];
        if (val is! List || !val.every((element) => element is int)) {
          return Response.badRequest(
            body: jsonEncode({
              'success': false,
              'error': 'installationIds must be a list of integers',
            }),
            headers: {'content-type': 'application/json'},
          );
        }
      }
      if (payload.containsKey('aiEnabled') && payload['aiEnabled'] is! bool) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'aiEnabled must be a boolean',
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      try {
        final currentDriftTeam = await (db.select(
          db.teams,
        )..where((t) => t.id.equals(teamId))).getSingleOrNull();

        if (currentDriftTeam == null) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Team not found'}),
            headers: {'content-type': 'application/json'},
          );
        }

        final now = DateTime.now().toUtc();
        final updatedDriftTeam = DriftTeam(
          id: teamId,
          name: payload['name'] as String? ?? currentDriftTeam.name,
          githubBaseUrl: payload.containsKey('githubBaseUrl')
              ? payload['githubBaseUrl'] as String?
              : currentDriftTeam.githubBaseUrl,
          githubApiBaseUrl: payload.containsKey('githubApiBaseUrl')
              ? payload['githubApiBaseUrl'] as String?
              : currentDriftTeam.githubApiBaseUrl,
          installationIds: payload.containsKey('installationIds')
              ? (payload['installationIds'] as List<dynamic>).cast<int>()
              : currentDriftTeam.installationIds,
          aiEnabled: payload.containsKey('aiEnabled')
              ? payload['aiEnabled'] as bool
              : currentDriftTeam.aiEnabled,
          runNumber: currentDriftTeam.runNumber,
          createdAt: currentDriftTeam.createdAt,
          updatedAt: now,
        );

        await db.teamDao.updateTeam(updatedDriftTeam);

        return Response.ok(
          jsonEncode({'success': true}),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, s) {
        stderr.writeln('Failed to update team $teamId: $e\n$s');
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': 'Internal server error',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    router.delete('/<teamId>', (Request request, String teamId) async {
      final uid = request.context['uid'] as String?;
      if (uid == null) {
        return Response.forbidden(
          jsonEncode({'success': false, 'error': 'Unauthorized'}),
          headers: {'content-type': 'application/json'},
        );
      }

      try {
        final isMember = await db.teamDao.isTeamMember(uid, teamId);
        if (!isMember) {
          return Response.forbidden(
            jsonEncode({'success': false, 'error': 'Forbidden'}),
            headers: {'content-type': 'application/json'},
          );
        }

        final currentDriftTeam = await (db.select(
          db.teams,
        )..where((t) => t.id.equals(teamId))).getSingleOrNull();

        if (currentDriftTeam == null) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Team not found'}),
            headers: {'content-type': 'application/json'},
          );
        }

        await db.teamDao.deleteTeam(teamId);

        return Response.ok(
          jsonEncode({'success': true}),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, s) {
        stderr.writeln('Failed to delete team $teamId: $e\n$s');
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': 'Internal server error',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    return router;
  }
}
