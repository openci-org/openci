import 'dart:convert';
import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:openci_workflow/src/ios_signing/write_ios_signing_secrets.dart';
import 'package:test/test.dart';

void main() {
  group('writeIosSigningSecrets', () {
    const ascPrivateKey =
        '-----BEGIN PRIVATE KEY-----\n'
        'TEST_ASC_KEY\n'
        '-----END PRIVATE KEY-----\n';
    const certificatePrivateKey =
        '-----BEGIN RSA PRIVATE KEY-----\n'
        'TEST_CERTIFICATE_KEY\n'
        '-----END RSA PRIVATE KEY-----\n';
    late Directory temporaryDirectory;

    setUp(() async {
      temporaryDirectory = await Directory.systemTemp.createTemp(
        'openci signing secrets ',
      );
    });

    tearDown(() => temporaryDirectory.delete(recursive: true));

    writeSecrets({
      String issuerId = 'test-issuer-id',
      String keyId = 'TESTKEYID',
      String? privateKeyBase64,
      String certificateKey = certificatePrivateKey,
    }) => IOOverrides.runZoned(
      () => writeIosSigningSecrets(
        ascKeys: AppStoreConnectKeys(
          issuerId: issuerId,
          keyId: keyId,
          privateKeyBase64:
              privateKeyBase64 ?? base64Encode(utf8.encode(ascPrivateKey)),
        ),
        certificatePrivateKey: certificateKey,
      ),
      getSystemTempDirectory: () => temporaryDirectory,
    );

    test('keeps IDs as strings and writes only the two private keys', () async {
      final credentials = await writeSecrets();

      expect(credentials.issuerId, 'test-issuer-id');
      expect(credentials.keyId, 'TESTKEYID');
      expect(
        await File(credentials.ascPrivateKeyPath).readAsString(),
        ascPrivateKey,
      );
      expect(
        await File(credentials.certificatePrivateKeyPath).readAsString(),
        certificatePrivateKey,
      );
      final directory = Directory.fromUri(
        temporaryDirectory.uri.resolve('openci-ios-signing/'),
      );
      expect(
        (await directory.list().toList()).map(
          (file) => file.uri.pathSegments.last,
        ),
        unorderedEquals([
          'asc-private-key.p8',
          'certificate-private-key.pem',
        ]),
      );
      expect((await directory.stat()).mode & 0x1ff, 0x1c0);
      for (final path in [
        credentials.ascPrivateKeyPath,
        credentials.certificatePrivateKeyPath,
      ]) {
        expect((await File(path).stat()).mode & 0x1ff, 0x180);
      }
    });

    test('restores certificate key newlines escaped by the server', () async {
      final credentials = await writeSecrets(
        certificateKey: certificatePrivateKey.replaceAll('\n', r'\n'),
      );

      expect(
        await File(credentials.certificatePrivateKeyPath).readAsString(),
        certificatePrivateKey,
      );
    });

    test('overwrites fixed files without leaving old bytes', () async {
      final previous = await writeSecrets();

      final credentials = await writeSecrets(
        issuerId: 'new',
        keyId: 'KEY',
        privateKeyBase64: base64Encode(utf8.encode('new ASC key')),
        certificateKey: 'new certificate key',
      );

      expect(credentials.ascPrivateKeyPath, previous.ascPrivateKeyPath);
      expect(
        credentials.certificatePrivateKeyPath,
        previous.certificatePrivateKeyPath,
      );
      expect(credentials.issuerId, 'new');
      expect(credentials.keyId, 'KEY');
      expect(previous.issuerId, 'test-issuer-id');
      expect(previous.keyId, 'TESTKEYID');
      expect(
        await File(credentials.ascPrivateKeyPath).readAsString(),
        'new ASC key',
      );
      expect(
        await File(credentials.certificatePrivateKeyPath).readAsString(),
        'new certificate key',
      );
    });

    for (final filesExist in [false, true]) {
      test(
        'invalid Base64 does not write files or expose the secret: $filesExist',
        () async {
          final previous = filesExist ? await writeSecrets() : null;

          await expectLater(
            writeSecrets(
              issuerId: 'replacement issuer',
              keyId: 'replacement key',
              privateKeyBase64: 'secret-private-key!!!',
              certificateKey: 'replacement certificate key',
            ),
            throwsA(
              isA<FormatException>()
                  .having((error) => error.source, 'source', isNull)
                  .having(
                    (error) => error.toString(),
                    'diagnostic',
                    isNot(contains('secret-private-key')),
                  ),
            ),
          );

          if (previous == null) {
            expect(await temporaryDirectory.list().toList(), isEmpty);
          } else {
            expect(previous.issuerId, 'test-issuer-id');
            expect(previous.keyId, 'TESTKEYID');
            expect(
              await File(previous.ascPrivateKeyPath).readAsString(),
              ascPrivateKey,
            );
            expect(
              await File(previous.certificatePrivateKeyPath).readAsString(),
              certificatePrivateKey,
            );
          }
        },
      );
    }

    test('propagates a filesystem failure', () async {
      final blockingFile = File.fromUri(
        temporaryDirectory.uri.resolve('openci-ios-signing'),
      );
      await blockingFile.writeAsString('keep');

      await expectLater(writeSecrets(), throwsA(isA<FileSystemException>()));

      expect(await blockingFile.readAsString(), 'keep');
    });
  }, testOn: '!windows');
}
