import 'dart:io';

String loadDatabaseUrl() {
  final appEnv = Platform.environment['APP_ENV'] ?? 'development';
  final databaseUrlEnv = Platform.environment['DATABASE_URL'];

  if (databaseUrlEnv == null && appEnv == 'production') {
    throw StateError(
      'DATABASE_URL environment variable must be specified in production.',
    );
  }

  final url =
      databaseUrlEnv ?? 'postgres://postgres:password@localhost:5432/openci';
  if (databaseUrlEnv == null) {
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

  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

  return (ip: ip, port: port);
}
