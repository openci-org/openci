import 'dart:async';
import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';

import '../../i18n/i18n.dart';
import 'setup_orchard_context.dart';

typedef OrchardWorkerProcessStarter =
    Future<Process> Function(
      String executable,
      List<String> arguments, {
      required ProcessStartMode mode,
    });

/// Starts the Mac worker. The caller must [OrchardWorker.stop] it when done.
Future<OrchardWorker?> startOrchardWorker(
  Logger logger, {
  @visibleForTesting OrchardProcessRunner processRunner = Process.run,
  @visibleForTesting OrchardWorkerProcessStarter processStarter = Process.start,
  @visibleForTesting Stream<ProcessSignal>? interruptSignals,
  @visibleForTesting Stream<ProcessSignal>? terminateSignals,
}) async {
  try {
    final tokenResult = await processRunner('orchard', [
      'get',
      'bootstrap-token',
      'bootstrap-admin',
    ]);
    final token = tokenResult.stdout.toString().trim();
    if (tokenResult.exitCode != 0 || token.isEmpty) {
      logger.stderr(t.dev.start.stepOrchardWorkerFailed);
      return null;
    }

    logger.stdout('\n${t.dev.start.stepOrchardWorker}');
    final process = await processStarter('orchard', [
      'worker',
      'run',
      'https://127.0.0.1:6120',
      '--bootstrap-token',
      token,
      '--no-pki',
    ], mode: ProcessStartMode.inheritStdio);

    return OrchardWorker._(
      process,
      logger,
      interruptSignals ?? ProcessSignal.sigint.watch(),
      terminateSignals ?? ProcessSignal.sigterm.watch(),
    );
  } on ProcessException catch (error) {
    logger.stderr('${t.dev.start.stepOrchardWorkerFailed}\n${error.message}');
    return null;
  }
}

class OrchardWorker {
  final Process _process;
  var _exited = false;
  var _stopRequested = false;
  ProcessSignal? _stopSignal;
  late final Future<int> exitCode;

  OrchardWorker._(
    this._process,
    Logger logger,
    Stream<ProcessSignal> interruptSignals,
    Stream<ProcessSignal> terminateSignals,
  ) {
    final subscriptions = [
      interruptSignals.listen(_handleSignal),
      terminateSignals.listen(_handleSignal),
    ];
    exitCode = _waitForExit(logger, subscriptions);
  }

  bool get isRunning => !_exited && !_stopRequested;

  Future<void> stop() async {
    if (isRunning) {
      _stopRequested = true;
      // Orchard handles SIGINT by shutting down its worker.
      _process.kill(ProcessSignal.sigint);
    }
    await exitCode;
  }

  void _handleSignal(ProcessSignal signal) {
    _stopSignal ??= signal;
    _stopRequested = true;
    _process.kill(ProcessSignal.sigint);
  }

  Future<int> _waitForExit(
    Logger logger,
    List<StreamSubscription<ProcessSignal>> subscriptions,
  ) async {
    try {
      final code = await _process.exitCode;
      if (_stopSignal != null) {
        return 128 + _stopSignal!.signalNumber;
      }
      if (code != 0 && !_stopRequested) {
        logger.stderr(t.dev.start.stepOrchardWorkerFailed);
      }
      return code < 0 ? 128 - code : code;
    } finally {
      _exited = true;
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    }
  }
}
