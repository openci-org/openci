import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/auth/user_email_info.dart';

import '../routes/_middleware.dart';

// Invoked by auth_emulator_test.dart in a fresh process without emulator mode.
Future<void> main(List<String> args) async {
  if (args.length != 1 ||
      Platform.environment.containsKey('FIREBASE_AUTH_EMULATOR_HOST') ||
      Platform.environment.containsKey('GOOGLE_APPLICATION_CREDENTIALS') ||
      Platform.environment.containsKey('GOOGLE_CLOUD_PROJECT') ||
      Platform.environment.containsKey('FIREBASE_CONFIG')) {
    throw StateError(
      'The production probe requires one token and no emulator or Firebase credentials.',
    );
  }

  final app = FirebaseApp.initializeApp(
    options: const AppOptions(projectId: 'demo-openci'),
    name: 'auth-production-mode-probe',
  );
  final handler =
      authProvider(app)((context) {
        final uid = context.read<String?>();
        final info = context.read<UserEmailInfo?>();
        return Response.json(
          statusCode: uid == null ? HttpStatus.unauthorized : HttpStatus.ok,
          body: {'uid': uid, 'email': info?.email},
        );
      }).use(
        provider<InternalApiKeyValidator>(
          (_) => const InternalApiKeyValidator.forTesting(environment: {}),
        ),
      );
  final server = await serve(handler, InternetAddress.loopbackIPv4, 0);
  try {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:${server.port}/protected'),
      headers: {'Authorization': 'Bearer ${args.single}'},
    );
    if (response.statusCode != HttpStatus.unauthorized) {
      throw StateError(
        'Unsigned emulator token was accepted without emulator mode.',
      );
    }
  } finally {
    await server.close(force: true);
    await FirebaseApp.deleteApp(app);
  }
}
