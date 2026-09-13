import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

FutureOr<Response> onRequest(
  RequestContext context,
  String id,
  String runId,
) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id, runId),
    HttpMethod.post => _post(context, id, runId),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(
  RequestContext context,
  String id,
  String runId,
) async {
  return Response.json(
    statusCode: HttpStatus.notImplemented,
    body: {'success': false, 'error': 'Step history is not implemented'},
  );
}

Future<Response> _post(
  RequestContext context,
  String id,
  String runId,
) async {
  return Response.json(
    statusCode: HttpStatus.notImplemented,
    body: {'success': false, 'error': 'Step saving is not implemented'},
  );
}
