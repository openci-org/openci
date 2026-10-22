import 'package:drift/drift.dart';

@DataClassName('BillingAccount')
class BillingAccounts extends Table {
  TextColumn get teamId => text()();

  @override
  Set<Column> get primaryKey => {teamId};
}
