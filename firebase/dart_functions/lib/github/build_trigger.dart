import '../util/logger.dart';
import 'installation_token.dart';
import 'webhook_event.dart';

Future<void> handleBuildTrigger(WebhookEvent event) async {
  final installationId = event.installation?.id;
  if (installationId == null) {
    throw ArgumentError('No installation ID in webhook event');
  }

  final (:token, :expiresAt) = await getInstallationToken(installationId);
  logInfo('Got installation token', {'expiresAt': expiresAt});

  // TODO: Fetch .openci/ workflows via GraphQL
  // TODO: Parse YAML, match triggers, extract jobs
  // TODO: Create check runs
  // TODO: Write build_jobs to Firestore
}
