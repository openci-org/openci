import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/auth/user_email_info.dart';

Middleware verifiedEmailMiddleware() {
  return (handler) {
    return (context) {
      final emailInfo = context.read<UserEmailInfo?>();
      if (emailInfo == null ||
          emailInfo.emailVerified == null ||
          emailInfo.emailVerified == false) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {
            'success': false,
            'error': 'Email verification required',
            'code': 'email_verification_required',
          },
        );
      }
      return handler(context);
    };
  };
}
