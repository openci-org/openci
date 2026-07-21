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

    final jobStates = <String, Map<String, dynamic>>{};
    final actJobPattern = RegExp(r'^\[([^\]]+)\]\s*(.*)$');

    Map<String, dynamic> getJobState(String jobName) {
      return jobStates.putIfAbsent(jobName, () {
        final startTime = DateTime.now().toUtc();
        final sanitizedJobName = jobName.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '_',
        );
        final preBuildStepId = 'pre_build_setup_$sanitizedJobName';
        final state = <String, dynamic>{
          'currentStepId': preBuildStepId,
          'currentStepName': 'Pre-build setup',
          'stepOrder': 4,
          'stepStartTime': startTime,
        };
        unawaited(
          sendStepStatusUpdate(
            buildJobId: buildJobId,
            runId: runId,
            stepId: preBuildStepId,
            name: '[$jobName] Pre-build setup',
            status: 'IN_PROGRESS',
            durationMs: 0,
            stepOrder: 4,
            createdAt: startTime.toIso8601String(),
            updatedAt: startTime.toIso8601String(),
          ),
        );
        return state;
      });
    }

    Future<void> closeJobCurrentStep(
      String jobName, {
      required String status,
    }) async {
      final state = getJobState(jobName);
      final prevStepId = state['currentStepId'] as String?;
      final prevStepName = state['currentStepName'] as String?;
      final prevStepStartTime = state['stepStartTime'] as DateTime;
      final prevStepOrder = state['stepOrder'] as int;

      state['currentStepId'] = null;
      state['currentStepName'] = null;

      if (prevStepId != null && prevStepName != null) {
        final now = DateTime.now().toUtc();
        final duration = now.difference(prevStepStartTime).inMilliseconds;
        await sendStepStatusUpdate(
          buildJobId: buildJobId,
          runId: runId,
          stepId: prevStepId,
          name: '[$jobName] $prevStepName',
          status: status,
          durationMs: duration,
          stepOrder: prevStepOrder,
          createdAt: prevStepStartTime.toIso8601String(),
          updatedAt: now.toIso8601String(),
        );
      }
    }

    void processLine(String line) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || isNoisyLine(trimmed)) return;

      Map<String, dynamic>? jsonLog;
      try {
        if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
          jsonLog = jsonDecode(trimmed) as Map<String, dynamic>?;
        }
      } catch (_) {}

      if (jsonLog != null) {
        final rawJobName = jsonLog['job'] as String? ?? 'global';
        final slashIndex = rawJobName.lastIndexOf('/');
        final jobName = slashIndex != -1
            ? rawJobName.substring(slashIndex + 1).trim()
            : rawJobName.trim();

        final stepName = jsonLog['step'] as String?;
        final message = (jsonLog['msg'] ?? jsonLog['message']) as String?;
        final status = jsonLog['status'] as String?;

        if (status == 'success' || status == 'failure') {
          hasSuccessfulStep = true;
        }

        if (stepName != null && stepName.isNotEmpty) {
          final state = getJobState(jobName);
          final prevStepName = state['currentStepName'] as String?;
          final prevStepId = state['currentStepId'] as String?;
          final prevStepStartTime = state['stepStartTime'] as DateTime;
          final prevStepOrder = state['stepOrder'] as int;

          if (prevStepName != stepName) {
            final sanitizedJobName = jobName.toLowerCase().replaceAll(
              RegExp(r'[^a-z0-9]'),
              '_',
            );
            final sanitizedStepName = stepName.toLowerCase().replaceAll(
              RegExp(r'[^a-z0-9]'),
              '_',
            );
            final currentStepOrder = prevStepId != null
                ? prevStepOrder + 1
                : prevStepOrder;
            final stepId =
                'step_${sanitizedJobName}_${currentStepOrder}_$sanitizedStepName';

            state['currentStepName'] = stepName;
            state['currentStepId'] = stepId;
            final startTime = DateTime.now().toUtc();
            state['stepStartTime'] = startTime;
            state['stepOrder'] = currentStepOrder + 1;

            unawaited(() async {
              if (prevStepId != null && prevStepName != null) {
                final now = DateTime.now().toUtc();
                final duration = now
                    .difference(prevStepStartTime)
                    .inMilliseconds;
                await sendStepStatusUpdate(
                  buildJobId: buildJobId,
                  runId: runId,
                  stepId: prevStepId,
                  name: '[$jobName] $prevStepName',
                  status: 'SUCCESS',
                  durationMs: duration,
                  stepOrder: prevStepOrder,
                  createdAt: prevStepStartTime.toIso8601String(),
                  updatedAt: now.toIso8601String(),
                );
              }
              await sendStepStatusUpdate(
                buildJobId: buildJobId,
                runId: runId,
                stepId: stepId,
                name: '[$jobName] $stepName',
                status: 'IN_PROGRESS',
                durationMs: 0,
                stepOrder: currentStepOrder,
                createdAt: startTime.toIso8601String(),
                updatedAt: startTime.toIso8601String(),
              );
            }());
          }
        }

        final state = getJobState(jobName);
        final currentStepId = state['currentStepId'] as String?;

        if (message != null && message.isNotEmpty) {
          if (currentStepId != null) {
            writeBuildStepLog(buildJobId, runId, currentStepId, message);
          } else {
            final sanitizedJobName = jobName.toLowerCase().replaceAll(
              RegExp(r'[^a-z0-9]'),
              '_',
            );
            writeBuildStepLog(
              buildJobId,
              runId,
              'pre_build_setup_$sanitizedJobName',
              message,
            );
          }
          logInfo(buildJobId, runId, '[$jobName] $message');
        }
        return;
      }

      // Fallback for non-JSON lines
      if (trimmed.contains('✅') || trimmed.contains('Job succeeded')) {
        hasSuccessfulStep = true;
      }

      if (isActError(trimmed)) {
        outputErrors.add(trimmed);
      }

      final match = actJobPattern.firstMatch(trimmed);
      String jobName = 'global';
      String cleanLine = trimmed;

      if (match != null) {
        final prefixContent = match.group(1) ?? '';
        final msg = match.group(2) ?? '';
        final slashIndex = prefixContent.lastIndexOf('/');
        jobName = slashIndex != -1
            ? prefixContent.substring(slashIndex + 1).trim()
            : prefixContent.trim();
        cleanLine = msg.replaceFirst(RegExp(r'^\|\s*'), '').trim();
      }

      if (cleanLine.isEmpty) return;

      final state = getJobState(jobName);
      final currentStepId = state['currentStepId'] as String?;
      if (currentStepId != null) {
        writeBuildStepLog(buildJobId, runId, currentStepId, cleanLine);
      } else {
        final sanitizedJobName = jobName.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '_',
        );
        writeBuildStepLog(
          buildJobId,
          runId,
          'pre_build_setup_$sanitizedJobName',
          cleanLine,
        );
      }
      logInfo(buildJobId, runId, '[$jobName] $cleanLine');
    }

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final masked = line.replaceAll(token, '***').trim();
          if (masked.isNotEmpty) {
            processLine(masked);
          }
        }, onDone: () => stdoutCompleter.complete());

    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final masked = line.replaceAll(token, '***').trim();
          if (masked.isNotEmpty) {
            processLine(masked);
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

    await Future.wait([
      stdoutCompleter.future,
      stderrCompleter.future,
    ]).timeout(const Duration(milliseconds: 200), onTimeout: () => []);
    _log.info('Drained streams with 200ms grace period.');

    final exitCode = await exitCodeFuture;
    _log.info('SSH execution completed. Exit code: $exitCode');

    Future<void> closeAllJobs({required String status}) async {
      for (final jName in jobStates.keys) {
        await closeJobCurrentStep(jName, status: status);
      }
    }

    if (isTimedOut) {
      await closeAllJobs(status: 'FAILURE');
      await flushRemainingStepLogs(runId: runId);
      throw TimeoutException(
        'act timed out after ${timeout.inMinutes} minutes',
      );
    }

    if (exitCode != 0) {
      await closeAllJobs(status: 'FAILURE');
      await flushRemainingStepLogs(runId: runId);
      throw Exception('act exited with code $exitCode');
    }

    if (outputErrors.isNotEmpty) {
      await closeAllJobs(status: 'FAILURE');
      await flushRemainingStepLogs(runId: runId);
      throw Exception('act reported errors:\n${outputErrors.join('\n')}');
    }

    if (!hasSuccessfulStep) {
      await closeAllJobs(status: 'FAILURE');
      await flushRemainingStepLogs(runId: runId);
      throw Exception(
        'act exited with code 0 but no steps were executed. '
        'Ensure the workflow file is correct and your workflow/job triggers match.',
      );
    }

    await closeAllJobs(status: 'SUCCESS');
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
