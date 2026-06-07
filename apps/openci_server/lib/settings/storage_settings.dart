import 'dart:io';

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

StorageSettings loadStorageSettings({Map<String, String>? environment}) {
  final env = environment ?? Platform.environment;
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
  final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
  final useSSL = uri.scheme == 'https';

  return StorageSettings(
    endPoint: endPoint,
    port: port,
    useSSL: useSSL,
    accessKey: accessKeyEnv,
    secretKey: secretKeyEnv,
    bucket: bucketEnv,
  );
}
