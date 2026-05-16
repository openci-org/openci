import 'package:flutter/foundation.dart';

import 'src/macos_updater_api.g.dart';

/// A macOS-only Sparkle updater facade.
class MacosUpdater {
  MacosUpdater({@visibleForTesting MacosUpdaterHostApi? api})
    : _api = api ?? MacosUpdaterHostApi();

  final MacosUpdaterHostApi _api;

  Future<void> setFeedUrl(String url) {
    return _api.setFeedUrl(url);
  }

  Future<void> checkForUpdates() {
    return _api.checkForUpdates();
  }

  Future<void> setScheduledCheckInterval(Duration interval) {
    return _api.setScheduledCheckInterval(interval.inSeconds);
  }
}
