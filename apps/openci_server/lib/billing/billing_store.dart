import 'package:openci_server/database.dart';

class BillingStore {
  BillingStore(this._db);

  final AppDatabase _db;

  Future<BillingAccount?> get(String teamId) {
    return (_db.select(
      _db.billingAccounts,
    )..where((account) => account.teamId.equals(teamId))).getSingleOrNull();
  }
}
