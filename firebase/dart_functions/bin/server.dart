import 'package:dart_functions/github/github_webhook_handler.dart';
import 'package:dart_functions/util/sentry_init.dart';
import 'package:firebase_functions/firebase_functions.dart';

void main(List<String> args) async {
  await initSentry();

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
