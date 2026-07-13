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

  String getSshKeyPath(String runId) => '/tmp/openci-ssh-key-$runId';
  String getAskPassPath(String runId) => '/tmp/openci-askpass-$runId.sh';

  Future<void> setupDirectSsh(LumeVM vm, String runId) async {
    final sshKeyPath = getSshKeyPath(runId);
    final askPassPath = getAskPassPath(runId);
    final keyFile = File(sshKeyPath);
    if (!keyFile.existsSync()) {
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
    final pubKey = File('$sshKeyPath.pub').readAsStringSync().trim();
    final ip = vm.ipAddress;
    if (ip == null) {
      throw StateError('VM IP is null; cannot install SSH key.');
    }

    final askpass = File(askPassPath);
    askpass.writeAsStringSync("#!/bin/sh\nprintf '%s' '$_sshPassword'\n");
    await Process.run('chmod', ['+x', askPassPath]);

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
          '$_sshUser@$ip',
          command,
        ],
        environment: {
          'SSH_ASKPASS': askPassPath,
          'SSH_ASKPASS_REQUIRE': 'force',
          'DISPLAY': ':0',
        },
      );
      await process.stdin.close();
      await process.stdout.drain<void>();
      await process.stderr.drain<void>();
      return process.exitCode;
    }

    final pubKeyB64 = base64Encode(utf8.encode('$pubKey\n'));
    final appendCmd =
        'printf %s \'$pubKeyB64\' | base64 -D >> ~/.ssh/authorized_keys';

    var exitCode = -1;
    for (var attempt = 1; attempt <= 5; attempt++) {
      exitCode = await runPasswordSsh('$installCmd && $appendCmd');
      if (exitCode == 0) break;
      await Future<void>.delayed(const Duration(seconds: 5));
    }

    try {
      askpass.deleteSync();
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }

    if (exitCode != 0) {
      throw Exception('Failed to install SSH key on VM. Exit code: $exitCode');
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
