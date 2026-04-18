import 'dart:io';

import 'package:logging/logging.dart';
import 'package:openci_worker_cli/auto_updater.dart';
import 'package:openci_worker_cli/constants.dart';

final _log = Logger('Supervisor');

/// Runs the worker in supervised mode.
///
/// Launches the same binary as a child process (without --supervised) and
/// monitors its exit code:
/// - exit 0: normal shutdown, supervisor exits too.
/// - exit 42: update requested, swap staged binary and restart.
/// - other: crash, wait 10 seconds and restart.
Future<void> runSupervised(List<String> arguments) async {
  final workerArgs = arguments.where((a) => a != '--supervised').toList();

  while (true) {
    _log.info('Starting worker process...');

    final process = await Process.start(
      Platform.resolvedExecutable,
      workerArgs,
      mode: ProcessStartMode.inheritStdio,
    );

    final exitCode = await process.exitCode;

    // Clean up update signal file if it exists
    final signalFile = File(updateSignalFile);
    if (signalFile.existsSync()) {
      try {
        signalFile.deleteSync();
      } catch (_) {}
    }

    switch (exitCode) {
      case 0:
        _log.info('Worker exited normally.');
        return;

      case exitCodeUpdateRequested:
        _log.info('Update requested. Applying update...');
        await _applyUpdate();
        _log.info('Restarting worker...');

      default:
        _log.warning(
          'Worker crashed (exit code $exitCode). Restarting in 10 seconds...',
        );
        await Future<void>.delayed(const Duration(seconds: 10));
    }
  }
}

/// Swaps the staged binary into place, backing up the current binary.
///
/// Both macOS and Linux use the same mechanism:
/// 1. Backup current binary to /tmp for rollback
/// 2. Move staged binary to current path
/// 3. chmod +x
Future<void> _applyUpdate() async {
  final currentPath = Platform.resolvedExecutable;
  final stagedFile = File(stagedBinaryPath);

  if (!stagedFile.existsSync()) {
    _log.warning('No staged binary found at $stagedBinaryPath');
    return;
  }

  // Backup current binary to /tmp for rollback
  const backupPath = '/tmp/openci-worker.prev';
  final backupResult = await Process.run('cp', [currentPath, backupPath]);
  if (backupResult.exitCode != 0) {
    _log.warning('Failed to backup current binary: ${backupResult.stderr}');
    // Continue anyway — update is more important than backup
  } else {
    _log.info('Current binary backed up to $backupPath');
  }

  // Replace with staged binary
  final mvResult = await Process.run('mv', [stagedBinaryPath, currentPath]);
  if (mvResult.exitCode != 0) {
    _log.warning('Failed to replace binary: ${mvResult.stderr}');
    return;
  }

  await Process.run('chmod', ['+x', currentPath]);
  _log.info('Binary updated successfully.');
}
