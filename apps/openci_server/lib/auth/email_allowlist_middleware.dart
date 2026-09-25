import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/auth/server_access_policy.dart';
import 'package:openci_server/auth/user_email_info.dart';

Middleware emailAllowlistMiddleware() {
  return (handler) {
    return (context) {
      final emailInfo = context.read<UserEmailInfo?>();
      final policy = context.read<ServerAccessPolicy>();
      if (emailInfo == null || !policy.isEmailAllowed(emailInfo.email)) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {
            'success': false,
            'error': 'Access denied',
            'code': 'access_denied',
          },
        );
      }
      return handler(context);
    };
  };
}
