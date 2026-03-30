import 'dart:io';

import 'package:dart_firebase_admin/firestore.dart';
import 'package:logging/logging.dart';
import 'package:openci_worker_cli/constants.dart';

final _log = Logger('AutoUpdater');

Future<bool> checkAndUpdate(Firestore firestore) async {
  try {
    final latestVersion = await _fetchLatestVersion(firestore);
    if (latestVersion == null) return false;

    if (latestVersion == version) {
      _log.fine('Already on latest version ($version)');
      return false;
    }

    _log.info('New version available: $version → $latestVersion');
    _log.info('Updating via brew...');

    // Must run `brew update` first to fetch the latest tap info,
    // otherwise `brew upgrade` won't know about the new version.
    final updateTapResult = await Process.run('brew', ['update']);
    if (updateTapResult.exitCode != 0) {
      _log.warning('brew update failed: ${updateTapResult.stderr}');
      return false;
    }

    final upgradeResult = await Process.run(
      'brew',
      ['upgrade', 'openci-worker'],
    );

    if (upgradeResult.exitCode != 0) {
      _log.warning('brew upgrade failed: ${upgradeResult.stderr}');
      return false;
    }

    // Verify the upgrade actually installed the new version.
    // `brew upgrade` returns exit code 0 even if "already installed".
    final infoResult = await Process.run(
      'brew',
      ['info', '--json=v2', 'openci-worker'],
    );

    if (infoResult.exitCode == 0) {
      final output = infoResult.stdout as String;
      if (!output.contains(latestVersion)) {
        _log.warning(
          'brew upgrade succeeded but version $latestVersion not found. '
          'Skipping restart.',
        );
        return false;
      }
    }

    _log.info('Updated to $latestVersion. Restarting...');
    return true;
  } catch (e) {
    _log.warning('Auto-update check failed: $e');
    return false;
  }
}

Future<String?> _fetchLatestVersion(Firestore firestore) async {
  final doc = await firestore.collection('config').doc('workerCli').get();
  if (!doc.exists) {
    _log.fine('config/workerCli document not found');
    return null;
  }

  final data = doc.data();
  if (data == null) return null;

  return data['latestVersion'] as String?;
}
