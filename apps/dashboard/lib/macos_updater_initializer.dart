import 'package:flutter/foundation.dart';
import 'package:macos_updater/macos_updater.dart';

const _macosUpdateFeedUrl = String.fromEnvironment(
  'OPENCI_MACOS_UPDATE_FEED_URL',
  defaultValue:
      'https://firebasestorage.googleapis.com/v0/b/openci-b1b91.firebasestorage.app/o/artifacts%2Fopenci-dashboard%2Fmacos%2Fdevelop%2Flatest%2Fappcast.xml?alt=media&token=adfb1bbd-98ac-4d7d-8bfe-df57403ce6b0',
);

const _macosUpdateCheckIntervalHours = int.fromEnvironment(
  'OPENCI_MACOS_UPDATE_CHECK_INTERVAL_HOURS',
  defaultValue: 24,
);

Future<void> initializeMacosUpdater() async {
  if (kIsWeb || kDebugMode || defaultTargetPlatform != TargetPlatform.macOS) {
    return;
  }

  try {
    final updater = MacosUpdater();
    await updater.setFeedUrl(_macosUpdateFeedUrl);
    await updater.setScheduledCheckInterval(
      const Duration(hours: _macosUpdateCheckIntervalHours),
    );
  } catch (error, stackTrace) {
    debugPrint('[OpenCI] Failed to initialize macOS updater: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
