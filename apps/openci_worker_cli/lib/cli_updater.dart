import 'dart:io';

import 'package:dart_firebase_admin/firestore.dart';
import 'package:logging/logging.dart';
import 'package:openci_shared/firestore_paths.dart';
import 'package:openci_worker_cli/constants.dart';
import 'package:process_run/process_run.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('CLIUpdater');

DateTime _lastCheck = DateTime.now();
const _interval = Duration(minutes: 5);

Future<void> checkForCLIUpdateIfNeeded(Firestore firestore) async {
  if (DateTime.now().difference(_lastCheck) < _interval) return;
  _lastCheck = DateTime.now();

  try {
    final shouldRestart = await _checkForCLIUpdate(firestore);
    if (shouldRestart) {
      _log.info('Update complete. Restarting worker...');
      exit(0);
    }
  } catch (e) {
    _log.warning('Update check failed: $e');
  }
}

Future<bool> _checkForCLIUpdate(Firestore firestore) async {
  final configDoc = await firestore
      .collection(workerConfigCollection)
      .doc('latest_version')
      .get();

  if (!configDoc.exists) return false;

  final data = configDoc.data();
  if (data == null) return false;

  final latestVersion = data['version'] as String?;
  if (latestVersion == null || latestVersion == version) return false;

  _log.info('New version available: $version → $latestVersion');

  try {
    final shell = Shell(verbose: true, throwOnError: false);
    await shell.run('brew update');
    final result = await shell.run('brew upgrade openci-worker');
    final output = result.first.stdout?.toString() ?? '';

    if (output.contains('already installed')) {
      _log.info('Already on latest brew version. Skipping restart.');
      return false;
    }

    return true;
  } catch (e, s) {
    _log.warning('Auto-update failed: $e');
    await Sentry.captureException(e, stackTrace: s);
    return false;
  }
}
