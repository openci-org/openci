import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:openci_worker_cli/constants.dart';

final _log = Logger('AutoUpdater');

/// Checks if a new version is available on pub.dev and installs it.
///
/// Returns `true` if an update was installed and the worker should restart
/// (exit with [exitCodeUpdateRequested]).
///
/// Uses `dart pub global activate` to install the new version.
/// The supervisor will restart the worker process automatically.
Future<bool> checkAndUpdate() async {
  try {
    final latestVersion = await _fetchLatestVersion();
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
    return await _installUpdate(latestVersion);
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

/// Installs the specified version via `dart pub global activate`.
Future<bool> _installUpdate(String latestVersion) async {
  _log.info('Installing update via dart install...');

  try {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null) {
      String? binaryPath;
      if (Platform.isMacOS) {
        binaryPath = '$home/Library/Application Support/Dart/install/bin/openci_worker';
      } else if (Platform.isLinux) {
        final xdgStateHome = Platform.environment['XDG_STATE_HOME'];
        final statePath = (xdgStateHome != null && xdgStateHome.isNotEmpty)
            ? '$xdgStateHome/Dart/install/bin/openci_worker'
            : '$home/.local/state/Dart/install/bin/openci_worker';

        final xdgDataHome = Platform.environment['XDG_DATA_HOME'];
        final sharePath = (xdgDataHome != null && xdgDataHome.isNotEmpty)
            ? '$xdgDataHome/Dart/install/bin/openci_worker'
            : '$home/.local/share/Dart/install/bin/openci_worker';

        if (FileSystemEntity.typeSync(statePath) != FileSystemEntityType.notFound) {
          binaryPath = statePath;
        } else if (FileSystemEntity.typeSync(sharePath) != FileSystemEntityType.notFound) {
          binaryPath = sharePath;
        } else {
          binaryPath = statePath;
        }
      }

      if (binaryPath != null) {
        final fileType = FileSystemEntity.typeSync(binaryPath);
        if (fileType != FileSystemEntityType.notFound) {
          _log.info('Deleting existing link/binary at $binaryPath to avoid PathExistsException');
          if (fileType == FileSystemEntityType.link) {
            Link(binaryPath).deleteSync();
          } else {
            File(binaryPath).deleteSync();
          }
        }
      }
    }
  } catch (e) {
    _log.warning('Failed to pre-delete existing link/binary: $e');
  }

  final result = await Process.run('dart', [
    'install',
    'openci_worker_cli',
    latestVersion,
    '--overwrite',
  ]);

  if (result.exitCode != 0) {
    _log.warning('Update failed: ${result.stderr}');
    return false;
  }

  _log.info('Successfully installed openci_worker_cli $latestVersion');
  return true;
}

/// Fetches the latest version from pub.dev API.
Future<String?> _fetchLatestVersion() async {
  final response = await http.get(
    Uri.parse('https://pub.dev/api/packages/openci_worker_cli'),
  );

  if (response.statusCode != 200) {
    _log.warning(
      'Failed to fetch version from pub.dev: ${response.statusCode}',
    );
    return null;
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final latest = data['latest'] as Map<String, dynamic>?;
  if (latest == null) return null;

  return latest['version'] as String?;
}
