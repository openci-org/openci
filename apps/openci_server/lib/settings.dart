import 'dart:io';

String loadDatabaseUrl() {
  final appEnv = Platform.environment['APP_ENV'] ?? 'development';
  final databaseUrlEnv = Platform.environment['DATABASE_URL'];

  final isDatabaseUrlMissing =
      databaseUrlEnv == null || databaseUrlEnv.trim().isEmpty;

  if (isDatabaseUrlMissing && appEnv == 'production') {
    throw StateError(
      'DATABASE_URL environment variable must be specified in production.',
    );
  }

  final url = isDatabaseUrlMissing
      ? 'postgres://postgres:password@localhost:5432/openci'
      : databaseUrlEnv;

  if (isDatabaseUrlMissing) {
    stdout.writeln(
      'Warning: DATABASE_URL is missing. Falling back to local development URL.',
    );
  }

  return url;
}

({InternetAddress ip, int port}) loadServerSettings() {
  final ip = Platform.environment['HOST'] == 'any'
      ? InternetAddress.anyIPv4
      : InternetAddress.loopbackIPv4;

  final parsedPort = int.tryParse(Platform.environment['PORT'] ?? '');
  final port = (parsedPort != null && parsedPort >= 1 && parsedPort <= 65535)
      ? parsedPort
      : 8080;

  return (ip: ip, port: port);
}
