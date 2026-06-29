import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/device/udid_request_table.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:uuid/uuid.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.post => _post(context, id),
    HttpMethod.get => _get(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _post(RequestContext context, String teamId) async {
  try {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();
    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

    final isMember = await db.teamDao.isTeamMember(uid, teamId);
    if (!isMember) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final bodyStr = await context.request.body();
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(bodyStr) as Map<String, dynamic>;
    } catch (_) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Invalid JSON body'},
      );
    }

    final udid = body['udid'] as String?;

    if (udid == null || udid.trim().isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Missing required parameter: udid'},
      );
    }

    final requestId = const Uuid().v4();
    final now = DateTime.now().toUtc();

    final driftRequest = DriftUdidRequest(
      id: requestId,
      userId: uid,
      teamId: teamId,
      udid: udid.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await db.udidRequestDao.createRequest(driftRequest);

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'success': true,
        'request': driftRequest.toJson(),
      },
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to create UDID request',
    );
  }
}

Future<Response> _get(RequestContext context, String teamId) async {
  try {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();
    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

    final isMember = await db.teamDao.isTeamMember(uid, teamId);
    if (!isMember) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final requests = await db.udidRequestDao.getRequestsByTeamId(teamId);

    return Response.json(
      body: {
        'success': true,
        'requests': requests.map((r) => r.toJson()).toList(),
      },
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to get UDID requests',
    );
  }
}
