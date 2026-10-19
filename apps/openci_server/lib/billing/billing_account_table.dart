import 'package:drift/drift.dart';

@DataClassName('BillingAccount')
class BillingAccounts extends Table {
  // No team foreign key: retain billing identity after team deletion.
  TextColumn get teamId => text()();

  @override
  Set<Column> get primaryKey => {teamId};
}
