import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final db = context.read<AppDatabase>();
  try {
    await db.seedDao.ensureTestTeam();
    final job = await db.seedDao.createTestBuildJob();

    return Response.json(
      body: {
        'success': true,
        'message': 'Test team and build job seeded successfully',
        'jobId': job.id,
        'runsOn': job.runsOn,
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
