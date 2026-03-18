import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:openci_worker_cli/constants.dart';

final _log = Logger('AutoUpdater');

Future<bool> checkAndUpdate() async {
  try {
    final latestVersion = await _fetchLatestVersion();
    if (latestVersion == null) return false;

    if (latestVersion == version) {
      _log.fine('Already on latest version ($version)');
      return false;
    }

    _log.info('New version available: $version → $latestVersion');
    _log.info('Updating via brew...');

    final updateResult = await Process.run(
      'brew',
      ['upgrade', 'openci-worker'],
    );

    if (updateResult.exitCode != 0) {
      _log.warning(
        'brew upgrade failed: ${updateResult.stderr}',
      );
      return false;
    }

    _log.info('Updated to $latestVersion. Restarting...');
    return true;
  } catch (e) {
    _log.warning('Auto-update check failed: $e');
    return false;
  }
}

Future<String?> _fetchLatestVersion() async {
  final result = await Process.run('curl', [
    '-s',
    '-H',
    'Accept: application/vnd.github.v3+json',
    'https://api.github.com/repos/open-ci-io/openci/releases/latest',
  ]);

  if (result.exitCode != 0) return null;

  final json = jsonDecode(result.stdout as String) as Map<String, dynamic>;
  final tagName = json['tag_name'] as String?;
  if (tagName == null) return null;

  return tagName.startsWith('v') ? tagName.substring(1) : tagName;
}
