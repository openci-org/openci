import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';

Middleware internalApiMiddleware() {
  return (handler) {
    return (context) {
      final validator = context.read<InternalApiKeyValidator>();
      if (validator.isValid(context) == false) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {'success': false, 'error': 'Authentication required'},
        );
      }
      return handler(context);
    };
  };
}
