import 'dart:io';

import 'package:cli_util/cli_logging.dart';

import '../../secrets/secrets_api.dart';
import '../../asc/asc_api_key_secret.dart';
import '../../credential_store/credential_config.dart';
import '../../i18n/i18n.dart';
import '../../secrets/fetch_secret_names.dart';

Future<int> ensureIosCertificateKey({
  required AuthProfile profile,
  required Logger logger,
}) async {
  final client = SecretsApi(profile);
  try {
    // Recheck before generation: another setup may have prepared the key.
    // Never overwrite it via saveSecret.
    final names = await fetchSecretNames(client, profile.teamId);
    if (names.contains(iosCertificatePrivateKeySecretName)) {
      logger.stdout(t.setup.iosCertificateKey.reused);
      return 0;
    }

    final response = await client.generateCertificateKey(profile.teamId);
    if (!response.isSuccessful) {
      throw SecretNamesHttpException(response.statusCode);
    }
    final savedNames = await fetchSecretNames(client, profile.teamId);
    if (!savedNames.contains(iosCertificatePrivateKeySecretName)) {
      logger.stderr(t.setup.iosCertificateKey.setupFailed);
      return 1;
    }
    logger.stdout(t.setup.iosCertificateKey.ready);
    return 0;
  } on SecretNamesHttpException catch (error) {
    logger.stderr(
      error.statusCode == HttpStatus.unauthorized ||
              error.statusCode == HttpStatus.forbidden
          ? t.register.secret.loginRequired
          : t.setup.iosCertificateKey.requestFailed(status: error.statusCode),
    );
    return 1;
  } catch (_) {
    // Responses and transport errors can contain credentials or key material.
    logger.stderr(t.setup.iosCertificateKey.setupFailed);
    return 1;
  } finally {
    client.dispose();
  }
}
