import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context, String id, String runId) {
  return Response.json(
    statusCode: HttpStatus.notImplemented,
    body: {'success': false, 'error': 'Build log streaming is not implemented'},
  );
}
