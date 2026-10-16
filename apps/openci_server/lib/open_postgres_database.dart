import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart' as pg;

QueryExecutor openPostgresDatabase(String databaseUrl) => LazyDatabase(
  () async => _OwnedPgDatabase(await pg.Connection.openFromUrl(databaseUrl)),
  dialect: SqlDialect.postgres,
);

class _OwnedPgDatabase extends PgDatabase {
  _OwnedPgDatabase(this.connection) : super.opened(connection);

  final pg.Connection connection;

  @override
  Future<void> close() async {
    try {
      await super.close();
    } finally {
      await connection.close();
    }
  }
}
