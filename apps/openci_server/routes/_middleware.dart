import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:openci_server/database.dart';

final _db = AppDatabase();
final _firebaseApp = FirebaseApp.initializeApp();

Handler middleware(Handler handler) {
  return handler.use(databaseProvider(_db)).use(authProvider(_firebaseApp));
}

Middleware databaseProvider(AppDatabase db) {
  return provider<AppDatabase>((context) => db);
}

Middleware authProvider(FirebaseApp firebaseApp) {
  return (handler) {
    return (context) async {
      if (context.request.uri.path == '/') {
        return handler(context.provide<String?>(() => null));
      }

      final authHeader = context.request.headers['Authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return handler(context.provide<String?>(() => null));
      }

      final token = authHeader.substring(7);
      try {
        final decodedToken = await firebaseApp.auth().verifyIdToken(
          token,
          checkRevoked: true,
        );
        return handler(context.provide<String?>(() => decodedToken.uid));
      } catch (e) {
        stderr.writeln('Token verification failed: $e');
        return handler(context.provide<String?>(() => null));
      }
    };
  };
}
