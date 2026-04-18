import 'dart:async';
import 'dart:io';

import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:openci_worker_cli/auto_updater.dart';
import 'package:openci_worker_cli/constants.dart';
import 'package:openci_worker_cli/docker_job_executor.dart';
import 'package:openci_worker_cli/job_executor.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('Poller');

const _spinnerFrames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

const _updateCheckInterval = Duration(minutes: 1);

Future<void> pollForJobs({
  required Firestore firestore,
  required String workerId,
  required String projectId,
  required String serviceAccountPath,
}) async {
  _log.info('Starting job poller...');

  Timer? spinnerTimer;
  var spinnerIndex = 0;
  var lastUpdateCheck = DateTime.now();

  void startSpinner() {
    spinnerTimer?.cancel();
    spinnerTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final now = DateTime.now();
      final time =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      final frame = _spinnerFrames[spinnerIndex % _spinnerFrames.length];
      stderr.write('\r$time $frame [Poller] Waiting for jobs...  ');
      spinnerIndex++;
    });
  }

  void stopSpinner() {
    if (spinnerTimer != null) {
      spinnerTimer!.cancel();
      spinnerTimer = null;
      stderr.writeln('');
    }
  }

  Future<void> tryAutoUpdate() async {
    lastUpdateCheck = DateTime.now();
    final updated = await checkAndUpdate(firestore);
    if (updated) {
      _log.info('Update staged. Exiting for restart...');

      // Signal other workers to update too
      try {
        File(updateSignalFile).createSync();
      } catch (_) {}

      exit(exitCodeUpdateRequested);
    }
  }

  void checkUpdateSignal() {
    try {
      if (File(updateSignalFile).existsSync()) {
        _log.info('Update signal detected from another worker.');
        exit(exitCodeUpdateRequested);
      }
    } catch (_) {}
  }

  while (true) {
    try {
      final bool jobFound;
      if (Platform.isLinux) {
        jobFound = await processDockerJob(
          firestore,
          projectId,
          serviceAccountPath,
          workerId,
          onJobFound: stopSpinner,
        );
      } else {
        jobFound = await processJob(
          firestore,
          projectId,
          serviceAccountPath,
          workerId,
          onJobFound: stopSpinner,
        );
      }

      if (jobFound) {
        _log.info('Job completed, checking for next...');
        await tryAutoUpdate();
      } else {
        // Check if another worker has signalled an update
        checkUpdateSignal();

        final now = DateTime.now();
        if (now.difference(lastUpdateCheck) >= _updateCheckInterval) {
          stopSpinner();
          await tryAutoUpdate();
        }
        if (spinnerTimer == null) startSpinner();
        await Future.delayed(const Duration(seconds: 10));
      }
    } catch (e, s) {
      stopSpinner();
      _log.severe('Error in poll loop: $e');
      await Sentry.captureException(e, stackTrace: s);
      await Future.delayed(const Duration(seconds: 10));
    }
  }
}
