import 'dart:convert';
import 'dart:typed_data';

import 'package:openci_server/db.dart';
import 'package:openci_server/storage.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router getRouter(DatabaseManager db, StorageManager storage) {
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

    bool storageHealthy;
    try {
      storageHealthy = await storage.verifyConnection();
    } catch (_) {
      storageHealthy = false;
    }

    final status = (dbHealthy && storageHealthy) ? 'ok' : 'error';
    final responseBody = {
      'status': status,
      'database': dbHealthy ? 'connected' : 'disconnected',
      'storage': storageHealthy ? 'connected' : 'disconnected',
    };

    return Response(
      (dbHealthy && storageHealthy) ? 200 : 500,
      body: jsonEncode(responseBody),
      headers: {'content-type': 'application/json'},
    );
  });

  router.get('/test-upload', (Request request) async {
    try {
      final testFileName = 'test_${DateTime.now().millisecondsSinceEpoch}.txt';
      final testContent =
          'Hello, this is a test artifact uploaded from OpenCI Server!';
      final stream = Stream.value(Uint8List.fromList(utf8.encode(testContent)));

      await storage.uploadObject(
        testFileName,
        stream,
        size: testContent.length,
      );

      final downloadUrl = await storage.getPresignedUrl(testFileName);

      return Response.ok(
        jsonEncode({
          'success': true,
          'file': testFileName,
          'downloadUrl': downloadUrl,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': e.toString(),
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  return router;
}
