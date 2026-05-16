import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/macos_updater_api.g.dart';

enum MacosUpdaterCheckResultType { updateAvailable, noUpdateFound, failed }

@immutable
class MacosUpdaterCheckResult {
  const MacosUpdaterCheckResult({
    required this.type,
    required this.message,
    this.version,
    this.displayVersion,
  });

  factory MacosUpdaterCheckResult.fromMap(Map<Object?, Object?> map) {
    return MacosUpdaterCheckResult(
      type: switch (map['type']) {
        'updateAvailable' => MacosUpdaterCheckResultType.updateAvailable,
        'noUpdateFound' => MacosUpdaterCheckResultType.noUpdateFound,
        'failed' => MacosUpdaterCheckResultType.failed,
        _ => MacosUpdaterCheckResultType.failed,
      },
      message: map['message'] as String? ?? '',
      version: map['version'] as String?,
      displayVersion: map['displayVersion'] as String?,
    );
  }

  final MacosUpdaterCheckResultType type;
  final String message;
  final String? version;
  final String? displayVersion;
}

/// A macOS-only Sparkle updater facade.
class MacosUpdater {
  MacosUpdater({@visibleForTesting MacosUpdaterHostApi? api})
    : _api = api ?? MacosUpdaterHostApi();

  static const _eventChannel = EventChannel('macos_updater/events');
  static Stream<MacosUpdaterCheckResult>? _checkResults;

  final MacosUpdaterHostApi _api;

  Stream<MacosUpdaterCheckResult> get checkResults {
    return _checkResults ??= _eventChannel.receiveBroadcastStream().map(
      (event) => MacosUpdaterCheckResult.fromMap(
        Map<Object?, Object?>.from(event as Map<Object?, Object?>),
      ),
    );
  }

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
