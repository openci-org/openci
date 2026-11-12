import 'package:flutter/foundation.dart';
import 'package:macos_updater/macos_updater.dart';

String? get _macosUpdateFeedUrl {
  const customFeedUrl = String.fromEnvironment('OPENCI_MACOS_UPDATE_FEED_URL');
  if (customFeedUrl.isNotEmpty) {
    return customFeedUrl;
  }
  return null;
}

const _macosUpdateCheckIntervalHours = int.fromEnvironment(
  'OPENCI_MACOS_UPDATE_CHECK_INTERVAL_HOURS',
  defaultValue: 24,
);

bool get isMacosUpdaterAvailable {
  return isMacosUpdaterSupportedPlatform && !kDebugMode;
}

bool get isMacosUpdaterSupportedPlatform {
  return !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
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

Future<MacosUpdaterCheckResult> checkForMacosUpdates() async {
  if (!isMacosUpdaterSupportedPlatform) {
    throw UnsupportedError(
      'macOS updater is only available on macOS.',
    );
  }

  final updater = MacosUpdater();
  await _configureMacosUpdater(updater);
  final result = updater.checkResults.first.timeout(
    const Duration(seconds: 45),
    onTimeout: () => const MacosUpdaterCheckResult(
      type: MacosUpdaterCheckResultType.failed,
      message: 'Sparkle did not report an update check result.',
    ),
  );
  await updater.checkForUpdates();
  return result;
}

Future<void> _configureMacosUpdater(MacosUpdater updater) async {
  final override = _macosUpdateFeedUrl;
  if (override != null) {
    await updater.setFeedUrl(override);
  }
  await updater.setScheduledCheckInterval(
    const Duration(hours: _macosUpdateCheckIntervalHours),
  );
  await updater.start();
}
