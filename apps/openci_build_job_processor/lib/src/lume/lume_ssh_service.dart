import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:lume_dart/lume_dart.dart';
import 'package:openci_build_job_processor/openci_build_job_processor.dart';
import 'package:openci_build_job_processor/src/logging/build_job_logger.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('LumeSshService');

class LumeSshService {
  static const _sshUser = 'admin';
  static const _sshPassword = 'admin';
  static const List<String> _sshBaseOpts = [
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

  // Visible for testing to speed up test execution
  Duration retryDelay = const Duration(seconds: 5);
  Duration sshTimeout = const Duration(seconds: 45);

  String getSshKeyPath(String runId) => '/tmp/openci-ssh-key-$runId';
  String getAskPassPath(String runId) => '/tmp/openci-askpass-$runId.sh';

  Future<void> generateSshKey(String sshKeyPath) async {
    final keyFile = File(sshKeyPath);
    final pubKeyFile = File('$sshKeyPath.pub');

    try {
      if (keyFile.existsSync()) {
        keyFile.deleteSync();
      }
      if (pubKeyFile.existsSync()) {
        pubKeyFile.deleteSync();
      }
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }

    await Process.run('ssh-keygen', [
      '-t',
      'ed25519',
      '-f',
      sshKeyPath,
      '-N',
      '',
      '-q',
    ]);
  }

  Future<void> setupDirectSsh(
    LumeVM vm,
    String runId, {
    String? jumpHost,
  }) async {
    final sshKeyPath = getSshKeyPath(runId);
    final askPassPath = getAskPassPath(runId);

    await generateSshKey(sshKeyPath);

    final ip = vm.ipAddress;
    if (ip == null) {
      throw StateError('VM IP is null; cannot install SSH key.');
    }

    final pubKey = File('$sshKeyPath.pub').readAsStringSync().trim();
    await installPublicKeyToVm(
      ip: ip,
      pubKey: pubKey,
      askPassPath: askPassPath,
      vmName: vm.name,
      runId: runId,
      jumpHost: jumpHost,
    );
  }

  Future<void> installPublicKeyToVm({
    required String ip,
    required String pubKey,
    required String askPassPath,
    required String vmName,
    required String runId,
    String? jumpHost,
  }) async {
    await prepareAskPassFile(askPassPath);

    try {
      await installKeyViaPasswordSsh(
        ip: ip,
        pubKey: pubKey,
        askPassPath: askPassPath,
        vmName: vmName,
        runId: runId,
        jumpHost: jumpHost,
      );
    } finally {
      deleteAskPassFile(askPassPath);
    }
  }

  Future<void> prepareAskPassFile(String path) async {
    final askpass = File(path);
    askpass.writeAsStringSync("#!/bin/sh\nprintf '%s' '$_sshPassword'\n");
    await Process.run('chmod', ['+x', path]);
  }

  void deleteAskPassFile(String path) {
    try {
      final askpass = File(path);
      if (askpass.existsSync()) {
        askpass.deleteSync();
      }
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }
  }

  Future<void> installKeyViaPasswordSsh({
    required String ip,
    required String pubKey,
    required String askPassPath,
    required String vmName,
    required String runId,
    String? jumpHost,
  }) async {
    const installCmd =
        'mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys';

    final pubKeyB64 = base64Encode(utf8.encode('$pubKey\n'));
    final appendCmd =
        'printf %s \'$pubKeyB64\' | base64 -D >> ~/.ssh/authorized_keys';

    var exitCode = -1;
    String lastStderr = '';
    for (var attempt = 1; attempt <= 30; attempt++) {
      final result = await runPasswordSsh(
        ip: ip,
        command: '$installCmd && $appendCmd',
        askPassPath: askPassPath,
        jumpHost: jumpHost,
      );
      exitCode = result.exitCode;
      lastStderr = result.stderr;
      if (exitCode == 0) break;
      await Future<void>.delayed(retryDelay);
    }

    if (exitCode != 0) {
      throw Exception(
        'Failed to install SSH key on VM. '
        'VM: $vmName ($ip), Run ID: $runId, '
        'Worker Host: ${Platform.localHostname}, '
        'Exit code: $exitCode, '
        'Error: ${lastStderr.trim()}',
      );
    }
  }

  Future<SshResult> runPasswordSsh({
    required String ip,
    required String command,
    required String askPassPath,
    String? jumpHost,
  }) async {
    final jumpOpts = jumpHost != null
        ? [
            '-o',
            'ProxyCommand=ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p $_sshUser@$jumpHost',
          ]
        : <String>[];
    final process = await Process.start(
      '/usr/bin/ssh',
      [
        ..._sshBaseOpts,
        ...jumpOpts,
        '-o',
        'PubkeyAuthentication=no',
        '-o',
        'PreferredAuthentications=password,keyboard-interactive',
        '-o',
        'NumberOfPasswordPrompts=1',
        '$_sshUser@$ip',
        command,
      ],
      environment: {
        'SSH_ASKPASS': askPassPath,
        'SSH_ASKPASS_REQUIRE': 'force',
        'DISPLAY': ':0',
      },
    );

    final stdoutBuffer = <String>[];
    final stderrBuffer = <String>[];

    final stdoutSub = process.stdout
        .transform(utf8.decoder)
        .listen((data) => stdoutBuffer.add(data));
    final stderrSub = process.stderr
        .transform(utf8.decoder)
        .listen((data) => stderrBuffer.add(data));

    try {
      final exitCode = await () async {
        await process.stdin.close();
        return await process.exitCode;
      }().timeout(sshTimeout);

      await stdoutSub.cancel();
      await stderrSub.cancel();

      return SshResult(
        exitCode: exitCode,
        stdout: stdoutBuffer.join(),
        stderr: stderrBuffer.join(),
      );
    } on TimeoutException {
      await stdoutSub.cancel();
      await stderrSub.cancel();
      process.kill();
      return SshResult(
        exitCode: -1,
        stdout: stdoutBuffer.join(),
        stderr: 'SSH connection timed out.',
      );
    }
  }

  Future<void> clearArpCache({
    required String jumpHost,
    required String runId,
  }) async {
    final askPassPath = getAskPassPath(runId);
    try {
      await prepareAskPassFile(askPassPath);
      _log.info('Clearing ARP cache on Lume host: $jumpHost');
      final result = await runPasswordSsh(
        ip: jumpHost,
        command: 'echo $_sshPassword | sudo -S arp -d -a',
        askPassPath: askPassPath,
      );
      if (result.exitCode != 0) {
        _log.warning(
          'Failed to clear ARP cache on Lume host: $jumpHost. '
          'Exit code: ${result.exitCode}, Error: ${result.stderr.trim()}',
        );
      } else {
        _log.info('Successfully cleared ARP cache on Lume host: $jumpHost');
      }
    } catch (e, s) {
      _log.warning(
        'Error while clearing ARP cache on Lume host $jumpHost',
        e,
        s,
      );
      unawaited(Sentry.captureException(e, stackTrace: s));
    } finally {
      deleteAskPassFile(askPassPath);
    }
  }

  Future<int> executeSshCommand({
    required String ip,
    required String runId,
    required String command,
    String? jumpHost,
  }) async {
    final sshKeyPath = getSshKeyPath(runId);
    final jumpOpts = jumpHost != null
        ? [
            '-o',
            'ProxyCommand=ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p $_sshUser@$jumpHost',
          ]
        : <String>[];
    final process = await Process.start('/usr/bin/ssh', [
      ..._sshBaseOpts,
      ...jumpOpts,
      '-i',
      sshKeyPath,
      '$_sshUser@$ip',
      command,
    ]);

    final stdoutBuffer = <String>[];
    final stderrBuffer = <String>[];

    final stdoutSub = process.stdout
        .transform(utf8.decoder)
        .listen((data) => stdoutBuffer.add(data));
    final stderrSub = process.stderr
        .transform(utf8.decoder)
        .listen((data) => stderrBuffer.add(data));

    try {
      final exitCode = await () async {
        await process.stdin.close();
        return await process.exitCode;
      }().timeout(sshTimeout);

      await stdoutSub.cancel();
      await stderrSub.cancel();

      if (exitCode != 0) {
        final errOut = stderrBuffer.join().trim();
        _log.warning('SSH command failed (exit: $exitCode). Command: $command');
        if (errOut.isNotEmpty) {
          _log.warning('SSH stderr: $errOut');
        }
      }
      return exitCode;
    } on TimeoutException {
      await stdoutSub.cancel();
      await stderrSub.cancel();
      process.kill();
      _log.warning('SSH command timed out. Command: $command');
      return -1;
    }
  }

  Future<void> writeFileToVm({
    required String ip,
    required String runId,
    required String remotePath,
    required String content,
    String? jumpHost,
  }) async {
    final sshKeyPath = getSshKeyPath(runId);
    final localFile = File(
      '/tmp/openci-upload-${DateTime.now().millisecondsSinceEpoch}',
    );
    localFile.writeAsStringSync(content);

    try {
      final jumpOpts = jumpHost != null
          ? [
              '-o',
              'ProxyCommand=ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p $_sshUser@$jumpHost',
            ]
          : <String>[];
      final processResult = await Process.run('/usr/bin/scp', [
        ..._sshBaseOpts,
        ...jumpOpts,
        '-o',
        'BatchMode=yes',
        '-i',
        sshKeyPath,
        localFile.path,
        '$_sshUser@$ip:$remotePath',
      ]).timeout(sshTimeout);

      if (processResult.exitCode != 0) {
        throw Exception(
          'Failed to scp file to $remotePath: ${processResult.stderr}',
        );
      }
    } finally {
      try {
        if (localFile.existsSync()) {
          localFile.deleteSync();
        }
      } catch (e, s) {
        unawaited(Sentry.captureException(e, stackTrace: s));
      }
    }
  }

  void cleanupTempSshKeys(String runId) {
    try {
      final sshKeyPath = getSshKeyPath(runId);
      final keyFile = File(sshKeyPath);
      if (keyFile.existsSync()) {
        keyFile.deleteSync();
      }
      final pubKeyFile = File('$sshKeyPath.pub');
      if (pubKeyFile.existsSync()) {
        pubKeyFile.deleteSync();
      }
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }

    try {
      final askPassPath = getAskPassPath(runId);
      final askPassFile = File(askPassPath);
      if (askPassFile.existsSync()) {
        askPassFile.deleteSync();
      }
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }
  }

  Future<void> execCommandStreaming({
    required List<String> command,
    required String ip,
    required String buildJobId,
    required String runId,
    required String token,
    required Future<bool> Function() isCancelled,
    String? jumpHost,
    Duration timeout = const Duration(minutes: 60),
  }) async {
    final sshKeyPath = getSshKeyPath(runId);
    final jumpOpts = jumpHost != null
        ? [
            '-o',
            'ProxyCommand=ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p $_sshUser@$jumpHost',
          ]
        : <String>[];

    final process = await Process.start('/usr/bin/ssh', [
      ..._sshBaseOpts,
      ...jumpOpts,
      '-o',
      'RequestTTY=no',
      '-o',
      'BatchMode=yes',
      '-i',
      sshKeyPath,
      '$_sshUser@$ip',
      ...command,
    ]);

    _log.info('SSH process started. PID: ${process.pid}, Command: $command');

    await process.stdin.close();
    _log.info('Closed stdin stream.');

    final stdoutCompleter = Completer<void>();
    final stderrCompleter = Completer<void>();
    final outputErrors = <String>[];
    var hasSuccessfulStep = false;

    final gitProgressPattern = RegExp(
      r'^(Receiving objects|Resolving deltas|Updating files|'
      r'Comparing stages|Indexing objects|Writing objects):\s*\d+',
    );

    bool isNoisyLine(String line) {
      if (gitProgressPattern.hasMatch(line)) return true;
      if (line.startsWith('remote: Enumerating objects:')) return true;
      if (line.contains('NIO SSH connection failed')) return true;
      return false;
    }

    bool isActError(String line) {
      return line.startsWith('  ❌  ') || line.startsWith('  ❌ ');
    }

    String? currentStepId;
    String? currentStepName;
    var stepOrder = 10;
    var stepStartTime = DateTime.now().toUtc();
    final runPattern = RegExp(r'^  ⭐  Run (.*)$');

    Future<void> closeCurrentStep({required String status}) async {
      if (currentStepId != null && currentStepName != null) {
        final now = DateTime.now().toUtc();
        final duration = now.difference(stepStartTime).inMilliseconds;
        await sendStepStatusUpdate(
          buildJobId: buildJobId,
          runId: runId,
          stepId: currentStepId!,
          name: currentStepName!,
          status: status,
          durationMs: duration,
          stepOrder: stepOrder++,
          createdAt: stepStartTime.toIso8601String(),
          updatedAt: now.toIso8601String(),
        );
      }
    }

    void processLine(String line) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || isNoisyLine(trimmed)) return;

      if (trimmed.contains('✅') || trimmed.contains('Job succeeded')) {
        hasSuccessfulStep = true;
      }

      if (isActError(trimmed)) {
        outputErrors.add(trimmed);
      }

      final cleanLine = stripActPrefix(trimmed);

      // ⭐ Run <Step Name> の検知 (act の出力パース)
      if (cleanLine.contains('⭐') && cleanLine.contains('Run ')) {
        final runMatch = runPattern.firstMatch(
          cleanLine.replaceAll(RegExp(r'^\[[^\]]+\]\s*'), ''),
        );
        final stepName = runMatch?.group(1)?.trim() ?? 'Run Step';

        unawaited(() async {
          await closeCurrentStep(status: 'SUCCESS');
          currentStepName = stepName;
          currentStepId =
              'step_${stepName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
          stepStartTime = DateTime.now().toUtc();
          await sendStepStatusUpdate(
            buildJobId: buildJobId,
            runId: runId,
            stepId: currentStepId!,
            name: currentStepName!,
            status: 'IN_PROGRESS',
            durationMs: 0,
            stepOrder: stepOrder++,
            createdAt: stepStartTime.toIso8601String(),
            updatedAt: stepStartTime.toIso8601String(),
          );
        }());
      } else if (cleanLine.contains('✅') && cleanLine.contains('Success - ')) {
        unawaited(closeCurrentStep(status: 'SUCCESS'));
        currentStepId = null;
        currentStepName = null;
      } else if (cleanLine.contains('❌') && cleanLine.contains('Failure - ')) {
        unawaited(closeCurrentStep(status: 'FAILURE'));
        currentStepId = null;
        currentStepName = null;
      }

      if (currentStepId != null) {
        writeBuildStepLog(buildJobId, runId, currentStepId!, cleanLine);
      } else {
        writeBuildStepLog(buildJobId, runId, 'pre_build_setup', cleanLine);
      }

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
      } else if (await isCancelled()) {
        process.kill(ProcessSignal.sigterm);
      }
    });

    _log.info('Waiting for SSH output or process exit...');
    final exitCodeFuture = process.exitCode;
    await Future.any<dynamic>([
      Future.wait([stdoutCompleter.future, stderrCompleter.future]),
      exitCodeFuture,
    ]);
    cancelTimer.cancel();
    _log.info('Future.any resolved (process exit or stream end).');

    // プロセス終了で抜けた場合に備え、最後のエラーログの読みこぼしを防ぐため、
    // 最大200ミリ秒だけログの読み切り（ストリーム of stdout/stderr のクローズ）を待ちます。
    await Future.wait([
      stdoutCompleter.future,
      stderrCompleter.future,
    ]).timeout(const Duration(milliseconds: 200), onTimeout: () => []);
    _log.info('Drained streams with 200ms grace period.');

    final exitCode = await exitCodeFuture;
    _log.info('SSH execution completed. Exit code: $exitCode');

    if (isTimedOut) {
      await closeCurrentStep(status: 'FAILURE');
      await flushRemainingStepLogs(runId: runId);
      throw TimeoutException(
        'act timed out after ${timeout.inMinutes} minutes',
      );
    }

    if (exitCode != 0) {
      await closeCurrentStep(status: 'FAILURE');
      await flushRemainingStepLogs(runId: runId);
      throw Exception('act exited with code $exitCode');
    }

    if (outputErrors.isNotEmpty) {
      await closeCurrentStep(status: 'FAILURE');
      await flushRemainingStepLogs(runId: runId);
      throw Exception('act reported errors:\n${outputErrors.join('\n')}');
    }

    if (!hasSuccessfulStep) {
      await closeCurrentStep(status: 'FAILURE');
      await flushRemainingStepLogs(runId: runId);
      throw Exception(
        'act exited with code 0 but no steps were executed. '
        'Ensure the workflow file is correct and your workflow/job triggers match.',
      );
    }

    await closeCurrentStep(status: 'SUCCESS');
    await flushRemainingStepLogs(runId: runId);
  }
}

class SshResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  SshResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });
}
