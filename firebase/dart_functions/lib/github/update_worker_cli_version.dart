import 'package:google_cloud_firestore/google_cloud_firestore.dart';

import '../firebase.dart';
import '../util/logger.dart';
import 'webhook_event.dart';

Future<void> updateWorkerCliVersion(WebhookEvent event) async {
  final repoFullName = event.repository?.fullName;
  if (repoFullName != 'open-ci-io/openci') return;

  final assets = event.release?.assets ?? [];
  final hasWorkerAsset = assets.any((a) => a.name.startsWith('openci-worker-'));
  if (!hasWorkerAsset) return;

  final tagName = event.release?.tagName;
  if (tagName == null || tagName.isEmpty) return;

  final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;

  try {
    final now = DateTime.now().toUtc().toIso8601String();

    await firestore.collection('config').doc('workerCli').set({
      'latestVersion': version,
      'updatedAt': now,
      'releaseUrl': event.release?.htmlUrl,
    }, options: const SetOptions.merge());

    logInfo('Updated Worker CLI version', {'version': version});
  } catch (e) {
    logError('Failed to update Worker CLI version', {}, e);
  }
}
