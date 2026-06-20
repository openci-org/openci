import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

Response? verifyWorkerAuth(RequestContext context, String? uid) {
  if (uid == null) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'success': false, 'error': 'Authentication required'},
    );
  }

  Map<String, String> env;
  try {
    env = context.read<Map<String, String>>();
  } catch (_) {
    env = Platform.environment;
  }

  final allowedUidsStr = env['ALLOWED_WORKER_UIDS'];
  if (allowedUidsStr == null || allowedUidsStr.trim().isEmpty) {
    throw StateError(
      'ALLOWED_WORKER_UIDS environment variable must be specified.',
    );
  }

  final allowedUids = allowedUidsStr
      .split(',')
      .map((u) => u.trim())
      .where((u) => u.isNotEmpty)
      .toSet();

  if (!allowedUids.contains(uid)) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'success': false, 'error': 'Forbidden: Worker not authorized'},
    );
  }

  return null;
}
