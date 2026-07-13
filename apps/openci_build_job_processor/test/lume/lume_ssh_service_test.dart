import 'dart:io';

import 'package:openci_build_job_processor/src/lume/lume_ssh_service.dart';
import 'package:test/test.dart';

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
  });
}
