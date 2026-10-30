import assert from "node:assert/strict";
import { test } from "node:test";
import { billingTables, billingRow, migrateBilling } from "../../lib/functions/billing/migrate.js";
import { legacyBillingRows } from "./helpers/legacy_billing.mjs";

function fixture() {
  const rows = legacyBillingRows("team");
  const scan = async (visit) => {
    for (const table of billingTables) await visit(table, rows[table.type]);
  };
  const saved = new Map();
  const target = {
    get: async (table) => saved.get(table.type),
    insert: async (table, row) => {
      saved.set(table.type, row);
    },
  };
  return { rows, scan, saved, target };
}

test("billing migration defaults to dry run and preserves purchases, integer precision and consumed usage", async () => {
  const f = fixture();
  // Above Number.MAX_SAFE_INTEGER: never parse Int64 ledger values as double.
  f.rows.BillingPeriod.allowance_seconds = "9007199254740993";
  assert.equal((await migrateBilling(f.scan, f.target)).dryRun, true);
  assert.equal(f.saved.size, 0);
  assert.equal((await migrateBilling(f.scan, f.target, true)).inserted, 9);
  assert.equal(f.saved.get("BillingPeriod").allowanceSeconds, "9007199254740993");
  assert.equal(f.saved.get("BillingCheckoutCreation").openTeamId, "team");
  assert.equal(f.saved.get("BillingCustomerCreation").idempotencyKey, "team-customer-key");
  assert.equal(f.saved.get("BillingStripeState").paidPeriodId, "stripe:team-invoice");
  assert.equal(f.saved.get("BillingExecution").finishedAtMs, "2000");
  assert.equal(f.saved.get("BillingAdmission").openJobId, null);
  assert.equal(f.saved.get("BillingStripeState").revision, "0");
  assert.equal((await migrateBilling(f.scan, f.target, true)).unchanged, 9);
});

test("preflight rejects conflicts and undrained work before any inserts", async () => {
  for (const change of [
    (f) => {
      f.rows.BillingAdmission.closed_at_ms = null;
    },
    (f) => {
      f.rows.BillingExecution.finished_at_ms = null;
    },
    (f) => {
      f.rows.BillingPeriod.allowance_seconds = Number.MAX_SAFE_INTEGER + 1;
    },
    (f) => {
      f.saved.set("BillingStripeState", { teamId: "team", revision: "10" });
    },
  ]) {
    const f = fixture();
    let inserts = 0;
    f.target.insert = async () => {
      inserts++;
    };
    change(f);
    await assert.rejects(migrateBilling(f.scan, f.target, true));
    assert.equal(inserts, 0);
  }
});

test("an insert with a lost reply is verified; a missing or conflicting write stops the import", async () => {
  const f = fixture();
  f.target.insert = async (table, row) => {
    f.saved.set(table.type, row);
    throw Error("lost reply");
  };
  assert.equal((await migrateBilling(f.scan, f.target, true)).inserted, 9);
  for (const conflict of [false, true]) {
    const other = fixture();
    other.target.insert = async (table, row) => {
      if (conflict) other.saved.set(table.type, { ...row, usageRevision: "9" });
      throw Error("write failed");
    };
    await assert.rejects(migrateBilling(other.scan, other.target, true), /verification failed/);
  }
});

test("closed Checkout imports cannot occupy the team's open purchase slot", () => {
  const table = billingTables.find((t) => t.type === "BillingCheckoutCreation");
  const source = { ...legacyBillingRows("team").BillingCheckoutCreation, closed_at: "2" };
  assert.equal(billingRow(table, source).openTeamId, null);
});
