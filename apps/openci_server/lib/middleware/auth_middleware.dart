import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:shelf/shelf.dart';

Middleware authMiddleware(FirebaseApp app) {
  final auth = app.auth();

  return (Handler innerHandler) {
    return (Request request) async {
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
        final decodedToken = await auth.verifyIdToken(token, checkRevoked: true);
        final uid = decodedToken.uid;

        final updatedRequest = request.change(context: {'uid': uid});
        return await innerHandler(updatedRequest);
      } catch (e) {
        return Response(
          401,
          body: 'Unauthorized: Token verification failed ($e)',
          headers: {'content-type': 'text/plain'},
        );
      }
    };
  };
}
