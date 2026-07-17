import 'dart:io';

import 'package:openci_build_job_processor/src/lume/lume_ssh_service.dart';
import 'package:test/test.dart';

class MockLumeSshService extends LumeSshService {
  int mockExitCode = 0;
  int runCount = 0;
  List<String> executedCommands = [];

  @override
  Future<SshResult> runPasswordSsh({
    required String ip,
    required String command,
    required String askPassPath,
    String? jumpHost,
  }) async {
    runCount++;
    executedCommands.add(command);
    return SshResult(
      exitCode: mockExitCode,
      stdout: '',
      stderr: mockExitCode != 0 ? 'Mock SSH failure details' : '',
    );
  }
}

Future<bool> _hasCommand(String command) async {
  try {
    final result = Platform.isWindows
        ? await Process.run('where', [command])
        : await Process.run('which', [command]);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

void main() async {
  final hasSshKeygen = await _hasCommand('ssh-keygen');
  final hasSsh = File('/usr/bin/ssh').existsSync() || await _hasCommand('ssh');
  final hasScp = File('/usr/bin/scp').existsSync() || await _hasCommand('scp');

  group('LumeSshService', () {
    late LumeSshService sshService;
    const testRunId = 'test-run-123';

    setUp(() {
      sshService = LumeSshService();
    });

    test('getSshKeyPath returns correct path', () {
      final path = sshService.getSshKeyPath(testRunId);
      expect(path, equals('/tmp/openci-ssh-key-test-run-123'));
    });

    test('getAskPassPath returns correct path', () {
      final path = sshService.getAskPassPath(testRunId);
      expect(path, equals('/tmp/openci-askpass-test-run-123.sh'));
    });

    test('cleanupTempSshKeys deletes files if they exist', () {
      final keyPath = sshService.getSshKeyPath(testRunId);
      final pubKeyPath = '$keyPath.pub';
      final askPassPath = sshService.getAskPassPath(testRunId);

      // Create dummy files
      File(keyPath).writeAsStringSync('dummy-key');
      File(pubKeyPath).writeAsStringSync('dummy-pub');
      File(askPassPath).writeAsStringSync('dummy-askpass');

      expect(File(keyPath).existsSync(), isTrue);
      expect(File(pubKeyPath).existsSync(), isTrue);
      expect(File(askPassPath).existsSync(), isTrue);

      // Cleanup
      sshService.cleanupTempSshKeys(testRunId);

      expect(File(keyPath).existsSync(), isFalse);
      expect(File(pubKeyPath).existsSync(), isFalse);
      expect(File(askPassPath).existsSync(), isFalse);
    });

    test(
      'cleanupTempSshKeys completes without exception when files do not exist',
      () {
        expect(() => sshService.cleanupTempSshKeys(testRunId), returnsNormally);
      },
    );

    test(
      'generateSshKey generates valid SSH key pair files',
      () async {
        final keyPath = sshService.getSshKeyPath(testRunId);
        final pubKeyPath = '$keyPath.pub';

        // Ensure files do not exist beforehand
        if (File(keyPath).existsSync()) File(keyPath).deleteSync();
        if (File(pubKeyPath).existsSync()) File(pubKeyPath).deleteSync();

        try {
          await sshService.generateSshKey(keyPath);

          expect(File(keyPath).existsSync(), isTrue);
          expect(File(pubKeyPath).existsSync(), isTrue);

          // Verify the private key content starts with the standard header
          final privateKeyContent = File(keyPath).readAsStringSync();
          expect(privateKeyContent, contains('BEGIN OPENSSH PRIVATE KEY'));

          // Verify public key starts with key type
          final publicKeyContent = File(pubKeyPath).readAsStringSync();
          expect(publicKeyContent, startsWith('ssh-ed25519'));
        } finally {
          // Cleanup after test
          sshService.cleanupTempSshKeys(testRunId);
        }
      },
      skip: hasSshKeygen ? null : 'ssh-keygen command not available',
    );

    test(
      'generateSshKey deletes existing keys and generates a new pair',
      () async {
        final keyPath = sshService.getSshKeyPath(testRunId);
        final pubKeyPath = '$keyPath.pub';

        // Create dummy files beforehand
        File(keyPath).writeAsStringSync('old-dummy-private-key');
        File(pubKeyPath).writeAsStringSync('old-dummy-public-key');

        expect(
          File(keyPath).readAsStringSync(),
          equals('old-dummy-private-key'),
        );
        expect(
          File(pubKeyPath).readAsStringSync(),
          equals('old-dummy-public-key'),
        );

        try {
          await sshService.generateSshKey(keyPath);

          expect(File(keyPath).existsSync(), isTrue);
          expect(File(pubKeyPath).existsSync(), isTrue);

          // Check that old files are overwritten and contain new ed25519 keys
          final privateKeyContent = File(keyPath).readAsStringSync();
          expect(privateKeyContent, isNot(equals('old-dummy-private-key')));
          expect(privateKeyContent, contains('BEGIN OPENSSH PRIVATE KEY'));

          final publicKeyContent = File(pubKeyPath).readAsStringSync();
          expect(publicKeyContent, isNot(equals('old-dummy-public-key')));
          expect(publicKeyContent, startsWith('ssh-ed25519'));
        } finally {
          sshService.cleanupTempSshKeys(testRunId);
        }
      },
      skip: hasSshKeygen ? null : 'ssh-keygen command not available',
    );

    test(
      'prepareAskPassFile creates askpass file with executable permissions and correct password',
      () async {
        final askPassPath = sshService.getAskPassPath(testRunId);

        if (File(askPassPath).existsSync()) File(askPassPath).deleteSync();

        try {
          await sshService.prepareAskPassFile(askPassPath);

          final file = File(askPassPath);
          expect(file.existsSync(), isTrue);

          // Verify content contains password
          final content = file.readAsStringSync();
          expect(content, contains('admin'));
          expect(content, startsWith('#!/bin/sh'));

          // Verify executable permission (non-Windows check)
          if (!Platform.isWindows) {
            final result = await Process.run('test', ['-x', askPassPath]);
            expect(
              result.exitCode,
              equals(0),
              reason: 'File should be executable',
            );
          }
        } finally {
          sshService.cleanupTempSshKeys(testRunId);
        }
      },
    );

    test('deleteAskPassFile deletes the file successfully', () {
      final askPassPath = sshService.getAskPassPath(testRunId);
      final file = File(askPassPath);

      file.writeAsStringSync('dummy-askpass-content');
      expect(file.existsSync(), isTrue);

      sshService.deleteAskPassFile(askPassPath);
      expect(file.existsSync(), isFalse);
    });

    test(
      'deleteAskPassFile completes without exception when file does not exist',
      () {
        final askPassPath = sshService.getAskPassPath(testRunId);
        final file = File(askPassPath);
        if (file.existsSync()) file.deleteSync();

        expect(
          () => sshService.deleteAskPassFile(askPassPath),
          returnsNormally,
        );
      },
    );

    test(
      'installKeyViaPasswordSsh completes successfully on first attempt when exitCode is 0',
      () async {
        final mockService = MockLumeSshService();
        mockService.mockExitCode = 0;
        mockService.retryDelay = Duration.zero;

        await mockService.installKeyViaPasswordSsh(
          ip: '127.0.0.1',
          pubKey: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...',
          askPassPath: '/tmp/dummy-askpass',
          vmName: 'test-vm',
          runId: 'test-run',
        );

        expect(mockService.runCount, equals(1));
        expect(mockService.executedCommands.first, contains('authorized_keys'));
      },
    );

    test(
      'installKeyViaPasswordSsh retries and throws exception when all attempts fail',
      () async {
        final mockService = MockLumeSshService();
        mockService.mockExitCode = 1; // Always fail
        mockService.retryDelay = Duration.zero; // Speed up test

        var threw = false;
        try {
          await mockService.installKeyViaPasswordSsh(
            ip: '127.0.0.1',
            pubKey: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...',
            askPassPath: '/tmp/dummy-askpass',
            vmName: 'test-vm',
            runId: 'test-run',
          );
        } catch (e) {
          threw = true;
          expect(e, isA<Exception>());
          final msg = e.toString();
          expect(msg, contains('VM: test-vm (127.0.0.1)'));
          expect(msg, contains('Run ID: test-run'));
          expect(msg, contains('Worker Host:'));
          expect(msg, contains('Exit code: 1'));
          expect(msg, contains('Error: Mock SSH failure details'));
        }

        expect(threw, isTrue);
        expect(mockService.runCount, equals(30));
      },
    );

    test(
      'runPasswordSsh returns -1 and kills process on timeout',
      () async {
        sshService.sshTimeout = const Duration(milliseconds: 1);

        final result = await sshService.runPasswordSsh(
          ip: '127.0.0.1',
          command: 'sleep 10',
          askPassPath: '/tmp/non-existent-askpass-path',
        );

        expect(result.exitCode, equals(-1));
        expect(result.stderr, contains('timed out'));
      },
      skip: hasSsh ? null : 'ssh command not available',
    );

    test(
      'executeSshCommand returns non-zero on connection failure',
      () async {
        final exitCode = await sshService.executeSshCommand(
          ip: '127.0.0.1',
          runId: testRunId,
          command: 'echo hello',
        );
        expect(exitCode, isNot(equals(0)));
      },
      skip: hasSsh ? null : 'ssh command not available',
    );

    test(
      'executeSshCommand returns -1 and kills process on timeout',
      () async {
        sshService.sshTimeout = const Duration(milliseconds: 1);

        final exitCode = await sshService.executeSshCommand(
          ip: '127.0.0.1',
          runId: testRunId,
          command: 'sleep 10',
        );

        expect(exitCode, equals(-1));
      },
      skip: hasSsh ? null : 'ssh command not available',
    );

    test(
      'writeFileToVm throws exception on scp failure',
      () async {
        expect(
          () async => await sshService.writeFileToVm(
            ip: '127.0.0.1',
            runId: testRunId,
            remotePath: '/tmp/dummy',
            content: 'dummy-content',
          ),
          throwsA(isA<Exception>()),
        );
      },
      skip: hasScp ? null : 'scp command not available',
    );

    test(
      'clearArpCache executes sudo arp -d -a command on Lume host',
      () async {
        final mockService = MockLumeSshService();
        mockService.mockExitCode = 0;

        await mockService.clearArpCache(
          jumpHost: '100.112.30.120',
          runId: 'test-run',
        );

        expect(mockService.runCount, equals(1));
        expect(
          mockService.executedCommands.first,
          contains('sudo -S arp -d -a'),
        );
      },
    );
  });
}
