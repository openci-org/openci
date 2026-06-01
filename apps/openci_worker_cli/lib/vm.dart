import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:openci_worker_cli/constants.dart';
import 'package:openci_worker_cli/logger.dart';
import 'package:avf_dart/avf_dart.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('VM');

Future<void> cloneVm({
  required String baseVmName,
  required String vmName,
  required String buildJobId,
  required String runId,
}) async {
  await logInfo(
    buildJobId,
    runId,
    'Cloning VM $baseVmName to $vmName...',
  );
  await VirtualMachine.clone(sourceName: baseVmName, targetName: vmName);
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
  required String buildJobId,
  required String runId,
  required String token,
  required String? ipAddress,
}) async {
  final exitCode = await VirtualMachineSsh.executeStream(
    command,
    ipAddress: ipAddress,
    username: sshUser,
    privateKeyPath: _sshKeyPath,
    onStdout: (data) async {
      final masked = data.replaceAll(token, '***').trim();
      if (masked.isNotEmpty) {
        await logInfo(buildJobId, runId, masked);
      }
    },
    onStderr: (data) async {
      final masked = data.replaceAll(token, '***').trim();
      if (masked.isNotEmpty) {
        await logWarning(buildJobId, runId, masked);
      }
    },
  );

  if (exitCode != 0) {
    throw Exception('Command failed with exit code $exitCode');
  }
}

Future<VirtualMachine> runVm(String vmName) async {
  return await VirtualMachine.boot(name: vmName);
}

Future<void> stopVm(VirtualMachine? vm) async {
  if (vm == null) return;
  try {
    await vm.stop();
  } catch (_) {}
}

Future<void> deleteVm(String vmName) async {
  try {
    await VirtualMachine.delete(vmName);
  } catch (_) {}
}

const _sshKeyPath = '/tmp/openci-ssh-key';

Future<void> setupDirectSsh(VirtualMachine vm) async {
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

  // Install SSH key via avf_dart's SSH module (using default password)
  final exitCode = await VirtualMachineSsh.executeStream(
    'mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && grep -qxF \'$pubKey\' ~/.ssh/authorized_keys || printf \'%s\\n\' \'$pubKey\' >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys',
    ipAddress: vm.ipAddress,
    username: sshUser,
    password: sshPassword,
  );

  if (exitCode != 0) {
    throw Exception('Failed to install SSH key on VM. Exit code: $exitCode');
  }
  _log.info('SSH key installed on VM');
}

Future<void> cleanupOrphanedVms(String workerId) async {
  try {
    _log.info('Cleaning orphaned VMs for worker $workerId...');
    final prefix = 'openci-vm-$workerId-';

    // 1. Clean up filesystem-based VMs for this worker
    final vms = await VirtualMachine.list();
    final workerVms = vms.where((vm) => vm.name.startsWith(prefix)).toList();

    for (final vm in workerVms) {
      _log.info('Deleting orphaned VM: ${vm.name}');
      await VirtualMachine.delete(vm.name);
    }

    // 2. Kill zombie helper processes
    await _killZombieAvfProcesses();
  } catch (e, s) {
    _log.severe('Error cleaning up orphaned VMs: $e');
    await Sentry.captureException(e, stackTrace: s);
  }
}

Future<void> _killZombieAvfProcesses() async {
  try {
    final psResult = await Process.run('ps', ['aux']);
    if (psResult.exitCode != 0) return;

    final avfRunPattern = RegExp(r'^\S+\s+(\d+)\s+.*avf_helper\s+boot\s+(\S+)');
    final zombiePids = <int>[];

    for (final line in LineSplitter.split(psResult.stdout.toString())) {
      final match = avfRunPattern.firstMatch(line);
      if (match == null) continue;

      final pid = int.tryParse(match.group(1)!);
      final vmPath = match.group(2)!;
      if (pid == null) continue;

      // Check if the VM directory still exists
      final vmDir = Directory(vmPath);
      if (!vmDir.existsSync()) {
        _log.warning('Found zombie AVF process: PID=$pid VMPath=$vmPath. Killing...');
        zombiePids.add(pid);
      }
    }

    for (final pid in zombiePids) {
      Process.killPid(pid);
    }
  } catch (e) {
    _log.warning('Error killing zombie AVF processes: $e');
  }
}

Future<void> pruneStaleVms(
  String buildJobId,
  String runId, {
  required String workerId,
}) async {
  try {
    final prefix = 'openci-vm-$workerId-';
    final currentVm = currentVmName(workerId: workerId, buildJobId: buildJobId);

    final vms = await VirtualMachine.list();
    final staleVms = vms.where((vm) => vm.name.startsWith(prefix) && vm.name != currentVm).toList();

    for (final vm in staleVms) {
      await logInfo(buildJobId, runId, 'Deleting stale VM: ${vm.name}');
      await VirtualMachine.delete(vm.name);
    }
  } catch (e) {
    await logWarning(
      buildJobId,
      runId,
      'Error pruning stale VMs: $e',
    );
  }
}

Future<void> writeFileToVm(
  String? ipAddress,
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

  Future<int> sshRun(String remoteCommand) async {
    return await VirtualMachineSsh.executeStream(
      remoteCommand,
      ipAddress: ipAddress,
      username: sshUser,
      password: sshPassword,
    );
  }

  await sshRun('rm -f $remotePath $remotePath.b64');

  for (final chunk in chunks) {
    final exitCode = await sshRun('printf %s \'$chunk\' >> $remotePath.b64');
    if (exitCode != 0) {
      throw Exception('Failed to write chunk to $remotePath');
    }
  }

  final decodeExitCode = await sshRun(
    'base64 -D < $remotePath.b64 > $remotePath && rm $remotePath.b64',
  );
  if (decodeExitCode != 0) {
    throw Exception(
      'Failed to decode $remotePath in VM: $decodeExitCode',
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
  String? vmIp,
  String buildJobId,
  String runId,
  String token, {
  required Future<bool> Function() isCancelled,
}) async {
  if (vmIp == null) {
    throw StateError('Cannot stream SSH command: VM IP is null.');
  }

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

    logInfo(buildJobId, runId, trimmed);
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
