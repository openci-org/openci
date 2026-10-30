// Operator-only, insert-only migration. Billing writers must be stopped first.
// The default dry run reads both databases and never logs purchase identifiers.
import { initializeApp, getApps, deleteApp } from "firebase-admin/app";
import type { DataConnect } from "firebase-admin/data-connect";
import { Client, type QueryResult } from "pg";
import { connectorConfig } from "@openci/billing-admin";
import { isolatedConnector } from "../executor/store.js";

type Row = Record<string, string | boolean | null>;
type Table = { type: string; sql: string; fields: string[]; defaults?: Row };
// Order is significant: historical accounts survive deleted teams; usage rows
// refer to those accounts and periods, not to legacy build-job foreign keys.
export const billingTables: Table[] = [
  {
    type: "BillingAccount",
    sql: "billing_accounts",
    fields: ["teamId"],
    defaults: { usageRevision: "0" },
  },
  {
    type: "BillingPeriod",
    sql: "billing_periods",
    fields: ["id", "teamId", "planId", "periodType", "startsAt", "endsAt", "allowanceSeconds"],
  },
  {
    type: "BillingTrialClaim",
    sql: "billing_trial_claims",
    fields: ["userId", "teamId", "claimedAt"],
  },
  {
    type: "BillingCustomerCreation",
    sql: "billing_customer_creations",
    fields: ["teamId", "idempotencyKey", "livemode", "createdAt", "stripeCustomerId"],
  },
  {
    type: "BillingCheckoutCreation",
    sql: "billing_checkout_creations",
    fields: [
      "idempotencyKey",
      "teamId",
      "planId",
      "stripeCustomerId",
      "stripePriceId",
      "successUrl",
      "cancelUrl",
      "livemode",
      "createdAt",
      "stripeCheckoutSessionId",
      "closedAt",
    ],
  },
  {
    type: "BillingStripeState",
    sql: "billing_stripe_state",
    fields: [
      "teamId",
      "stripeCustomerId",
      "livemode",
      "stripeSubscriptionId",
      "subscriptionStatus",
      "planId",
      "paidPeriodId",
      "cancelAtPeriodEnd",
      "syncedAt",
    ],
    defaults: { revision: "0" },
  },
  {
    type: "BillingAdmission",
    sql: "billing_admissions",
    fields: [
      "id",
      "jobId",
      "teamId",
      "workerHost",
      "periodId",
      "claimedAtMs",
      "startByMs",
      "reservedMillis",
      "runId",
      "closedAtMs",
    ],
    defaults: { openJobId: null },
  },
  {
    type: "BillingExecution",
    sql: "billing_executions",
    fields: [
      "runId",
      "teamId",
      "jobId",
      "workerHost",
      "periodId",
      "startedAtMs",
      "observedAtMs",
      "leaseUntilMs",
      "finishedAtMs",
      "outcome",
      "measurementIncomplete",
    ],
  },
  {
    type: "BillingStripeEvent",
    sql: "billing_stripe_events",
    fields: ["eventId", "eventType", "eventCreated", "processedAt"],
  },
];
const column = (field: string) => field.replace(/[A-Z]/g, (c) => "_" + c.toLowerCase());
const integer = /(?:At|Ms|Seconds|Millis|Revision|revision|eventCreated)$/;

export function billingRow(table: Table, source: Record<string, unknown>): Row {
  if (!billingTables.includes(table)) throw new Error("Unknown billing table");
  const row: Row = { ...table.defaults };
  for (const field of table.fields) {
    const value = source[column(field)];
    if (
      value === undefined ||
      (value !== null && !["string", "boolean", "number"].includes(typeof value))
    )
      throw new Error("Invalid legacy billing value");
    if (integer.test(field) && value !== null) {
      if (
        (typeof value === "number" && !Number.isSafeInteger(value)) ||
        !/^\d+$/.test(String(value))
      )
        throw new Error("Invalid legacy billing timestamp or amount");
      row[field] = String(value);
    } else {
      if (typeof value === "number") throw new Error("Unexpected billing number");
      row[field] = value as string | boolean | null;
    }
  }
  if (typeof row[table.fields[0]] !== "string" || !row[table.fields[0]])
    throw new Error("Invalid billing identity");
  if (table.type === "BillingAdmission" && row.closedAtMs === null)
    throw new Error("Drain legacy billing admissions before migration");
  if (table.type === "BillingExecution" && row.finishedAtMs === null)
    throw new Error("Drain legacy billing executions before migration");
  if (table.type === "BillingCheckoutCreation")
    row.openTeamId = row.closedAt === null ? row.teamId : null;
  return row;
}

type Scan = (
  visit: (table: Table, source: Record<string, unknown>) => Promise<void>,
) => Promise<void>;
interface Destination {
  get(table: Table, row: Row): Promise<Row | null | undefined>;
  insert(table: Table, row: Row): Promise<void>;
}
function matches(expected: Row, actual: Row) {
  return Object.entries(expected).every(([key, value]) => actual[key] === value);
}

export async function migrateBilling(scan: Scan, target: Destination, apply = false) {
  const counts: Record<string, number> = {};
  let unchanged = 0,
    inserted = 0;
  // Check the entire snapshot and destination before the first write.
  await scan(async (table, source) => {
    const row = billingRow(table, source);
    const existing = await target.get(table, row);
    if (existing && !matches(row, existing))
      throw new Error("Destination billing differs; refusing to overwrite");
    counts[table.type] = (counts[table.type] ?? 0) + 1;
  });
  if (!apply) return { dryRun: true, counts };
  await scan(async (table, source) => {
    const row = billingRow(table, source);
    let existing = await target.get(table, row);
    if (!existing) {
      try {
        await target.insert(table, row);
      } catch {
        /* Re-read after a duplicate or lost response. */
      }
      existing = await target.get(table, row);
      inserted++;
    } else unchanged++;
    if (!existing || !matches(row, existing)) throw new Error("Billing import verification failed");
  });
  return { dryRun: false, counts, inserted, unchanged };
}

export function billingDestination(dc: DataConnect): Destination {
  return {
    get: async (table, row) => {
      const field = table.type[0].toLowerCase() + table.type.slice(1);
      const key = table.fields[0];
      const result = await dc.executeGraphqlRead<{ row: Row | null }, { key: string }>(
        `query ImportRead($key: String!) { row: ${field}(key: { ${key}: $key }) { ${Object.keys(row).join(" ")} } }`,
        { variables: { key: row[key] as string } },
      );
      return result.data.row;
    },
    insert: async (table, row) => {
      await dc.insert(table.type, row);
    },
  };
}

async function main() {
  const databaseUrl = process.env.LEGACY_DATABASE_URL;
  const project = process.env.BILLING_MIGRATION_PROJECT;
  if (!databaseUrl || !project) throw new Error("Missing migration configuration");
  const db = new Client({ connectionString: databaseUrl });
  await db.connect();
  try {
    await db.query("BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY");
    initializeApp({ projectId: project });
    const dc = isolatedConnector(connectorConfig);
    // Active legacy billing teams must already exist in FSC. Deleted-team
    // billing identities are intentionally copied without recreating a team.
    const teams = await db.query<{ id: string }>(
      "SELECT id FROM teams WHERE id IN (SELECT team_id FROM billing_accounts)",
    );
    for (const { id } of teams.rows) {
      const r = await dc.executeGraphqlRead<{ team: unknown }, { id: string }>(
        "query ImportTeam($id: String!) { team(id: $id) { id } }",
        { variables: { id } },
      );
      if (!r.data.team) throw new Error("Import active teams before billing");
    }
    const scan: Scan = async (visit) => {
      for (const table of billingTables) {
        let after: string | null = null;
        const key = column(table.fields[0]);
        for (;;) {
          // Identifiers come exclusively from the constant allowlist above.
          const result: QueryResult<Record<string, unknown>> = await db.query(
            `SELECT ${table.fields.map(column).join(", ")} FROM ${table.sql} WHERE ($1::text IS NULL OR ${key} > $1) ORDER BY ${key} LIMIT 100`,
            [after],
          );
          if (!result.rows.length) break;
          for (const row of result.rows) {
            await visit(table, row);
            after = row[key] as string;
          }
        }
      }
    };
    process.stdout.write(
      JSON.stringify(
        await migrateBilling(scan, billingDestination(dc), process.argv.includes("--apply")),
      ) + "\n",
    );
  } finally {
    await db.end();
    await Promise.all(getApps().map(deleteApp));
  }
}
if (process.argv[1]?.replaceAll("\\", "/").endsWith("/billing/migrate.js"))
  main().catch(() => {
    process.stderr.write(
      "Billing migration stopped. Existing destination records were not overwritten. Keep billing writers stopped and resolve the dry-run conflict before cutover.\n",
    );
    process.exitCode = 1;
  });
