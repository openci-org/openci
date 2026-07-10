import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:openci_worker_cli/constants.dart';
import 'package:sentry/sentry.dart';

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
typedef ProcessStarter =
    Future<Process> Function(
      String executable,
      List<String> arguments, {
      String? workingDirectory,
      Map<String, String>? environment,
      bool includeParentEnvironment,
      bool runInShell,
      ProcessStartMode mode,
    });

Future<void> runSupervised(
  List<String> arguments, {
  ProcessStarter processStart = Process.start,
  Duration crashRestartDelay = const Duration(seconds: 10),
}) async {
  final workerArgs = arguments.where((a) => a != '--supervised').toList();

  // Detect if running via pub global (Platform.resolvedExecutable points to
  // the dart binary, not a compiled AOT executable).
  final resolvedExe = Platform.resolvedExecutable;
  final isRunningViaPubGlobal =
      resolvedExe.endsWith('/dart') || resolvedExe.endsWith(r'\dart.exe');

  while (true) {
    _log.info('Starting worker process...');

    final String executable;
    final List<String> processArgs;

    final installedAot = _findInstalledAotBinary();
    if (installedAot != null) {
      _log.info('Found installed AOT binary: $installedAot');
      executable = installedAot;
      processArgs = workerArgs;
    } else if (isRunningViaPubGlobal) {
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

    final Process process;
    try {
      process = await processStart(
        executable,
        processArgs,
        mode: ProcessStartMode.inheritStdio,
      );
    } on ProcessException catch (e, s) {
      _log.severe('Failed to start worker process: $e');
      await Sentry.captureException(e, stackTrace: s);
      _log.warning('Restarting in ${crashRestartDelay.inSeconds} seconds...');
      await Future<void>.delayed(crashRestartDelay);
      continue;
    }

    // Forward system signals (SIGTERM / SIGINT) to child process to ensure graceful shutdown
    // and prevent child process from becoming a zombie when supervisor is terminated.
    StreamSubscription? sigtermSub;
    StreamSubscription? sigintSub;
    if (!Platform.isWindows) {
      sigtermSub = ProcessSignal.sigterm.watch().listen((sig) {
        _log.info(
          'Supervisor received SIGTERM. Forwarding to child process...',
        );
        process.kill(ProcessSignal.sigterm);
      });
      sigintSub = ProcessSignal.sigint.watch().listen((sig) {
        _log.info('Supervisor received SIGINT. Forwarding to child process...');
        process.kill(ProcessSignal.sigint);
      });
    }

    final exitCode = await process.exitCode;
    await sigtermSub?.cancel();
    await sigintSub?.cancel();

    switch (exitCode) {
      case 0:
        _log.info('Worker exited normally.');
        return;

      case exitCodeUpdateRequested:
        _log.info('Update installed. Restarting worker...');

      default:
        _log.warning(
          'Worker crashed (exit code $exitCode). Restarting in ${crashRestartDelay.inSeconds} seconds...',
        );
        await Future<void>.delayed(crashRestartDelay);
    }
  }
}

/// Locates the AOT-compiled binary installed via `dart install`.
String? _findInstalledAotBinary() {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null) return null;

  if (Platform.isMacOS) {
    final path =
        '$home/Library/Application Support/Dart/install/bin/openci_worker';
    if (File(path).existsSync()) return path;
  } else if (Platform.isLinux) {
    final xdgStateHome = Platform.environment['XDG_STATE_HOME'];
    final statePath = (xdgStateHome != null && xdgStateHome.isNotEmpty)
        ? '$xdgStateHome/Dart/install/bin/openci_worker'
        : '$home/.local/state/Dart/install/bin/openci_worker';
    if (File(statePath).existsSync()) return statePath;

    final xdgDataHome = Platform.environment['XDG_DATA_HOME'];
    final sharePath = (xdgDataHome != null && xdgDataHome.isNotEmpty)
        ? '$xdgDataHome/Dart/install/bin/openci_worker'
        : '$home/.local/share/Dart/install/bin/openci_worker';
    if (File(sharePath).existsSync()) return sharePath;
  } else if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'];
    if (appData != null) {
      final path = '$appData\\Dart\\install\\bin\\openci_worker.exe';
      if (File(path).existsSync()) return path;
    }
  }
  return null;
}
