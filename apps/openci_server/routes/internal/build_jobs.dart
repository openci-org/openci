import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.delete) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final db = context.read<AppDatabase>();
  try {
    final queryParams = context.request.uri.queryParameters;
    final teamId = queryParams['team_id'];
    final jobId = queryParams['id'];

    int deletedCount;
    if (jobId != null && jobId.isNotEmpty) {
      deletedCount = await (db.delete(db.buildJobs)
            ..where((tbl) => tbl.id.equals(jobId)))
          .go();
    } else if (teamId != null && teamId.isNotEmpty) {
      deletedCount = await (db.delete(db.buildJobs)
            ..where((tbl) => tbl.teamId.equals(teamId)))
          .go();
    } else {
      deletedCount = await db.delete(db.buildJobs).go();
    }

    return Response.json(
      body: {
        'success': true,
        'deleted_count': deletedCount,
        'message': 'Build jobs deleted successfully',
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Failed to delete build jobs: $e',
      },
    );
  }
}
