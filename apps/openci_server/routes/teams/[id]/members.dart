import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:openci_server/database.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    HttpMethod.post => _post(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context, String id) async {
  final db = context.read<AppDatabase>();
  final firebaseApp = context.read<FirebaseApp>();
  final uid = context.read<String?>();

  if (uid == null) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'success': false, 'error': 'Unauthorized'},
    );
  }

  final isMember = await db.teamDao.isTeamMember(uid, id);
  if (!isMember) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'success': false, 'error': 'Forbidden'},
    );
  }

  final driftMembers = await db.teamDao.getTeamMembers(id);

  final members = <Map<String, dynamic>>[];
  for (final member in driftMembers) {
    final userRecord = await firebaseApp.auth().getUser(member.userId);
    members.add({
      'uid': member.userId,
      'email': userRecord.email,
      'displayName': userRecord.displayName,
      'photoURL': userRecord.photoUrl,
    });
  }
  return Response.json(body: {'members': members});
}

Future<Response> _post(RequestContext context, String id) async {
  final db = context.read<AppDatabase>();
  final firebaseApp = context.read<FirebaseApp>();
  final uid = context.read<String?>();

  if (uid == null) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'success': false, 'error': 'Unauthorized'},
    );
  }

  final isMember = await db.teamDao.isTeamMember(uid, id);
  if (!isMember) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'success': false, 'error': 'Forbidden'},
    );
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final email = body['email'] as String?;
  if (email == null || email.trim().isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'success': false, 'error': 'Email is required'},
    );
  }

  final normalizedEmail = email.trim().toLowerCase();
  try {
    final userRecord = await firebaseApp.auth().getUserByEmail(
      normalizedEmail,
    );
    final targetUid = userRecord.uid;

    final isAlreadyMember = await db.teamDao.isTeamMember(targetUid, id);
    if (isAlreadyMember) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'User is already a member of this team.',
        },
      );
    }

    await db.teamDao.addTeamMember(id, targetUid);
    return Response.json(body: {'success': true});
  } catch (e) {
    if (e.toString().contains('user-not-found') ||
        e.toString().contains('UserNotFound') ||
        e.toString().contains('no user record')) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {
          'success': false,
          'error':
              'User not found. The member you want to add must already be registered on the dashboard.',
        },
      );
    }
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': e.toString()},
    );
  }
}
