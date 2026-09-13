import 'package:drift/drift.dart';

@DataClassName('DriftWorkerHeartbeat')
class WorkerHeartbeats extends Table {
  TextColumn get id => text()();
  TextColumn get version => text().nullable()();
  TextColumn get platform => text().nullable()();
  TextColumn get status => text().nullable()();
  DateTimeColumn get lastSeenAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
