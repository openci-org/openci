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

bool get isMacosUpdaterAvailable {
  return !kIsWeb &&
      !kDebugMode &&
      defaultTargetPlatform == TargetPlatform.macOS;
}

Future<void> initializeMacosUpdater() async {
  if (!isMacosUpdaterAvailable) {
    return;
  }

  try {
    await _configureMacosUpdater(MacosUpdater());
  } catch (error, stackTrace) {
    debugPrint('[OpenCI] Failed to initialize macOS updater: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> checkForMacosUpdates() async {
  if (!isMacosUpdaterAvailable) {
    throw UnsupportedError(
      'macOS updater is only available in macOS release builds.',
    );
  }

  final updater = MacosUpdater();
  await _configureMacosUpdater(updater);
  await updater.checkForUpdates();
}

Future<void> _configureMacosUpdater(MacosUpdater updater) async {
  await updater.setFeedUrl(_macosUpdateFeedUrl);
  await updater.setScheduledCheckInterval(
    const Duration(hours: _macosUpdateCheckIntervalHours),
  );
}
