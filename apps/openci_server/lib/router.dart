import 'dart:convert';

import 'package:openci_server/db.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router getRouter(DatabaseManager db) {
  final router = Router();

  router.get('/', (Request request) {
    return Response.ok(
      'OpenCI Server (Shelf) is running!\n',
      headers: {'content-type': 'text/plain'},
    );
  });

  router.get('/health', (Request request) async {
    bool dbHealthy;
    try {
      dbHealthy = await db.verifyConnection();
    } catch (_) {
      dbHealthy = false;
    }

    final status = dbHealthy ? 'ok' : 'error';
    final responseBody = {
      'status': status,
      'database': dbHealthy ? 'connected' : 'disconnected',
    };

    return Response(
      dbHealthy ? 200 : 500,
      body: jsonEncode(responseBody),
      headers: {'content-type': 'application/json'},
    );
  });

  return router;
}
