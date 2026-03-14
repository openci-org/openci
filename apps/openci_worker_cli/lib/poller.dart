import 'dart:async';
import 'dart:io';

import 'package:dart_firebase_admin/firestore.dart';
import 'package:logging/logging.dart';
import 'package:openci_worker_cli/job_executor.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('Poller');

const _spinnerFrames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

Future<void> pollForJobs({
  required Firestore firestore,
  required String workerId,
  required String projectId,
  required String serviceAccountPath,
}) async {
  _log.info('Starting job poller...');

  Timer? spinnerTimer;
  var spinnerIndex = 0;

  void startSpinner() {
    spinnerTimer?.cancel();
    spinnerTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        final now = DateTime.now();
        final time =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        final frame = _spinnerFrames[spinnerIndex % _spinnerFrames.length];
        stderr.write('\r$time $frame [Poller] Waiting for jobs...  ');
        spinnerIndex++;
      },
    );
  }

  void stopSpinner() {
    if (spinnerTimer != null) {
      spinnerTimer!.cancel();
      spinnerTimer = null;
      stderr.writeln('');
    }
  }

  while (true) {
    try {
      final jobFound = await processJob(
        firestore,
        projectId,
        serviceAccountPath,
        workerId,
        onJobFound: stopSpinner,
      );

      if (jobFound) {
        _log.info('Job completed, checking for next...');
      } else {
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

