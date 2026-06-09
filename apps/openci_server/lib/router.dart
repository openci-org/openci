import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:openci_server/build_job/build_job_router.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/storage.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router getRouter(
  StorageManager storage, {
  required AppDatabase db,
  Map<String, String>? environment,
}) {
  final router = Router();
  final env = environment ?? Platform.environment;
  final appEnv = env['APP_ENV'] ?? 'development';

  router.get('/', (Request request) {
    return Response.ok(
      'OpenCI Server (Shelf) is running!\n',
      headers: {'content-type': 'text/plain'},
    );
  });

  router.post('/test-upload', (Request request) async {
    if (appEnv == 'production') {
      return Response.forbidden(
        jsonEncode({
          'success': false,
          'error': 'Test upload is disabled in production environment.',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

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
    } catch (e, s) {
      stderr.writeln('Test upload failed: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Internal server error',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  router.mount(
    '/builds',
    BuildJobRouter(
      db: db,
      appEnv: appEnv,
    ).router.call,
  );

  return router;
}
