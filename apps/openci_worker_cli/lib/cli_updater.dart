import 'package:dart_firebase_admin/firestore.dart';
import 'package:openci_worker_cli/constants.dart';
import 'package:process_run/process_run.dart';
import 'package:sentry/sentry.dart';

Future<bool> checkForCLIUpdate(Firestore firestore) async {
  final configDoc = await firestore
      .collection('worker_config_v0')
      .doc('latest_version')
      .get();

  if (!configDoc.exists) return false;

  final data = configDoc.data();
  if (data == null) return false;

  final latestVersion = data['version'] as String?;
  if (latestVersion == null || latestVersion == version) return false;

  print('\n📦 New version available: $version → $latestVersion');
  print('Updating...');

  try {
    final shell = Shell(verbose: true, throwOnError: false);
    await shell.run('brew update');
    final result = await shell.run('brew upgrade openci-worker');
    final output = result.first.stdout?.toString() ?? '';

    if (output.contains('already installed')) {
      print('[INFO] Already on latest brew version. Skipping restart.');
      return false;
    }

    return true;
  } catch (e, s) {
    print('[WARN] Auto-update failed: $e');
    await Sentry.captureException(e, stackTrace: s);
    return false;
  }
}
