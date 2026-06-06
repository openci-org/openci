import 'dart:io';

import 'package:postgres/postgres.dart';

class DatabaseManager {
  late final Pool pool;

  DatabaseManager(String databaseUrl) {
    pool = Pool.withEndpoints(
      [parseEndpoint(databaseUrl)],
      settings: const PoolSettings(
        maxConnectionCount: 5,
        sslMode: SslMode.disable,
      ),
    );
  }

  static Endpoint parseEndpoint(String databaseUrl) {
    final uri = Uri.parse(databaseUrl);
    final userInfo = uri.userInfo.split(':');
    final username = userInfo.isNotEmpty && userInfo[0].isNotEmpty
        ? userInfo[0]
        : null;
    final password = userInfo.length > 1 && userInfo[1].isNotEmpty
        ? userInfo[1]
        : null;
    final dbName = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;

    return Endpoint(
      host: uri.host,
      port: uri.port > 0 ? uri.port : 5432,
      database: dbName,
      username: username,
      password: password,
    );
  }

  Future<bool> verifyConnection() async {
    try {
      final result = await pool.execute('SELECT 1');
      return result.isNotEmpty;
    } catch (e) {
      stderr.writeln('Database connection validation failed: $e');
      return false;
    }
  }

  Future<void> close() async {
    await pool.close();
  }
}
