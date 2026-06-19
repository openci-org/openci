import 'package:drift/drift.dart';

@DataClassName('DriftProcessedWebhook')
class ProcessedWebhooks extends Table {
  TextColumn get deliveryId => text()();
  DateTimeColumn get processedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {deliveryId};
}
