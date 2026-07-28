import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final db = context.read<AppDatabase>();
  try {
    Map<String, dynamic> bodyJson = {};
    try {
      bodyJson = (await context.request.json()) as Map<String, dynamic>;
    } catch (_) {
      // Body is optional
    }

    final userId =
        bodyJson['userId'] as String? ?? bodyJson['userUid'] as String?;
    final teamId = bodyJson['teamId'] as String? ?? 'test-team';
    final teamName = bodyJson['name'] as String? ?? 'Test Team';

    await db.seedDao.ensureTestTeam(
      teamId: teamId,
      name: teamName,
      userId: userId,
    );

    return Response.json(
      body: {
        'success': true,
        'message': 'Test team seeded successfully',
        'teamId': teamId,
        'name': teamName,
        if (userId != null) 'userId': userId,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Failed to seed test team: $e',
      },
    );
  }
}
