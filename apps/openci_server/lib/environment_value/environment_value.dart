import 'dart:io';

import 'package:riverpod/riverpod.dart';

final environmentValueProvider = Provider<EnvironmentValue>((ref) {
  return EnvironmentValue.load();
});

class StorageSettings {
  final String endPoint;
  final int port;
  final bool useSSL;
  final String accessKey;
  final String secretKey;
  final String bucket;

  const StorageSettings({
    required this.endPoint,
    required this.port,
    required this.useSSL,
    required this.accessKey,
    required this.secretKey,
    required this.bucket,
  });
}

class EnvironmentValue {
  final InternetAddress host;
  final int port;
  final String databaseUrl;
  final String secretEncryptionKey;
  final String appEnv;
  final String? googleServiceAccount;
  final StorageSettings storage;

  const EnvironmentValue({
    required this.host,
    required this.port,
    required this.databaseUrl,
    required this.secretEncryptionKey,
    required this.appEnv,
    required this.googleServiceAccount,
    required this.storage,
  });

  factory EnvironmentValue.load({Map<String, String>? environment}) {
    final env = environment ?? Platform.environment;

    final ip = env['HOST'] == 'any'
        ? InternetAddress.anyIPv4
        : InternetAddress.loopbackIPv4;
    final parsedPort = int.tryParse(env['PORT'] ?? '');
    final port = (parsedPort != null && parsedPort >= 1 && parsedPort <= 65535)
        ? parsedPort
        : 8080;

    final databaseUrl = env['DATABASE_URL'];
    if (databaseUrl == null || databaseUrl.trim().isEmpty) {
      throw StateError('DATABASE_URL environment variable must be specified.');
    }

    final encryptionKey = env['SECRET_ENCRYPTION_KEY'];
    if (encryptionKey == null || encryptionKey.trim().isEmpty) {
      throw StateError(
        'SECRET_ENCRYPTION_KEY environment variable is missing.',
      );
    }

    final appEnv = env['APP_ENV'] ?? 'development';

    final googleServiceAccount = env['GOOGLE_SERVICE_ACCOUNT'];

    final endpointEnv = env['S3_ENDPOINT'] ?? 'http://localhost:18000';
    final accessKeyEnv = env['S3_ACCESS_KEY'] ?? 'dummy_access_key';
    final secretKeyEnv = env['S3_SECRET_KEY'] ?? 'dummy_secret_key';
    final bucketEnv = env['S3_BUCKET'] ?? 'openci';

    final trimmedEndpoint = endpointEnv.trim();
    if (trimmedEndpoint.isEmpty) {
      throw StateError('Invalid S3_ENDPOINT format: $endpointEnv');
    }

    final String normalizedEndpoint;
    if (trimmedEndpoint.startsWith('http://') ||
        trimmedEndpoint.startsWith('https://')) {
      normalizedEndpoint = trimmedEndpoint;
    } else {
      normalizedEndpoint = 'http://$trimmedEndpoint';
    }

    final uri = Uri.parse(normalizedEndpoint);
    if (uri.host.isEmpty || uri.host.trim().isEmpty) {
      throw StateError('Invalid S3_ENDPOINT format: $endpointEnv');
    }

    final endPoint = uri.host;
    final storagePort = uri.hasPort
        ? uri.port
        : (uri.scheme == 'https' ? 443 : 80);
    final useSSL = uri.scheme == 'https';

    final storage = StorageSettings(
      endPoint: endPoint,
      port: storagePort,
      useSSL: useSSL,
      accessKey: accessKeyEnv,
      secretKey: secretKeyEnv,
      bucket: bucketEnv,
    );

    return EnvironmentValue(
      host: ip,
      port: port,
      databaseUrl: databaseUrl,
      secretEncryptionKey: encryptionKey,
      appEnv: appEnv,
      googleServiceAccount: googleServiceAccount,
      storage: storage,
    );
  }
}
