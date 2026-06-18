import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.patch => _patch(context, id),
    HttpMethod.delete => _delete(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _patch(RequestContext context, String id) async {
  final db = context.read<AppDatabase>();
  final uid = context.read<String?>();
  if (uid == null) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'success': false, 'error': 'Unauthorized'},
    );
  }

  try {
    final isMember = await db.teamDao.isTeamMember(uid, id);
    if (!isMember) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }
  } catch (e, s) {
    stderr.writeln('Failed to check membership for team $id: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Internal server error',
      },
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

  if (payload.containsKey('name')) {
    final val = payload['name'];
    if (val is! String) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'name must be a string',
        },
      );
    }
    if (val.trim().isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'name cannot be empty',
        },
      );
    }
  }

  if (payload.containsKey('githubBaseUrl') &&
      payload['githubBaseUrl'] != null &&
      payload['githubBaseUrl'] is! String) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'success': false,
        'error': 'githubBaseUrl must be a string or null',
      },
    );
  }

  if (payload.containsKey('githubApiBaseUrl') &&
      payload['githubApiBaseUrl'] != null &&
      payload['githubApiBaseUrl'] is! String) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'success': false,
        'error': 'githubApiBaseUrl must be a string or null',
      },
    );
  }

  if (payload.containsKey('installationIds')) {
    final val = payload['installationIds'];
    if (val is! List || !val.every((element) => element is int)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'installationIds must be a list of integers',
        },
      );
    }
  }

  if (payload.containsKey('aiEnabled') && payload['aiEnabled'] is! bool) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'success': false,
        'error': 'aiEnabled must be a boolean',
      },
    );
  }

  try {
    final currentDriftTeam = await (db.select(
      db.teams,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (currentDriftTeam == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Team not found'},
      );
    }

    final now = DateTime.now().toUtc();
    final updatedDriftTeam = DriftTeam(
      id: id,
      name: payload.containsKey('name')
          ? (payload['name'] as String).trim()
          : currentDriftTeam.name,
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

    return Response.json(
      body: {'success': true},
    );
  } catch (e, s) {
    stderr.writeln('Failed to update team $id: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Internal server error',
      },
    );
  }
}

Future<Response> _delete(RequestContext context, String id) async {
  final db = context.read<AppDatabase>();
  final uid = context.read<String?>();
  if (uid == null) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'success': false, 'error': 'Unauthorized'},
    );
  }

  try {
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
    stderr.writeln('Failed to delete team $id: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Internal server error',
      },
    );
  }
}
