import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:lume_dart/lume_dart.dart' as lume;
import 'package:openci_worker_cli/build_job_logger.dart';
import 'package:openci_worker_cli/constants.dart';
import 'package:sentry/sentry.dart';
import 'package:uuid/uuid.dart';

final _log = Logger('VM');

final defaultLumeVmsDir =
    '${Platform.environment['HOME'] ?? Directory.systemTemp.path}/.lume';

Future<void> cloneVm({
  required String baseVmName,
  required String vmName,
  required String buildJobId,
  required String runId,
  required String workerId,
}) async {
  await logInfo(buildJobId, runId, 'Cloning VM $baseVmName to $vmName...');
  await lume.clone(sourceName: baseVmName, targetName: vmName, showLogs: false);
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
  final exitCode = await _sshKeyExecStream(
    ipAddress,
    command,
    onStdout: (data) {
      final masked = data.replaceAll(token, '***').trim();
      if (masked.isNotEmpty) {
        logInfo(buildJobId, runId, masked);
      }
    },
    onStderr: (data) {
      final masked = data.replaceAll(token, '***').trim();
      if (masked.isNotEmpty) {
        logWarning(buildJobId, runId, masked);
      }
    },
  );

  if (exitCode != 0) {
    throw Exception('Command failed with exit code $exitCode');
  }
}

Future<lume.LumeVM> runVm(String vmName) async {
  final process = await lume.run(
    name: vmName,
    noDisplay: true,
    showLogs: false,
  );

  final timeoutMinsEnv = Platform.environment['OPENCI_VM_BOOT_TIMEOUT_MINS'];
  final timeoutMins = timeoutMinsEnv != null
      ? int.tryParse(timeoutMinsEnv) ?? 10
      : 10;
  final timeout = Duration(minutes: timeoutMins);
  final stopTime = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(stopTime)) {
    try {
      final vms = await lume
          .ls(showLogs: false)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('lume ls timed out'),
          );
      final vm = vms.firstWhere((v) => v.name == vmName);
      if (vm.status == 'running' && vm.ipAddress != null) {
        try {
          final socket = await Socket.connect(
            vm.ipAddress!,
            22,
            timeout: const Duration(seconds: 2),
          );
          await socket.close();
          return vm;
        } catch (_) {
          if (vm.sshAvailable == true) {
            return vm;
          }
        }
      }
    } catch (e, stack) {
      print('DEBUG: Error in runVm loop: $e\n$stack');
    }
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  process.kill();
  throw TimeoutException(
    'Timeout waiting for Lume VM "$vmName" to boot and become SSH available.',
  );
}

Future<void> stopVm(lume.LumeVM? vm) async {
  if (vm == null) return;
  try {
    await lume.stop(name: vm.name, showLogs: false);
  } catch (_) {}
}

Future<void> deleteVm(String vmName) async {
  try {
    await lume.delete(name: vmName, showLogs: false);
  } catch (_) {}
}

String _workerId = 'default';

void initVmConfig(String workerId) {
  _workerId = workerId;
}

String get _sshKeyPath => '/tmp/openci-ssh-key-$_workerId';
String get _askPassPath => '/tmp/openci-askpass-$_workerId.sh';

/// Shared options for the system `ssh`/`scp` binaries.
const List<String> _sshBaseOpts = [
  '-o',
  'StrictHostKeyChecking=no',
  '-o',
  'UserKnownHostsFile=/dev/null',
  '-o',
  'LogLevel=ERROR',
  '-o',
  'ConnectTimeout=30',
  '-o',
  'ServerAliveInterval=30',
  '-o',
  'ServerAliveCountMax=5',
];

/// Runs [command] on the guest via the system `ssh` binary using key auth,
/// streaming output. We deliberately shell out to `/usr/bin/ssh` (and `scp`)
/// instead of an in-process Dart socket (dartssh2): on macOS 15+/26 the Local
/// Network privacy feature blocks in-process sockets of a non-exempt process
/// (e.g. the worker running as a LaunchAgent) from reaching the VM's local
/// network address, while Apple's own system binaries remain exempt.
Future<int> _sshKeyExecStream(
  String? ip,
  String command, {
  void Function(String data)? onStdout,
  void Function(String data)? onStderr,
}) async {
  if (ip == null) {
    throw StateError('Cannot run SSH command: VM IP is null.');
  }
  final process = await Process.start('/usr/bin/ssh', [
    ..._sshBaseOpts,
    '-o',
    'BatchMode=yes',
    '-o',
    'RequestTTY=no',
    '-i',
    _sshKeyPath,
    '$sshUser@$ip',
    command,
  ]);
  await process.stdin.close();
  final outDone = process.stdout
      .transform(utf8.decoder)
      .forEach((data) => onStdout?.call(data));
  final errDone = process.stderr
      .transform(utf8.decoder)
      .forEach((data) => onStderr?.call(data));
  final exitCode = await process.exitCode;
  await outDone;
  await errDone;
  return exitCode;
}

Future<void> setupDirectSsh(lume.LumeVM vm) async {
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
  final ip = vm.ipAddress;
  if (ip == null) {
    throw StateError('VM IP is null; cannot install SSH key.');
  }

  // Drive the system `ssh` binary's password auth via SSH_ASKPASS (no TTY
  // required). Using /usr/bin/ssh keeps this exempt from macOS Local Network
  // privacy when the worker runs as a LaunchAgent.
  final askpass = File(_askPassPath);
  askpass.writeAsStringSync("#!/bin/sh\nprintf '%s' '$sshPassword'\n");
  await Process.run('chmod', ['+x', _askPassPath]);

  const installCmd =
      'mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys';

  Future<int> runPasswordSsh(String command) async {
    final process = await Process.start(
      '/usr/bin/ssh',
      [
        ..._sshBaseOpts,
        '-o',
        'PubkeyAuthentication=no',
        '-o',
        'PreferredAuthentications=password,keyboard-interactive',
        '-o',
        'NumberOfPasswordPrompts=1',
        '$sshUser@$ip',
        command,
      ],
      environment: {
        'SSH_ASKPASS': _askPassPath,
        'SSH_ASKPASS_REQUIRE': 'force',
        'DISPLAY': ':0',
      },
    );
    await process.stdin.close();
    await process.stdout.drain<void>();
    await process.stderr.drain<void>();
    return process.exitCode;
  }

  // The append uses base64 of the public key to avoid any quoting issues over
  // the password-auth ssh channel.
  final pubKeyB64 = base64Encode(utf8.encode('$pubKey\n'));
  final appendCmd =
      'printf %s \'$pubKeyB64\' | base64 -D >> ~/.ssh/authorized_keys';

  var exitCode = -1;
  for (var attempt = 1; attempt <= 5; attempt++) {
    exitCode = await runPasswordSsh('$installCmd && $appendCmd');
    if (exitCode == 0) break;
    _log.warning(
      'SSH key install attempt $attempt failed (exit $exitCode); retrying...',
    );
    await Future<void>.delayed(const Duration(seconds: 5));
  }

  try {
    askpass.deleteSync();
  } catch (_) {}

  if (exitCode != 0) {
    throw Exception('Failed to install SSH key on VM. Exit code: $exitCode');
  }
  _log.info('SSH key installed on VM');
}

Future<void> _stopAndDeleteVm(
  lume.LumeVM vm, {
  required String label,
  String logPrefix = '',
}) async {
  if (vm.status == 'running') {
    try {
      await lume.stop(name: vm.name, showLogs: false);
    } catch (e) {
      _log.warning('${logPrefix}Failed to stop $label VM ${vm.name}: $e');
    }
  }
  try {
    await lume.delete(name: vm.name, showLogs: false);
  } catch (e) {
    _log.warning('${logPrefix}Failed to delete $label VM ${vm.name}: $e');
  }
}

Future<void> cleanupOrphanedVms(String workerId) async {
  try {
    _log.info('Cleaning orphaned VMs for worker $workerId...');
    final prefix = 'openci-vm-$workerId-';

    try {
      await Process.run('pkill', ['-9', '-f', 'lume .*$prefix']);
    } catch (e, s) {
      _log.warning('Failed to pkill orphaned Lume runners: $e');
      await Sentry.captureException(e, stackTrace: s);
    }

    final vms = await lume.ls(showLogs: false);
    final workerVms = vms.where((vm) => vm.name.startsWith(prefix)).toList();

    for (final vm in workerVms) {
      _log.info('Cleaning up orphaned VM: ${vm.name} (status: ${vm.status})');
      await _stopAndDeleteVm(vm, label: 'orphaned');
    }
  } catch (e, s) {
    _log.severe('Error cleaning up orphaned VMs: $e');
    await Sentry.captureException(e, stackTrace: s);
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

    final vms = await lume.ls(showLogs: false);
    final staleVms = vms
        .where((vm) => vm.name.startsWith(prefix) && vm.name != currentVm)
        .toList();

    for (final vm in staleVms) {
      _log.info(
        '[$runId] Deleting stale VM: ${vm.name} (status: ${vm.status})',
      );
      await _stopAndDeleteVm(vm, label: 'stale', logPrefix: '[$runId] ');
    }
  } catch (e) {
    _log.warning('[$runId] Error pruning stale VMs: $e');
  }
}

Future<void> writeFileToVm(
  String? ipAddress,
  String remotePath,
  String content,
) async {
  if (ipAddress == null) {
    throw StateError('Cannot write file to VM: IP is null.');
  }

  // Copy via the system `scp` binary (key auth). This relies on the SSH key
  // already installed by setupDirectSsh and, like ssh, is exempt from macOS
  // Local Network privacy when the worker runs as a LaunchAgent.
  final local = File('/tmp/openci-upload-${const Uuid().v4()}');
  local.writeAsStringSync(content);
  try {
    final result = await Process.run('/usr/bin/scp', [
      ..._sshBaseOpts,
      '-o',
      'BatchMode=yes',
      '-i',
      _sshKeyPath,
      local.path,
      '$sshUser@$ipAddress:$remotePath',
    ]);
    if (result.exitCode != 0) {
      throw Exception('Failed to scp file to $remotePath: ${result.stderr}');
    }
  } finally {
    try {
      local.deleteSync();
    } catch (_) {}
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
  Duration timeout = maxJobTimeout,
}) async {
  if (vmIp == null) {
    throw StateError('Cannot stream SSH command: VM IP is null.');
  }

  final process = await Process.start('/usr/bin/ssh', [
    '-o',
    'StrictHostKeyChecking=no',
    '-o',
    'UserKnownHostsFile=/dev/null',
    '-o',
    'LogLevel=ERROR',
    '-o',
    'RequestTTY=no',
    '-o',
    'BatchMode=yes',
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

    final cleanLine = stripActPrefix(trimmed);
    logInfo(buildJobId, runId, cleanLine);
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

  final startTime = DateTime.now();
  var isTimedOut = false;

  final cancelTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
    if (DateTime.now().difference(startTime) > timeout) {
      isTimedOut = true;
      process.kill(ProcessSignal.sigterm);
      return;
    }
    if (await isCancelled()) {
      process.kill(ProcessSignal.sigterm);
    }
  });

  final exitCode = await process.exitCode;
  cancelTimer.cancel();
  await stdoutCompleter.future;
  await stderrCompleter.future;

  if (isTimedOut) {
    throw TimeoutException(
      'Job execution exceeded timeout of ${timeout.inMinutes} minutes.',
    );
  }

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
  if (line.contains('❌')) {
    // Some tools (e.g. Patrol) print a decorative "❌ Failed: 0" summary line
    // where the count is zero, which means success, not a failure. Treat any
    // explicit zero failure/error count as benign.
    if (RegExp(
      r'(?:failed|failures|failing|errors?)\s*[:=]?\s*0\b',
    ).hasMatch(lower)) {
      return false;
    }
    return true;
  }
  return false;
}
