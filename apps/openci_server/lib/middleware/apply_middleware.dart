import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:openci_server/middleware/auth_middleware.dart';
import 'package:openci_server/middleware/cors_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Handler applyMiddleware(
  Router router, {
  FirebaseApp? firebaseApp,
  Map<String, String>? environment,
}) {
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
      .addMiddleware(corsMiddleware(environment: environment))
      .addMiddleware(logRequests())
      .addMiddleware(authMiddlewareInstance)
      .addHandler(router.call);
}
