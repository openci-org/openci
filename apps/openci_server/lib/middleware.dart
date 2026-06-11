import 'dart:io';

import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Handler applyMiddleware(Router router, {FirebaseApp? firebaseApp}) {
  final Middleware authMiddlewareInstance;
  if (firebaseApp == null) {
    authMiddlewareInstance = (Handler innerHandler) {
      return (Request request) {
        final updatedRequest = request.change(context: {'uid': 'test-uid'});
        return innerHandler(updatedRequest);
      };
    };
  } else {
    authMiddlewareInstance = authMiddleware(firebaseApp);
  }

  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(authMiddlewareInstance)
      .addHandler(router.call);
}

Middleware authMiddleware(FirebaseApp app) {
  final auth = app.auth();

  return (Handler innerHandler) {
    return (Request request) async {
      if (request.url.path == '' ||
          request.url.path == '/' ||
          request.requestedUri.path == '/') {
        return innerHandler(request);
      }

      final authHeader = request.headers['Authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(
          401,
          body: 'Unauthorized: Missing or invalid Authorization header',
          headers: {'content-type': 'text/plain'},
        );
      }

      final token = authHeader.substring(7);

      try {
        final decodedToken = await auth.verifyIdToken(
          token,
          checkRevoked: true,
        );
        final uid = decodedToken.uid;

        final updatedRequest = request.change(context: {'uid': uid});
        return innerHandler(updatedRequest);
      } catch (e) {
        stderr.writeln('Token verification failed: $e');
        return Response(
          401,
          body: 'Unauthorized: Token verification failed',
          headers: {'content-type': 'text/plain'},
        );
      }
    };
  };
}
