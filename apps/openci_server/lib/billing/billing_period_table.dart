import 'package:drift/drift.dart';
import 'package:openci_server/billing/billing_account_table.dart';

@DataClassName('BillingPeriod')
class BillingPeriods extends Table {
  TextColumn get id => text()();
  TextColumn get teamId => text().references(BillingAccounts, #teamId)();
  TextColumn get planId => text()();
  TextColumn get periodType => text()();
  // Drift stores these instants as Unix seconds in both PostgreSQL and SQLite.
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get endsAt => dateTime()();
  IntColumn get allowanceSeconds => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (plan_id IN ('light', 'pro'))",
    "CHECK (period_type IN ('trial', 'paid'))",
    'CHECK (ends_at > starts_at)',
    'CHECK (allowance_seconds IS NULL OR allowance_seconds >= 0)',
    "CHECK (period_type = 'trial' OR allowance_seconds IS NOT NULL)",
  ];
}
