import 'dart:io';

import 'package:dart_functions/github/github_webhook_handler.dart';
import 'package:dart_functions/util/sentry_init.dart';
import 'package:firebase_functions/firebase_functions.dart';

void main(List<String> args) async {
  // Initialize Sentry in the background.
  // Must not block server startup – Cloud Run requires PORT=8080 to be
  // listening within the startup timeout.
  try {
    await initSentry();
  } catch (e) {
    stderr.writeln('Warning: Sentry initialization failed: $e');
  }

  await fireUp(args, (firebase) {
    firebase.https.onRequest(
      handleGitHubWebhook,
      name: 'github-webhook',
      options: const HttpsOptions(
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
    );
  });
}
