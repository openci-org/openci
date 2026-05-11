import 'dart:async';
import 'dart:convert';

import 'package:dashboard/build_info.dart';
import 'package:dashboard/update/update_check_models.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'update_check_provider.g.dart';

const _versionJsonPath = '/version.json';
const _updateCheckInterval = Duration(minutes: 5);
const _updateCheckTimeout = Duration(seconds: 10);

@Riverpod(keepAlive: true)
class UpdateCheck extends _$UpdateCheck {
  Timer? _timer;

  @override
  UpdateCheckState build() {
    if (!kIsWeb || !BuildInfo.hasBuildIdentity) {
      return const UpdateCheckState();
    }

    _timer = Timer.periodic(
      _updateCheckInterval,
      (_) => unawaited(checkForUpdate()),
    );
    ref.onDispose(() => _timer?.cancel());

    unawaited(Future<void>.microtask(checkForUpdate));
    return const UpdateCheckState();
  }

  Future<void> checkForUpdate() async {
    if (!kIsWeb || !BuildInfo.hasBuildIdentity) {
      return;
    }

    try {
      final uri = Uri.base
          .resolve(_versionJsonPath)
          .replace(
            queryParameters: {
              '_': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          );
      final response = await http
          .get(
            uri,
            headers: const {
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
            },
          )
          .timeout(_updateCheckTimeout);

      if (response.statusCode != 200) {
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return;
      }

      final latest = LatestBuildInfo.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      final isUpdateAvailable = _isNewerBuild(latest);
      state = state.copyWith(
        latest: latest,
        isUpdateAvailable: isUpdateAvailable,
      );
    } catch (_) {
      rethrow;
    }
  }

  bool _isNewerBuild(LatestBuildInfo latest) {
    final currentSha = BuildInfo.sha.trim();
    final latestSha = latest.sha.trim();
    if (currentSha.isNotEmpty && latestSha.isNotEmpty) {
      return currentSha != latestSha;
    }

    final currentUpdatedAt = BuildInfo.updatedAtUtc;
    final latestUpdatedAt = latest.updatedAt;
    if (currentUpdatedAt != null && latestUpdatedAt != null) {
      return latestUpdatedAt.isAfter(currentUpdatedAt);
    }

    return false;
  }
}
