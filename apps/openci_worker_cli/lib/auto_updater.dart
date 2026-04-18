import 'dart:io';

import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:openci_worker_cli/constants.dart';

final _log = Logger('AutoUpdater');

/// Staging path where the new binary is downloaded before the supervisor
/// swaps it into place.
const stagedBinaryPath = '/tmp/openci-worker.staged';

/// Checks if a new version is available and stages it for the supervisor.
///
/// Returns `true` if an update is available and the worker should restart
/// (exit with [exitCodeUpdateRequested]).
///
/// Downloads the new binary to [stagedBinaryPath]. The supervisor
/// swaps it into place and restarts the worker.
Future<bool> checkAndUpdate(Firestore firestore) async {
  try {
    final latestVersion = await _fetchLatestVersion(firestore);
    if (latestVersion == null) return false;

    if (latestVersion == version) {
      _log.fine('Already on latest version ($version)');
      return false;
    }

    if (!_isNewerVersion(latestVersion, version)) {
      _log.fine('Remote version ($latestVersion) is not newer than $version');
      return false;
    }

    _log.info('New version available: $version → $latestVersion');
    return _stageBinary(latestVersion);
  } catch (e) {
    _log.warning('Auto-update check failed: $e');
    return false;
  }
}

/// Returns true if [remote] is a newer version than [current].
/// Simple semver comparison (major.minor.patch).
bool _isNewerVersion(String remote, String current) {
  final remoteParts = remote.split('.').map(int.tryParse).toList();
  final currentParts = current.split('.').map(int.tryParse).toList();

  for (var i = 0; i < 3; i++) {
    final r = i < remoteParts.length ? (remoteParts[i] ?? 0) : 0;
    final c = i < currentParts.length ? (currentParts[i] ?? 0) : 0;
    if (r > c) return true;
    if (r < c) return false;
  }
  return false;
}

/// Downloads the new binary to [stagedBinaryPath].
///
/// - macOS: downloads a `.tar.gz` archive and extracts the binary.
/// - Linux: downloads the raw binary directly.
Future<bool> _stageBinary(String latestVersion) async {
  _log.info('Downloading new binary...');

  if (Platform.isMacOS) {
    return _stageMacOSBinary(latestVersion);
  } else {
    return _stageLinuxBinary(latestVersion);
  }
}

Future<bool> _stageMacOSBinary(String latestVersion) async {
  final archiveName = 'openci-worker-v$latestVersion-darwin-arm64.tar.gz';
  final url =
      'https://github.com/open-ci-io/openci/releases/download/'
      'v$latestVersion/$archiveName';
  final archivePath = '/tmp/$archiveName';

  // Download the archive
  final downloadResult = await Process.run('curl', [
    '-fsSL',
    '-o',
    archivePath,
    url,
  ]);

  if (downloadResult.exitCode != 0) {
    _log.warning('Download failed: ${downloadResult.stderr}');
    return false;
  }

  // Extract the binary from the archive
  final extractResult = await Process.run('tar', [
    'xzf',
    archivePath,
    '-C',
    '/tmp',
  ]);

  if (extractResult.exitCode != 0) {
    _log.warning('Extraction failed: ${extractResult.stderr}');
    return false;
  }

  // Move the extracted binary to the staging path
  final mvResult = await Process.run('mv', [
    '/tmp/openci-worker',
    stagedBinaryPath,
  ]);

  if (mvResult.exitCode != 0) {
    _log.warning('Failed to stage binary: ${mvResult.stderr}');
    return false;
  }

  // Clean up the archive
  try {
    File(archivePath).deleteSync();
  } catch (_) {}

  await Process.run('chmod', ['+x', stagedBinaryPath]);
  _log.info('New binary staged at $stagedBinaryPath');
  return true;
}

Future<bool> _stageLinuxBinary(String latestVersion) async {
  final url =
      'https://github.com/open-ci-io/openci/releases/download/'
      'v$latestVersion/openci-worker-v$latestVersion-linux-x64';

  final downloadResult = await Process.run('curl', [
    '-fsSL',
    '-o',
    stagedBinaryPath,
    url,
  ]);

  if (downloadResult.exitCode != 0) {
    _log.warning('Download failed: ${downloadResult.stderr}');
    return false;
  }

  await Process.run('chmod', ['+x', stagedBinaryPath]);
  _log.info('New binary staged at $stagedBinaryPath');
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
