import 'package:drift/drift.dart';

@DataClassName('DriftWebhookTask')
class WebhookTasks extends Table {
  TextColumn get id => text()();
  TextColumn get deliveryId => text().unique()();
  TextColumn get eventType => text()();
  TextColumn get payload => text()();
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
