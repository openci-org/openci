import 'dart:io';

String loadDatabaseUrl({Map<String, String>? environment}) {
  final env = environment ?? Platform.environment;
  final appEnv = env['APP_ENV'] ?? 'development';
  final databaseUrlEnv = env['DATABASE_URL'];

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
