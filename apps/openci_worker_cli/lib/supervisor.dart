import 'dart:io';

import 'package:logging/logging.dart';
import 'package:openci_worker_cli/constants.dart';

final _log = Logger('Supervisor');

/// Runs the worker in supervised mode.
///
/// Launches the same binary as a child process (without --supervised) and
/// monitors its exit code:
/// - exit 0: normal shutdown, supervisor exits too.
/// - exit 42: update requested, restart the worker.
/// - other: crash, wait 10 seconds and restart.
///
/// With pub.dev-based updates, `dart pub global activate` is already
/// executed by the auto_updater before exiting with code 42.
/// The supervisor only needs to restart the process.
Future<void> runSupervised(List<String> arguments) async {
  final workerArgs = arguments.where((a) => a != '--supervised').toList();

  // Detect if running via pub global (Platform.resolvedExecutable points to
  // the dart binary, not a compiled AOT executable).
  final resolvedExe = Platform.resolvedExecutable;
  final isRunningViaPubGlobal = resolvedExe.endsWith('/dart') ||
      resolvedExe.endsWith(r'\dart.exe');

  while (true) {
    _log.info('Starting worker process...');

    final String executable;
    final List<String> processArgs;

    if (isRunningViaPubGlobal) {
      // Use `dart pub global run` to re-enter through the package entrypoint.
      executable = resolvedExe;
      processArgs = [
        'pub',
        'global',
        'run',
        'openci_worker_cli',
        ...workerArgs,
      ];
    } else {
      // AOT-compiled binary: just re-run self.
      executable = resolvedExe;
      processArgs = workerArgs;
    }

    final process = await Process.start(
      executable,
      processArgs,
      mode: ProcessStartMode.inheritStdio,
    );

    final exitCode = await process.exitCode;

    switch (exitCode) {
      case 0:
        _log.info('Worker exited normally.');
        return;

      case exitCodeUpdateRequested:
        _log.info('Update installed. Restarting worker...');

      default:
        _log.warning(
          'Worker crashed (exit code $exitCode). Restarting in 10 seconds...',
        );
        await Future<void>.delayed(const Duration(seconds: 10));
    }
  }
}
