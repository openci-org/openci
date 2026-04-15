import '../util/logger.dart';
import 'webhook_event.dart';

Future<void> updateWorkerCliVersion(WebhookEvent event) async {
  final repoFullName = event.repository?.fullName;
  if (repoFullName != 'open-ci-io/openci') return;

  final assets = event.release?.assets ?? [];
  final hasWorkerAsset = assets.any(
    (a) => a.name.startsWith('openci-worker-'),
  );
  if (!hasWorkerAsset) return;

  final tagName = event.release?.tagName;
  if (tagName == null || tagName.isEmpty) return;

  final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;

  // TODO: Write to Firestore config/workerCli
  logInfo('TODO: Update Worker CLI version', {'version': version});
}
