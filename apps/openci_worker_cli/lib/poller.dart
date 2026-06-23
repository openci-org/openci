import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:openci_worker_cli/auto_updater.dart';
import 'package:openci_worker_cli/cloud_function_caller.dart';
import 'package:openci_worker_cli/constants.dart';
import 'package:openci_worker_cli/docker_job_executor.dart';
import 'package:openci_worker_cli/heartbeat.dart';
import 'package:openci_worker_cli/job_executor.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('Poller');

const _spinnerFrames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

const _updateCheckInterval = Duration(minutes: 1);
const _heartbeatInterval = Duration(seconds: 30);

class WorkerState {
  String status = 'starting';
}

Future<void> _sendHeartbeat(
  ApiClient apiClient,
  String workerId,
  WorkerState state,
) async {
  try {
    await sendHeartbeat(
      apiClient: apiClient,
      workerId: workerId,
      version: version,
      status: state.status,
    );
  } catch (e) {
    _log.warning('Failed to update worker heartbeat: $e');
  }
}

Future<void> pollForJobs({
  required ApiClient apiClient,
  required String workerId,
}) async {
  _log.info('Starting job poller...');

  final state = WorkerState();

  // Send initial heartbeat
  await _sendHeartbeat(apiClient, workerId, state);

  // Set up periodic heartbeat timer
  final heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
    _sendHeartbeat(apiClient, workerId, state);
  });

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
    final updated = await checkAndUpdate();
    if (updated) {
      _log.info('Update installed. Exiting for restart...');
      state.status = 'stopping';
      await _sendHeartbeat(apiClient, workerId, state);
      heartbeatTimer.cancel();
      exit(exitCodeUpdateRequested);
    }
  }

  state.status = 'idle';
  await _sendHeartbeat(apiClient, workerId, state);

  try {
    while (true) {
      try {
        final bool jobFound;
        if (Platform.isLinux) {
          jobFound = await processDockerJob(
            apiClient,
            workerId,
            onJobFound: () {
              stopSpinner();
              state.status = 'busy';
              _sendHeartbeat(apiClient, workerId, state);
            },
          );
        } else {
          jobFound = await processJob(
            apiClient,
            workerId,
            onJobFound: () {
              stopSpinner();
              state.status = 'busy';
              _sendHeartbeat(apiClient, workerId, state);
            },
          );
        }

        if (jobFound) {
          _log.info('Job completed, checking for next...');
          state.status = 'idle';
          await _sendHeartbeat(apiClient, workerId, state);
          await tryAutoUpdate();
        } else {
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
        state.status = 'error';
        await _sendHeartbeat(apiClient, workerId, state);
        await Sentry.captureException(e, stackTrace: s);
        await Future.delayed(const Duration(seconds: 10));
      }
    }
  } finally {
    heartbeatTimer.cancel();
    state.status = 'stopping';
    await _sendHeartbeat(apiClient, workerId, state);
  }
}
