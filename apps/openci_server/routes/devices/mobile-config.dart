import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.get || HttpMethod.post => Response.json(
      statusCode: HttpStatus.gone,
      body: {
        'success': false,
        'error': 'Automatic device enrollment is disabled.',
      },
    ),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}
