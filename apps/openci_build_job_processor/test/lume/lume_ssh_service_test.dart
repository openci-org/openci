import 'dart:io';

import 'package:openci_build_job_processor/src/lume/lume_ssh_service.dart';
import 'package:test/test.dart';

class MockLumeSshService extends LumeSshService {
  int mockExitCode = 0;
  int runCount = 0;
  List<String> executedCommands = [];

  @override
  Future<int> runPasswordSsh({
    required String ip,
    required String command,
    required String askPassPath,
  }) async {
    runCount++;
    executedCommands.add(command);
    return mockExitCode;
  }
}

void main() {
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

    test('generateSshKey generates valid SSH key pair files', () async {
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
    });

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
          );
        } catch (e) {
          threw = true;
          expect(e, isA<Exception>());
        }

        expect(threw, isTrue);
        expect(mockService.runCount, equals(5));
      },
    );

    test('runPasswordSsh returns -1 and kills process on timeout', () async {
      sshService.sshTimeout = const Duration(milliseconds: 1);

      final exitCode = await sshService.runPasswordSsh(
        ip: '127.0.0.1',
        command: 'sleep 10',
        askPassPath: '/tmp/non-existent-askpass-path',
      );

      expect(exitCode, equals(-1));
    });
  });
}
