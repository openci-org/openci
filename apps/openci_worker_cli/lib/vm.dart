import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:google_cloud_firestore/google_cloud_firestore.dart';
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
  final shortId = buildJobId.length >= 8
      ? buildJobId.substring(0, 8)
      : buildJobId;
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

const _sshKeyPath = '/tmp/openci-ssh-key';

final _ipPattern = RegExp(r'\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b');

Future<String> getVmIp(String vmName) async {
  const maxRetries = 15;
  const retryDelay = Duration(seconds: 3);
  for (var attempt = 1; attempt <= maxRetries; attempt++) {
    final result = await Process.run('lume', [
      'ssh',
      vmName,
      '--user',
      sshUser,
      '--password',
      sshPassword,
      '--timeout',
      '10',
      '--',
      'ipconfig',
      'getifaddr',
      'en0',
    ]);
    final output = result.stdout.toString().trim();
    final stderr = result.stderr.toString().trim();
    if (output.isNotEmpty) {
      final lines = LineSplitter.split(output).toList();
      for (final line in lines.reversed) {
        final match = _ipPattern.firstMatch(line.trim());
        if (match != null &&
            !line.contains('DEBUG') &&
            !line.contains('INFO')) {
          final ip = match.group(1)!;
          _log.info('VM IP: $ip');
          return ip;
        }
      }
    }
    if (attempt < maxRetries) {
      _log.info(
        'getVmIp attempt $attempt/$maxRetries failed '
        '(stdout: "$output", stderr: "$stderr"). Retrying...',
      );
      await Future<void>.delayed(retryDelay);
    } else {
      throw Exception(
        'Failed to get VM IP for $vmName after $maxRetries attempts: '
        'stdout="$output", stderr="$stderr"',
      );
    }
  }
  throw StateError('Unreachable');
}

Future<void> setupDirectSsh(String vmName) async {
  final keyFile = File(_sshKeyPath);
  if (!keyFile.existsSync()) {
    await Process.run('ssh-keygen', [
      '-t',
      'ed25519',
      '-f',
      _sshKeyPath,
      '-N',
      '',
      '-q',
    ]);
    _log.info('Generated SSH key at $_sshKeyPath');
  }
  final pubKey = File('$_sshKeyPath.pub').readAsStringSync().trim();
  final shell = Shell(throwOnError: false);
  await shell.run(
    'lume ssh $vmName --user $sshUser --password $sshPassword --timeout 10 '
    '-- mkdir -p ~/.ssh '
    '&& echo "$pubKey" >> ~/.ssh/authorized_keys '
    '&& chmod 700 ~/.ssh '
    '&& chmod 600 ~/.ssh/authorized_keys',
  );
  _log.info('SSH key installed on VM');
}

Future<void> cleanupOrphanedVms(String workerId) async {
  try {
    _log.info('Cleaning orphaned VMs');
    final shell = Shell(throwOnError: false, verbose: false);
    final prefix = 'openci-vm-$workerId-';

    final lsResult = await Process.run('ls', [
      '-1',
      '${Platform.environment['HOME']}/.lume/',
    ]);
    if (lsResult.exitCode != 0) return;

    final vmNames = LineSplitter.split(
      lsResult.stdout.toString(),
    ).where((name) => name.startsWith(prefix)).toList();

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

    final lsResult = await Process.run('ls', [
      '-1',
      '${Platform.environment['HOME']}/.lume/',
    ]);
    if (lsResult.exitCode != 0) return;

    final vmNames = LineSplitter.split(
      lsResult.stdout.toString(),
    ).where((name) => name.startsWith(prefix) && name != currentVm).toList();

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

final _gitProgressPattern = RegExp(
  r'^(remote: )?(Counting|Compressing|Receiving|Resolving|Updating) objects?:',
);

bool _isNoisyLine(String line) {
  if (_gitProgressPattern.hasMatch(line)) return true;
  if (line.startsWith('remote: Enumerating objects:')) return true;
  if (line.contains('NIO SSH connection failed')) return true;
  return false;
}

Future<void> execCommandStreaming(
  List<String> command,
  String vmIp,
  Firestore firestore,
  String buildJobId,
  String runId,
  String token, {
  required Future<bool> Function() isCancelled,
}) async {
  final process = await Process.start('ssh', [
    '-o',
    'StrictHostKeyChecking=no',
    '-o',
    'UserKnownHostsFile=/dev/null',
    '-o',
    'LogLevel=ERROR',
    '-o',
    'RequestTTY=no',
    '-o',
    'ServerAliveInterval=30',
    '-o',
    'ServerAliveCountMax=5',
    '-i',
    _sshKeyPath,
    '$sshUser@$vmIp',
    ...command,
  ]);

  await process.stdin.close();

  final stdoutCompleter = Completer<void>();
  final stderrCompleter = Completer<void>();
  final outputErrors = <String>[];
  var hasSuccessfulStep = false;

  void processLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || _isNoisyLine(trimmed)) return;

    if (trimmed.contains('✅') || trimmed.contains('Job succeeded')) {
      hasSuccessfulStep = true;
    }

    if (_isActError(trimmed)) {
      outputErrors.add(trimmed);
    }

    logInfo(firestore, buildJobId, runId, trimmed);
  }

  process.stdout.transform(utf8.decoder).listen((data) {
    final masked = data.replaceAll(token, '***').trim();
    if (masked.isNotEmpty) {
      for (final line in LineSplitter.split(masked)) {
        processLine(line);
      }
    }
  }, onDone: () => stdoutCompleter.complete());

  process.stderr.transform(utf8.decoder).listen((data) {
    final masked = data.replaceAll(token, '***').trim();
    if (masked.isNotEmpty) {
      for (final line in LineSplitter.split(masked)) {
        processLine(line);
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

  if (outputErrors.isNotEmpty) {
    throw Exception('act reported errors:\n${outputErrors.join('\n')}');
  }

  if (!hasSuccessfulStep) {
    throw Exception(
      'act exited with code 0 but no steps were executed. '
      'Check that your workflow has a valid runs-on key.',
    );
  }
}

bool _isActError(String line) {
  final lower = line.toLowerCase();
  if (lower.contains("'runs-on' key not defined")) {
    return true;
  }
  if (lower.contains('level=error') && !lower.contains('cve-')) {
    return true;
  }
  if (lower.contains('❌')) {
    return true;
  }
  return false;
}
