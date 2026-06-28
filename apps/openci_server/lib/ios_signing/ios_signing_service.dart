import 'dart:io';

import 'package:openci_server/database.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:openci_server/secret/secret_table.dart';

class IosSigningService {
  static Future<String> generatePrivateKey() async {
    final result = await Process.run('openssl', ['genrsa', '2048']);
    if (result.exitCode != 0) {
      throw ProcessException(
        'openssl',
        ['genrsa', '2048'],
        'openssl genrsa failed: ${result.stderr}',
      );
    }

    final privateKeyPem = result.stdout.toString().trim();
    if (privateKeyPem.isEmpty) {
      throw const FormatException('Generated private key is empty');
    }

    return privateKeyPem;
  }

  static Future<void> saveAscApiKey(
    AppDatabase db,
    String teamId,
    SecretCrypter crypter, {
    required String issuerId,
    required String keyId,
    required String privateKey,
  }) async {
    final now = DateTime.now().toUtc();

    final secretsToSave = {
      'OPENCI_ASC_ISSUER_ID': issuerId.trim(),
      'OPENCI_ASC_KEY_ID': keyId.trim(),
      'OPENCI_ASC_PRIVATE_KEY': privateKey.trim(),
    };

    for (final entry in secretsToSave.entries) {
      final encryptedValue = await crypter.encrypt(entry.value);
      final driftSecret = DriftSecret(
        name: entry.key,
        teamId: teamId,
        encryptedValue: encryptedValue,
        createdAt: now,
        updatedAt: now,
      );
      await db.secretDao.insertOrUpdateSecret(driftSecret);
    }
  }
}
