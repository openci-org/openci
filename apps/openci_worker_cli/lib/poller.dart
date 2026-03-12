import 'dart:io';

import 'package:dart_firebase_admin/firestore.dart';
import 'package:openci_worker_cli/cli_updater.dart';
import 'package:openci_worker_cli/job_executor.dart';
import 'package:sentry/sentry.dart';

const _spinnerChars = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
const _pollInterval = 10;

Future<void> pollForJobs({
  required Firestore firestore,
  required String workerId,
  required String projectId,
  required String serviceAccountPath,
}) async {
  print('Polling for jobs...');
  var spinnerIndex = 0;
  var waitingStartTime = DateTime.now();
  var pollCounter = 0;

  while (true) {
    var jobFound = false;

    if (pollCounter == 0) {
      try {
        jobFound = await processJob(
          firestore,
          projectId,
          serviceAccountPath,
          workerId,
        );
      } catch (e, s) {
        print('\nError processing job: $e');
        await Sentry.captureException(e, stackTrace: s);
      }

      try {
        final shouldRestart = await checkForCLIUpdate(firestore);
        if (shouldRestart) {
          print('\n🔄 Update complete. Restarting worker...');
          exit(0);
        }
      } catch (e) {
        print('\n[WARN] Update check failed: $e');
      }
    }

    if (!jobFound) {
      final elapsed = DateTime.now().difference(waitingStartTime);
      final minutes = elapsed.inMinutes;
      final seconds = elapsed.inSeconds % 60;
      final timeStr = '${minutes}m ${seconds}s';
      stdout.write(
        '\r${_spinnerChars[spinnerIndex]} [$workerId] Waiting for jobs... ($timeStr)  ',
      );
      spinnerIndex = (spinnerIndex + 1) % _spinnerChars.length;
      pollCounter = (pollCounter + 1) % _pollInterval;
      await Future.delayed(const Duration(milliseconds: 100));
    } else {
      print('');
      waitingStartTime = DateTime.now();
      pollCounter = 0;
    }
  }
}
