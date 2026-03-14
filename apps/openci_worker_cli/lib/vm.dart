import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_firebase_admin/firestore.dart';
import 'package:logging/logging.dart';
import 'package:openci_worker_cli/constants.dart';
import 'package:openci_worker_cli/logger.dart';
import 'package:process_run/process_run.dart';
import 'package:process_run/stdio.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('VM');

Future<void> cloneVm({
  required String baseVmName,
  required String vmName,
  required String buildJobId,
  required String runId,
  required Firestore firestore,
}) async {
  await logInfo(
    firestore,
    buildJobId,
    runId,
    'Cloning VM $baseVmName to $vmName...',
  );
  var shell = Shell();
  await shell.run('lume clone $baseVmName $vmName');
}

String currentVmName({required String workerId, required String buildJobId}) {
  final shortId = buildJobId.length >= 8 ? buildJobId.substring(0, 8) : buildJobId;
  return 'openci-vm-$workerId-$shortId';
}

Future<void> execVmCommand({
  required String vmName,
  required String command,
  required Firestore firestore,
  required String buildJobId,
  required String runId,
  required String token,
}) async {
  var shell = Shell(verbose: true, throwOnError: false);
  final results = await shell.run(
    "lume ssh $vmName --user $sshUser --password $sshPassword --timeout 0 -- $command",
  );

  for (final result in results) {
    final stdout = result.stdout?.toString().trim();
    final stderr = result.stderr?.toString().trim();

    if (stdout != null && stdout.isNotEmpty) {
      final maskedOutput = stdout.replaceAll(token, '***');
      await logInfo(firestore, buildJobId, runId, maskedOutput);
    }
    if (stderr != null && stderr.isNotEmpty) {
      final maskedOutput = stderr.replaceAll(token, '***');
      await logInfo(firestore, buildJobId, runId, maskedOutput);
    }

    if (result.exitCode != 0) {
      throw Exception('Command failed with exit code ${result.exitCode}');
    }
  }
}

Future<void> runVm(String vmName) async {
  var shell = Shell();
  await shell.run('lume run $vmName --no-display');
}

Future<void> stopVm(String vmName) async {
  var shell = Shell(throwOnError: false);
  await shell.run('lume stop $vmName');
}

Future<void> deleteVm(String vmName) async {
  var shell = Shell(throwOnError: false);
  await shell.run('lume delete $vmName --force');
}

Future<void> waitForVmReady(
  String name, {
  Object? Function()? vmStartError,
}) async {
  var shell = Shell(throwOnError: false);
  _log.info('Waiting for VM to respond...');
  for (var i = 0; i < 120; i++) {
    final error = vmStartError?.call();
    if (error != null) {
      throw Exception('VM failed to start: $error');
    }

    var result = await shell.run(
      'lume ssh $name --user $sshUser --password $sshPassword --timeout 10 -- echo "ready"',
    );
    _log.fine('exit code: ${result.first.exitCode}');

    if (result.first.exitCode == 0) {
      return;
    }

    await Future.delayed(const Duration(seconds: 2));
  }

  throw Exception('VM boot timeout: VM did not respond.');
}

Future<void> cleanupOrphanedVms(String workerId) async {
  try {
    _log.info('Cleaning orphaned VMs');
    final shell = Shell(throwOnError: false, verbose: false);
    final prefix = 'openci-vm-$workerId-';

    final lsResult = await Process.run('ls', ['-1', '${Platform.environment['HOME']}/.lume/']);
    if (lsResult.exitCode != 0) return;

    final vmNames = LineSplitter.split(lsResult.stdout.toString())
        .where((name) => name.startsWith(prefix))
        .toList();

    for (final vmName in vmNames) {
      _log.info('Deleting orphaned VM: $vmName');
      await shell.run('lume stop $vmName');
      await shell.run('lume delete $vmName --force');
    }
    if (vmNames.isNotEmpty) {
      _log.info('Deleted ${vmNames.length} orphaned VM(s)');
    }
  } catch (e, s) {
    _log.severe('Error cleaning up orphaned VMs: $e');
    await Sentry.captureException(e, stackTrace: s);
  }
}

Future<void> pruneStaleVms(
  Firestore firestore,
  String buildJobId,
  String runId, {
  required String workerId,
}) async {
  try {
    final shell = Shell(throwOnError: false, verbose: false);
    final prefix = 'openci-vm-$workerId-';
    final currentVm = currentVmName(workerId: workerId, buildJobId: buildJobId);

    final lsResult = await Process.run('ls', ['-1', '${Platform.environment['HOME']}/.lume/']);
    if (lsResult.exitCode != 0) return;

    final vmNames = LineSplitter.split(lsResult.stdout.toString())
        .where((name) => name.startsWith(prefix) && name != currentVm)
        .toList();

    for (final vmName in vmNames) {
      await logInfo(firestore, buildJobId, runId, 'Deleting stale VM: $vmName');
      await shell.run('lume stop $vmName');
      await shell.run('lume delete $vmName --force');
    }
  } catch (e) {
    await logWarning(
      firestore,
      buildJobId,
      runId,
      'Error pruning stale VMs: $e',
    );
  }
}

Future<void> writeFileToVm(
  String vmName,
  String remotePath,
  String content,
) async {
  final encoded = base64Encode(utf8.encode(content));

  const chunkSize = 4096;
  final chunks = <String>[];
  for (var i = 0; i < encoded.length; i += chunkSize) {
    final end = (i + chunkSize < encoded.length)
        ? i + chunkSize
        : encoded.length;
    chunks.add(encoded.substring(i, end));
  }

  Future<ProcessResult> sshRun(String remoteCommand) async {
    return Process.run('lume', [
      'ssh',
      vmName,
      '--user',
      sshUser,
      '--password',
      sshPassword,
      remoteCommand,
    ]);
  }

  await sshRun('rm -f $remotePath $remotePath.b64');

  for (final chunk in chunks) {
    final result = await sshRun('printf %s $chunk >> $remotePath.b64');
    if (result.exitCode != 0) {
      throw Exception('Failed to write chunk to $remotePath: ${result.stderr}');
    }
  }

  final decodeResult = await sshRun(
    'base64 -D < $remotePath.b64 > $remotePath && rm $remotePath.b64',
  );
  if (decodeResult.exitCode != 0) {
    throw Exception(
      'Failed to decode $remotePath in VM: ${decodeResult.stderr}',
    );
  }
}

Future<void> execCommandStreaming(
  List<String> command,
  String vmName,
  Firestore firestore,
  String buildJobId,
  String runId,
  String token, {
  required Future<bool> Function() isCancelled,
}) async {
  final process = await Process.start('lume', [
    'ssh',
    vmName,
    '--user',
    sshUser,
    '--password',
    sshPassword,
    '--timeout',
    '0',
    '--',
    ...command,
  ]);

  final stdoutCompleter = Completer<void>();
  final stderrCompleter = Completer<void>();

  process.stdout.transform(utf8.decoder).listen((data) {
    final masked = data.replaceAll(token, '***').trim();
    if (masked.isNotEmpty) {
      for (final line in LineSplitter.split(masked)) {
        if (line.trim().isNotEmpty) {
          logInfo(firestore, buildJobId, runId, line.trim());
        }
      }
    }
  }, onDone: () => stdoutCompleter.complete());

  process.stderr.transform(utf8.decoder).listen((data) {
    final masked = data.replaceAll(token, '***').trim();
    if (masked.isNotEmpty) {
      for (final line in LineSplitter.split(masked)) {
        if (line.trim().isNotEmpty) {
          logInfo(firestore, buildJobId, runId, line.trim());
        }
      }
    }
  }, onDone: () => stderrCompleter.complete());

  final cancelTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
    if (await isCancelled()) {
      process.kill(ProcessSignal.sigterm);
    }
  });

  final exitCode = await process.exitCode;
  cancelTimer.cancel();
  await stdoutCompleter.future;
  await stderrCompleter.future;

  if (exitCode != 0) {
    throw Exception('act exited with code $exitCode');
  }
}
