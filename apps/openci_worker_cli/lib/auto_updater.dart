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

    if (Platform.isLinux) {
      return _updateLinux(latestVersion);
    } else {
      return _updateMacOS(latestVersion);
    }
  } catch (e) {
    _log.warning('Auto-update check failed: $e');
    return false;
  }
}

Future<bool> _updateMacOS(String latestVersion) async {
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
}

Future<bool> _updateLinux(String latestVersion) async {
  _log.info('Updating via GitHub Release...');

  const binaryPath = '/usr/local/bin/openci-worker';
  final url = 'https://github.com/open-ci-io/openci/releases/download/'
      'v$latestVersion/openci-worker-v$latestVersion-linux-x64';

  final downloadResult = await Process.run('curl', [
    '-fsSL',
    '-o',
    '$binaryPath.tmp',
    url,
  ]);

  if (downloadResult.exitCode != 0) {
    _log.warning('Download failed: ${downloadResult.stderr}');
    return false;
  }

  // Replace the current binary atomically
  await Process.run('chmod', ['+x', '$binaryPath.tmp']);
  final mvResult = await Process.run('mv', ['$binaryPath.tmp', binaryPath]);
  if (mvResult.exitCode != 0) {
    _log.warning('Failed to replace binary: ${mvResult.stderr}');
    return false;
  }

  _log.info('Updated to $latestVersion. Restarting...');
  return true;
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
