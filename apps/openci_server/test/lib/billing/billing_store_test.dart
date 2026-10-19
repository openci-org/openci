import 'package:drift/native.dart';
import 'package:openci_server/billing/billing_store.dart';
import 'package:openci_server/database.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late BillingStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = BillingStore(db);
  });

  tearDown(() => db.close());

  test('returns null without creating an account', () async {
    expect(await store.get('missing-team'), isNull);
    expect(await db.select(db.billingAccounts).get(), isEmpty);
  });

  test(
    'finds only the requested identity, even without an active team',
    () async {
      const first = BillingAccount(teamId: 'team-1');
      const second = BillingAccount(teamId: 'team-2');
      await db.into(db.billingAccounts).insert(first);
      await db.into(db.billingAccounts).insert(second);

      expect(await store.get('team-1'), first);
      expect(await store.get('team-2'), second);
      expect(await store.get('missing-team'), isNull);
    },
  );
}
