import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:lume_dart/lume_dart.dart';
import 'package:sentry/sentry.dart';

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

  Future<void> setupDirectSsh(LumeVM vm, String runId) async {
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
    );
  }

  Future<void> installPublicKeyToVm({
    required String ip,
    required String pubKey,
    required String askPassPath,
  }) async {
    await prepareAskPassFile(askPassPath);

    try {
      await installKeyViaPasswordSsh(
        ip: ip,
        pubKey: pubKey,
        askPassPath: askPassPath,
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
  }) async {
    const installCmd =
        'mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys';

    final pubKeyB64 = base64Encode(utf8.encode('$pubKey\n'));
    final appendCmd =
        'printf %s \'$pubKeyB64\' | base64 -D >> ~/.ssh/authorized_keys';

    var exitCode = -1;
    for (var attempt = 1; attempt <= 5; attempt++) {
      exitCode = await runPasswordSsh(
        ip: ip,
        command: '$installCmd && $appendCmd',
        askPassPath: askPassPath,
      );
      if (exitCode == 0) break;
      await Future<void>.delayed(retryDelay);
    }

    if (exitCode != 0) {
      throw Exception('Failed to install SSH key on VM. Exit code: $exitCode');
    }
  }

  Future<int> runPasswordSsh({
    required String ip,
    required String command,
    required String askPassPath,
  }) async {
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
        '$_sshUser@$ip',
        command,
      ],
      environment: {
        'SSH_ASKPASS': askPassPath,
        'SSH_ASKPASS_REQUIRE': 'force',
        'DISPLAY': ':0',
      },
    );

    try {
      return await () async {
        await process.stdin.close();
        await process.stdout.drain<void>();
        await process.stderr.drain<void>();
        return await process.exitCode;
      }().timeout(sshTimeout);
    } on TimeoutException {
      process.kill();
      return -1;
    }
  }

  Future<int> executeSshCommand({
    required String ip,
    required String runId,
    required String command,
  }) async {
    final sshKeyPath = getSshKeyPath(runId);
    final process = await Process.start('/usr/bin/ssh', [
      ..._sshBaseOpts,
      '-i',
      sshKeyPath,
      '$_sshUser@$ip',
      command,
    ]);

    try {
      return await () async {
        await process.stdin.close();
        await process.stdout.drain<void>();
        await process.stderr.drain<void>();
        return await process.exitCode;
      }().timeout(sshTimeout);
    } on TimeoutException {
      process.kill();
      return -1;
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
}
