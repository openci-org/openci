import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/ios_signing/ios_signing_service.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:test/test.dart';

void main() {
  group('IosSigningService', () {
    test('generatePrivateKey generates a valid RSA private key PEM', () async {
      final key = await IosSigningService.generatePrivateKey();
      expect(key, isNotEmpty);
      expect(key, contains('-----BEGIN PRIVATE KEY-----'));
      expect(key, contains('-----END PRIVATE KEY-----'));
    });

    test(
      'saveAscApiKey encrypts and saves issuerId, keyId, and privateKey',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        const encryptionKey = 'cTN0Nnc5eiRDJkYpSkBOY1FmVGZXblpyNHU3eCFBJUQ=';
        final crypter = SecretCrypter(encryptionKey);

        await IosSigningService.saveAscApiKey(
          db,
          'team-123',
          crypter,
          issuerId: 'issuer-abc',
          keyId: 'key-xyz',
          privateKey: 'private-key-pem',
        );

        final issuerSecret = await db.secretDao.getSecret(
          'team-123',
          'OPENCI_ASC_ISSUER_ID',
        );
        expect(issuerSecret, isNotNull);
        expect(
          await crypter.decrypt(issuerSecret!.encryptedValue),
          equals('issuer-abc'),
        );

        final keyIdSecret = await db.secretDao.getSecret(
          'team-123',
          'OPENCI_ASC_KEY_ID',
        );
        expect(keyIdSecret, isNotNull);
        expect(
          await crypter.decrypt(keyIdSecret!.encryptedValue),
          equals('key-xyz'),
        );

        final privateKeySecret = await db.secretDao.getSecret(
          'team-123',
          'OPENCI_ASC_PRIVATE_KEY',
        );
        expect(privateKeySecret, isNotNull);
        expect(
          await crypter.decrypt(privateKeySecret!.encryptedValue),
          equals('private-key-pem'),
        );

        await db.close();
      },
    );
  });
}
