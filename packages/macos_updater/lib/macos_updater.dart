import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'src/macos_updater_api.g.dart';

part 'macos_updater.freezed.dart';

enum MacosUpdaterCheckResultType { updateAvailable, noUpdateFound, failed }

@freezed
abstract class MacosUpdaterCheckResult with _$MacosUpdaterCheckResult {
  const factory MacosUpdaterCheckResult({
    required MacosUpdaterCheckResultType type,
    required String message,
    String? version,
    String? displayVersion,
  }) = _MacosUpdaterCheckResult;

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
