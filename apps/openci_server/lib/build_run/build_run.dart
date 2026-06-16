import 'package:drift/drift.dart';
import 'package:openci_server/build_job/build_job.dart';

@DataClassName('DriftBuildRun')
class BuildRuns extends Table {
  TextColumn get id => text()();
  TextColumn get buildJobId =>
      text().references(BuildJobs, #id, onDelete: KeyAction.cascade)();
  TextColumn get status => text()();
  TextColumn get conclusion => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
