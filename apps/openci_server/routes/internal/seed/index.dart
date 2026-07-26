import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final db = context.read<AppDatabase>();
  final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  try {
    // Ensure test-team with installation_id 12345678 exists
    await db.customStatement('''
      INSERT INTO teams (id, name, installation_ids, ai_enabled, run_number, created_at, updated_at)
      VALUES ('test-team', 'Test Team', '[12345678]', true, 1, $nowEpoch, $nowEpoch)
      ON CONFLICT (id) DO NOTHING;
    ''');

    return Response.json(
      body: {
        'success': true,
        'message': 'Test team ensured successfully',
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
