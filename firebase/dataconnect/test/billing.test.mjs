import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { createRequire } from "node:module";
import { after, test } from "node:test";
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getDataConnect } from "firebase-admin/data-connect";
import * as sdk from "@openci/billing-admin";
import { BillingStore } from "../../lib/functions/billing/store.js";
import { Billing } from "../../lib/functions/billing/service.js";
import {
  config,
  now,
  price,
  session,
  intent,
  subscription,
  invoice,
  stripeFixture,
} from "../../functions/test/helpers/billing.mjs";

const host = process.env.DATA_CONNECT_EMULATOR_HOST;
assert.match(host ?? "", /^(127\.0\.0\.1|localhost):\d+$/, "Start the SQL Connect emulator first");
const service = `http://${host}/v1/projects/demo-openci/locations/asia-northeast1/services/openci-b1b91-service`;
const app = initializeApp({ projectId: "demo-openci" });
const dc = getDataConnect(sdk.connectorConfig, app);
after(() => deleteApp(app));

async function graphql(query, variables) {
  const response = await fetch(`${service}:executeGraphql`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ query, variables }),
    signal: AbortSignal.timeout(15000),
  });
  const result = await response.json();
  assert.ok(response.ok && !result.errors?.length, JSON.stringify(result));
  return result.data;
}

async function fixture(t) {
  const id = randomUUID();
  const f = { teamId: `${id}-team`, otherTeamId: `${id}-other`, userId: `${id}-user` };
  t.after(() =>
    graphql(
      `
        mutation Cleanup($ids: [String!]!) @transaction {
          team_deleteMany(where: { id: { in: $ids } })
          buildJob_deleteMany(where: { teamId: { in: $ids } })
          billingAccount_deleteMany(where: { teamId: { in: $ids } })
          billingTeamDeletion_deleteMany(where: { teamId: { in: $ids } })
        }
      `,
      { ids: [f.teamId, f.otherTeamId] },
    ),
  );
  await graphql(
    `
      mutation Seed($teamId: String!, $otherTeamId: String!, $userId: String!) @transaction {
        team_insertMany(
          data: [
            { id: $teamId, name: "Team", createdAt: 1, updatedAt: 1 }
            { id: $otherTeamId, name: "Other", createdAt: 1, updatedAt: 1 }
          ]
        )
        teamMember_insertMany(
          data: [{ teamId: $teamId, userId: $userId }, { teamId: $otherTeamId, userId: $userId }]
        )
      }
    `,
    f,
  );
  return f;
}

function context(f) {
  return sdk.getBillingContext(dc, { teamId: f.teamId, userId: f.userId }).then((r) => r.data);
}

async function customer(f) {
  const input = {
    teamId: f.teamId,
    userId: f.userId,
    idempotencyKey: randomUUID(),
    livemode: false,
    createdAt: "1",
  };
  await sdk.createBillingCustomerCreation(dc, input);
  const linked = {
    teamId: f.teamId,
    idempotencyKey: input.idempotencyKey,
    livemode: false,
    stripeCustomerId: `cus_${randomUUID()}`,
  };
  await sdk.recordBillingCustomer(dc, linked);
  return linked;
}

async function checkout(f, c) {
  const input = {
    idempotencyKey: randomUUID(),
    teamId: f.teamId,
    planId: "pro",
    stripeCustomerId: c.stripeCustomerId,
    stripePriceId: "price_pro",
    successUrl: "https://example.test/success",
    cancelUrl: "https://example.test/cancel",
    livemode: false,
    createdAt: "2",
  };
  await sdk.createBillingCheckoutCreation(dc, { ...input, userId: f.userId });
  const session = { ...input, stripeCheckoutSessionId: `cs_${randomUUID()}` };
  await sdk.recordBillingCheckoutSession(dc, session);
  return session;
}

function closeInput(s) {
  return {
    teamId: s.teamId,
    idempotencyKey: s.idempotencyKey,
    stripeCustomerId: s.stripeCustomerId,
    livemode: s.livemode,
    stripeCheckoutSessionId: s.stripeCheckoutSessionId,
    closedAt: "3",
  };
}

async function period(f, overrides = {}) {
  const now = Math.floor(Date.now() / 1000);
  const input = {
    id: randomUUID(),
    teamId: f.teamId,
    planId: "pro",
    periodType: "paid",
    startsAt: String(now - 60),
    endsAt: String(now + 3600),
    allowanceSeconds: "360000",
    ...overrides,
  };
  await sdk.createBillingPeriod(dc, input);
  return input;
}

function deletion(f, observed = {}) {
  return {
    teamId: f.teamId,
    userId: f.userId,
    livemode: false,
    expectedCustomerCreationKey: observed.customer?.idempotencyKey ?? null,
    expectedStripeCustomerId: observed.customer?.stripeCustomerId ?? null,
    expectedStripeRevision: observed.stripe?.revision ?? null,
  };
}

async function seedJob(f, overrides = {}) {
  const job = {
    id: randomUUID(),
    teamId: f.teamId,
    status: "QUEUED",
    owner: "org",
    repo: "repo",
    workflowName: "CI",
    workflowFileName: "ci.dart",
    createdAt: "1",
    updatedAt: "1",
    ...overrides,
  };
  await graphql(
    `
      mutation Seed($job: BuildJob_Data!) {
        buildJob_insert(data: $job)
      }
    `,
    { job },
  );
  return job;
}

const novemberStart = Date.parse("2026-11-01T00:00:00+09:00");

async function seedMonthlyRuns(f, intervals, overrides = {}, anchor = novemberStart) {
  const p = {
    id: randomUUID(),
    teamId: f.teamId,
    startsAt: String(anchor / 1000 - 86400),
    endsAt: String(anchor / 1000 + 86400),
    planId: "postpaid",
    periodType: "postpaid",
    allowanceSeconds: null,
    ...overrides,
  };
  await graphql(
    `
      mutation Period($teamId: String!, $p: BillingPeriod_Data!) @transaction {
        billingAccount_upsert(data: { teamId: $teamId })
        billingPeriod_insert(data: $p)
      }
    `,
    { teamId: f.teamId, p },
  );
  const job = await seedJob(f);
  const runs = [];
  const steps = [];
  const executions = [];
  for (const [i, interval] of intervals.entries()) {
    const { start, prepEnd, prepStatus = "SUCCESS", observed, outcome = "success" } = interval;
    const id = `${job.id}-${i.toString().padStart(3, "0")}`;
    const startedAtMs = anchor + start;
    const observedAtMs = anchor + observed;
    runs.push({
      id,
      buildJobId: job.id,
      status: outcome ? "completed" : "in_progress",
      createdAt: String(Math.floor(startedAtMs / 1000)),
      updatedAt: String(Math.floor(observedAtMs / 1000)),
    });
    if (prepEnd !== undefined) {
      steps.push({
        runId: id,
        stepId: "prepare_vm",
        name: "prepare_vm",
        status: prepStatus,
        stepOrder: 0,
        createdAt: new Date(startedAtMs).toISOString(),
        updatedAt: new Date(anchor + prepEnd).toISOString(),
      });
    }
    executions.push({
      runId: id,
      jobId: job.id,
      teamId: f.teamId,
      periodId: p.id,
      workerHost: "worker",
      startedAtMs: String(startedAtMs),
      observedAtMs: String(observedAtMs),
      leaseUntilMs: String(observedAtMs + 60000),
      finishedAtMs: outcome ? String(observedAtMs) : null,
      outcome,
      measurementIncomplete: outcome === "abandoned",
    });
  }
  await graphql(
    `
      mutation SeedMeasuredRuns(
        $runs: [BuildRun_Data!]!
        $steps: [BuildStep_Data!]!
        $executions: [BillingExecution_Data!]!
      ) @transaction {
        buildRun_insertMany(data: $runs)
        buildStep_insertMany(data: $steps)
        billingExecution_insertMany(data: $executions)
      }
    `,
    { runs, steps, executions },
  );
}

test("JST monthly statement sums observed post-preparation time across attempts before rounding", async (t) => {
  const f = await fixture(t);
  const intervals = [
    { start: -65000, prepEnd: -20000, observed: 20000 },
    { start: -30000, prepEnd: 5000, observed: 25000, outcome: "failure" },
    { start: 1000, prepEnd: 10000, observed: 30000, outcome: null },
    { start: 0, observed: 10000, outcome: "abandoned" },
    { start: 0, prepEnd: 5000, prepStatus: "FAILURE", observed: 15000, outcome: "failure" },
  ];
  await seedMonthlyRuns(f, intervals);
  await seedMonthlyRuns({ teamId: f.otherTeamId }, [intervals[0]]);
  await seedMonthlyRuns(f, [intervals[0]], {
    id: `complimentary-pro:${f.teamId}:2026-11`,
    periodType: "paid",
    planId: "pro",
    allowanceSeconds: "360000",
  });
  await seedMonthlyRuns(f, [intervals[0]], { periodType: "trial", planId: "light" });
  await seedMonthlyRuns(f, [intervals[0]], {
    periodType: "paid",
    planId: "light",
    allowanceSeconds: "36000",
  });

  const statement = async (month) =>
    (await sdk.getTeamMonthlyUsage(dc, { teamId: f.teamId, month })).data.statement;
  const current = await statement("2026-11-01");
  assert.equal(current.teamId, f.teamId);
  assert.equal(current.month, "2026-11");
  assert.equal(current.runCount, "5");
  assert.deepEqual(
    current.runs.map((r) => r.measuredMillis),
    ["20000", "20000", "20000", "0", "0"],
  );
  assert.equal(current.runs[3].measurementIncomplete, true);
  assert.equal(current.runs[3].vmReadyAt, null);
  assert.equal(current.measuredMillis, "60000");
  assert.equal(current.billableMinutes, "1");
  assert.equal(current.amountJpyTaxIncluded, "1");
  assert.equal(current.amountUsdCentsTaxIncluded, null);
  assert.deepEqual(await statement("2026-11-30"), current);
  assert.equal((await statement("2026-10-01")).measuredMillis, "20000");
  const empty = await statement("2026-12-01");
  assert.deepEqual(empty.runs, []);
  assert.equal(empty.amountJpyTaxIncluded, "0");
});

test("monthly totals cover every page and convert the tax-inclusive yen total once", async (t) => {
  const f = await fixture(t);
  const interval = { start: 0, prepEnd: 500, observed: 2500 };
  await seedMonthlyRuns(f, Array(100).fill(interval));
  await seedMonthlyRuns(f, [interval]);
  const variables = { teamId: f.teamId, month: "2026-11-01", jpyPerUsd: "160.00" };
  const first = (await sdk.getTeamMonthlyUsage(dc, variables)).data.statement;
  const second = (
    await sdk.getTeamMonthlyUsage(dc, { ...variables, afterRunId: first.runs.at(-1).runId })
  ).data.statement;
  for (const page of [first, second]) {
    assert.equal(page.runCount, "101");
    assert.equal(page.measuredMillis, "202000");
    assert.equal(page.billableMinutes, "4");
    assert.equal(page.amountJpyTaxIncluded, "4");
    assert.equal(page.jpyPerUsd, "160.00");
    assert.equal(page.amountUsdCentsTaxIncluded, "3");
  }
  assert.equal(first.runs.length, 100);
  assert.equal(second.runs.length, 1);
  assert.equal(new Set([...first.runs, ...second.runs].map((r) => r.runId)).size, 101);
  for (const rate of ["0", "-1", "NaN", "1e3"]) {
    await assert.rejects(sdk.getTeamMonthlyUsage(dc, { ...variables, jpyPerUsd: rate }));
  }
});

test("monthly close freezes all run pages and currency across concurrent closes and later writes", async (t) => {
  const f = await fixture(t);
  const anchor = Date.parse("2020-04-01T00:00:00+09:00");
  const interval = { start: 0, prepEnd: 500, observed: 2500 };
  await seedMonthlyRuns(f, Array(100).fill(interval), {}, anchor);
  await seedMonthlyRuns(f, [interval], {}, anchor);
  await seedMonthlyRuns(
    f,
    [interval],
    { periodType: "paid", planId: "pro", allowanceSeconds: "360000" },
    anchor,
  );
  const vars = {
    teamId: f.teamId,
    month: "2020-04-01",
    currency: "USD",
    jpyPerUsd: "160.00",
    rateDate: "2020-04-30",
  };
  const close = async (input = vars) => (await sdk.closeTeamMonthlyStatement(dc, input)).data;
  const [a, b] = await Promise.all([close(), close()]);
  const receipt = a.receipt.statement;
  assert.deepEqual(b.receipt.statement, receipt);
  assert.deepEqual(
    [
      receipt.runCount,
      receipt.measuredMillis,
      receipt.billableMinutes,
      receipt.amountJpyTaxIncluded,
      receipt.amountUsdCentsTaxIncluded,
    ],
    ["101", "202000", "4", "4", "3"],
  );
  assert.equal(receipt.jpyPerUsd, "160.00");
  assert.equal(receipt.rateDate, "2020-04-30");
  const firstPage = a.usage.statement;
  assert.equal(firstPage.runs.length, 100);
  const last = firstPage.runs.at(-1).runId;
  const second = await close({ ...vars, afterRunId: last, jpyPerUsd: "160" });
  assert.equal(second.usage.statement.runs.length, 1);
  assert.deepEqual(second.receipt.statement, receipt);
  await seedMonthlyRuns(f, [{ start: 0, prepEnd: 0, observed: 600000 }], {}, anchor);
  const run = firstPage.runs[0];
  await graphql(
    `
      mutation Change($id: String!, $at: Int64!) {
        billingExecution_update(key: { runId: $id }, data: { observedAtMs: $at })
      }
    `,
    { id: run.runId, at: String(anchor + 90000) },
  );
  const read = (
    await sdk.getTeamMonthlyUsage(dc, { teamId: f.teamId, month: "2020-04-12", jpyPerUsd: "100" })
  ).data.statement;
  assert.deepEqual(read, firstPage);
  assert.deepEqual((await close()).receipt.statement, receipt);
  await assert.rejects(close({ ...vars, jpyPerUsd: "155" }));
  await assert.rejects(close({ ...vars, rateDate: "2020-05-01" }));
  await assert.rejects(close({ ...vars, currency: "JPY", jpyPerUsd: null, rateDate: null }));
  const link = { teamId: f.teamId, month: vars.month, invoiceId: "in_testApril" };
  await sdk.linkMonthlyStatementInvoice(dc, link);
  await sdk.linkMonthlyStatementInvoice(dc, link);
  await assert.rejects(sdk.linkMonthlyStatementInvoice(dc, { ...link, invoiceId: "in_anyOther" }));
  const saved = (await sdk.getClosedMonthlyStatement(dc, { teamId: f.teamId, month: vars.month }))
    .data.statement;
  assert.deepEqual(saved, { ...receipt, stripeInvoiceId: link.invoiceId });
  assert.equal(
    (await sdk.getClosedMonthlyStatement(dc, { teamId: f.otherTeamId, month: vars.month })).data
      .statement,
    null,
  );
});

test("monthly close rejects active months, unsettled observations and invalid FX without partial statements", async (t) => {
  const f = await fixture(t);
  const anchor = Date.parse("2020-04-01T00:00:00+09:00");
  await seedMonthlyRuns(f, [{ start: 0, prepEnd: 500, observed: 2500, outcome: null }], {}, anchor);
  const vars = { teamId: f.teamId, month: "2020-04-01", currency: "JPY" };
  for (const input of [
    vars,
    { ...vars, month: "2020-04-02" },
    { ...vars, month: "2999-01-01" },
    { ...vars, currency: "USD" },
    { ...vars, currency: "EUR" },
    { ...vars, jpyPerUsd: "150" },
    { ...vars, currency: "USD", jpyPerUsd: "0", rateDate: "2020-04-30" },
  ])
    await assert.rejects(sdk.closeTeamMonthlyStatement(dc, input));
  assert.equal(
    (await sdk.getClosedMonthlyStatement(dc, { teamId: f.teamId, month: vars.month })).data
      .statement,
    null,
  );
  const empty = { ...vars, month: "2020-03-01" };
  const zero = (await sdk.closeTeamMonthlyStatement(dc, empty)).data.receipt.statement;
  assert.equal(zero.amountJpyTaxIncluded, "0");
  assert.equal(zero.amountUsdCentsTaxIncluded, null);
  await assert.rejects(
    sdk.linkMonthlyStatementInvoice(dc, {
      teamId: f.teamId,
      month: empty.month,
      invoiceId: "in_zero",
    }),
  );
  const current = (await sdk.getTeamMonthlyUsage(dc, { teamId: f.teamId, month: vars.month })).data
    .statement;
  await graphql(
    `
      mutation Finish($run: String!, $at: Int64!) {
        billingExecution_update(
          key: { runId: $run }
          data: { finishedAtMs: $at, outcome: "success" }
        )
      }
    `,
    { run: current.runs[0].runId, at: current.runs[0].observedAtMs },
  );
  const closed = (await sdk.closeTeamMonthlyStatement(dc, vars)).data.receipt.statement;
  assert.equal(closed.amountJpyTaxIncluded, "1");
  assert.equal(closed.amountUsdCentsTaxIncluded, null);
});

test("a crossing run observed beyond month end can close and zero USD cents cannot be invoiced", async (t) => {
  const f = await fixture(t);
  await seedMonthlyRuns(
    f,
    [{ start: -61000, prepEnd: -51000, observed: 2000, outcome: null }],
    {},
    Date.parse("2020-05-01T00:00:00+09:00"),
  );
  const vars = {
    teamId: f.teamId,
    month: "2020-04-01",
    currency: "USD",
    jpyPerUsd: "1000",
    rateDate: "2020-04-30",
  };
  const closed = (await sdk.closeTeamMonthlyStatement(dc, vars)).data.receipt.statement;
  assert.equal(closed.measuredMillis, "51000");
  assert.equal(closed.billableMinutes, "1");
  assert.equal(closed.amountUsdCentsTaxIncluded, "0");
  await assert.rejects(
    sdk.linkMonthlyStatementInvoice(dc, {
      teamId: f.teamId,
      month: vars.month,
      invoiceId: "in_zeroUsd",
    }),
  );
  const currentMonth = new Date(Date.now() + 9 * 3600000).toISOString().slice(0, 7) + "-01";
  await assert.rejects(sdk.closeTeamMonthlyStatement(dc, { ...vars, month: currentMonth }));
});

test("team billing shows the postpaid estimate for the current Japan month and rechecks membership", async (t) => {
  const f = await fixture(t);
  const april = Date.parse("2020-04-01T00:00:00+09:00");
  await seedMonthlyRuns(f, [{ start: 0, prepEnd: 30000, observed: 150001 }], {}, april);
  const store = new BillingStore(dc);
  let now = april + 200000;
  const service = new Billing(store, null, config, () => now);
  const status = () => service.execute(f.userId, { action: "status", teamId: f.teamId });
  assert.deepEqual((await status()).monthlyUsage, {
    month: "2020-04",
    billableMinutes: "3",
    amountJpyTaxIncluded: "3",
    nextInvoiceDate: "2020-05-01",
  });
  now = april - 1;
  assert.deepEqual((await status()).monthlyUsage, {
    month: "2020-03",
    billableMinutes: "0",
    amountJpyTaxIncluded: "0",
    nextInvoiceDate: "2020-04-01",
  });
  store.currentMonthlyUsage = async () => {
    throw Error("unavailable");
  };
  assert.equal((await status()).monthlyUsage, null);
  store.currentMonthlyUsage = async () => {
    await graphql("mutation Remove($id:String!) {teamMember_deleteMany(where:{teamId:{eq:$id}})}", {
      id: f.teamId,
    });
    return {
      month: "2020-04",
      billableMinutes: "3",
      amountJpyTaxIncluded: "3",
      nextInvoiceDate: "2020-05-01",
    };
  };
  await assert.rejects(status(), /forbidden/);
});

test("billing context checks membership and preserves missing billing data", async (t) => {
  const f = await fixture(t);
  assert.deepEqual(await context(f), {
    account: null,
    customer: null,
    stripe: null,
    checkout: null,
  });
  await assert.rejects(sdk.getBillingContext(dc, { teamId: f.teamId, userId: "outsider" }));
  const c = await customer(f);
  const p = await period(f);
  await sdk.initializeBillingStripeState(dc, {
    teamId: f.teamId,
    stripeCustomerId: c.stripeCustomerId,
    livemode: false,
  });
  const s = await checkout(f, c);
  const data = await context(f);
  assert.equal(data.customer.stripeCustomerId, c.stripeCustomerId);
  assert.equal(data.stripe.subscriptionStatus, "none");
  assert.equal(data.checkout.idempotencyKey, s.idempotencyKey);
  assert.equal(data.account.usageRevision, "0");
  assert.equal(
    (await sdk.getBillingPeriod(dc, { teamId: f.teamId, id: p.id })).data.period.allowanceSeconds,
    "360000",
  );
  await graphql(
    `
      mutation Remove($teamId: String!) {
        teamMember_deleteMany(where: { teamId: { eq: $teamId } })
      }
    `,
    { teamId: f.teamId },
  );
  await assert.rejects(context(f));
});

test("webhook lookups filter team and mode and include closed purchases", async (t) => {
  const f = await fixture(t);
  const c = await customer(f);
  const s = await checkout(f, c);
  await sdk.closeBillingCheckoutCreation(dc, closeInput(s));
  const key = { teamId: f.teamId, idempotencyKey: s.idempotencyKey, livemode: false };
  const stored = (await sdk.getBillingCheckoutCreation(dc, key)).data.checkout;
  assert.equal(stored.closedAt, "3");
  assert.equal(stored.stripeCheckoutSessionId, s.stripeCheckoutSessionId);
  assert.equal(
    (await sdk.getBillingCheckoutCreation(dc, { ...key, teamId: f.otherTeamId })).data.checkout,
    null,
  );
  assert.equal(
    (await sdk.getBillingCheckoutCreation(dc, { ...key, livemode: true })).data.checkout,
    null,
  );
  assert.equal(
    (
      await sdk.getBillingCustomerByStripeId(dc, {
        stripeCustomerId: c.stripeCustomerId,
        livemode: false,
      })
    ).data.customer.teamId,
    f.teamId,
  );
  assert.equal(
    (
      await sdk.getBillingCustomerByStripeId(dc, {
        stripeCustomerId: c.stripeCustomerId,
        livemode: true,
      })
    ).data.customer,
    null,
  );
  await sdk.deleteBillingTeam(dc, deletion(f, await context(f)));
  assert.equal(
    (await sdk.getBillingCheckoutCreation(dc, key)).data.checkout.idempotencyKey,
    s.idempotencyKey,
  );
  assert.equal(
    (
      await sdk.getBillingCustomerByStripeId(dc, {
        stripeCustomerId: c.stripeCustomerId,
        livemode: false,
      })
    ).data.customer.teamId,
    f.teamId,
  );
});

test("period retry reads preserve bigint precision and never overwrite a period", async (t) => {
  const f = await fixture(t);
  const p = await period(f, { allowanceSeconds: "9007199254740993" });
  await assert.rejects(sdk.createBillingPeriod(dc, { ...p, allowanceSeconds: "1" }));
  assert.deepEqual((await sdk.getBillingPeriod(dc, { teamId: f.teamId, id: p.id })).data.period, p);
  assert.equal(
    (await sdk.getBillingPeriod(dc, { teamId: f.otherTeamId, id: p.id })).data.period,
    null,
  );
});

test("team deletion returns secret references and retains billing/build history", async (t) => {
  const f = await fixture(t);
  const c = await customer(f);
  const p = await period(f);
  const job = await seedJob(f);
  const path = `projects/demo-openci/secrets/${f.teamId}/versions/1`;
  await graphql(
    `
      mutation Secret($teamId: String!, $path: String!) {
        secretReference_insert(
          data: {
            teamId: $teamId
            name: "TOKEN"
            secretVersionPath: $path
            createdAt: 1
            updatedAt: 1
          }
        )
      }
    `,
    { teamId: f.teamId, path },
  );
  const observed = await context(f);
  await assert.rejects(sdk.deleteBillingTeam(dc, { ...deletion(f, observed), userId: "outsider" }));
  await assert.rejects(sdk.deleteBillingTeam(dc, { ...deletion(f, observed), livemode: true }));
  const result = await sdk.deleteBillingTeam(dc, deletion(f, observed));
  assert.deepEqual(result.data.cleanup.secrets, [{ secretVersionPath: path }]);
  assert.equal(result.data.team_delete.id, f.teamId);
  await assert.rejects(context(f));
  assert.equal(
    (await sdk.getBillingPeriod(dc, { teamId: f.teamId, id: p.id })).data.period.id,
    p.id,
  );
  assert.equal((await sdk.getBillingJob(dc, { id: job.id })).data.job.teamId, f.teamId);
  assert.equal(
    (
      await sdk.getBillingCustomerByStripeId(dc, {
        stripeCustomerId: c.stripeCustomerId,
        livemode: false,
      })
    ).data.customer.teamId,
    f.teamId,
  );
});

test("pending Customer creation and open Checkouts prevent team deletion", async (t) => {
  const f = await fixture(t);
  const stale = deletion(f, await context(f));
  const intent = {
    teamId: f.teamId,
    userId: f.userId,
    idempotencyKey: randomUUID(),
    livemode: false,
    createdAt: "1",
  };
  await sdk.createBillingCustomerCreation(dc, intent);
  await assert.rejects(sdk.deleteBillingTeam(dc, stale));
  await assert.rejects(sdk.deleteBillingTeam(dc, deletion(f, await context(f))));
  const c = {
    teamId: f.teamId,
    idempotencyKey: intent.idempotencyKey,
    livemode: false,
    stripeCustomerId: `cus_${randomUUID()}`,
  };
  await sdk.recordBillingCustomer(dc, c);
  await assert.rejects(sdk.deleteBillingTeam(dc, stale));
  const s = await checkout(f, c);
  await assert.rejects(sdk.deleteBillingTeam(dc, deletion(f, await context(f))));
  await sdk.closeBillingCheckoutCreation(dc, closeInput(s));
  await sdk.deleteBillingTeam(dc, deletion(f, await context(f)));
});

test("changed Stripe revisions and nonterminal subscriptions block deletion", async (t) => {
  const f = await fixture(t);
  const c = await customer(f);
  await sdk.initializeBillingStripeState(dc, {
    teamId: f.teamId,
    stripeCustomerId: c.stripeCustomerId,
    livemode: false,
  });
  const stale = deletion(f, await context(f));
  const event = {
    teamId: f.teamId,
    stripeCustomerId: c.stripeCustomerId,
    livemode: false,
    expectedRevision: "0",
    stripeSubscriptionId: `sub_${randomUUID()}`,
    subscriptionStatus: "active",
    cancelAtPeriodEnd: false,
    eventId: randomUUID(),
    eventType: "customer.subscription.updated",
    eventCreated: "2",
    processedAt: "2",
  };
  t.after(() =>
    graphql(
      `
        mutation Cleanup($ids: [String!]!) {
          billingStripeEvent_deleteMany(where: { eventId: { in: $ids } })
        }
      `,
      { ids: [event.eventId, `${event.eventId}-ended`] },
    ),
  );
  await sdk.recordBillingStripeEvent(dc, event);
  await assert.rejects(sdk.deleteBillingTeam(dc, stale));
  await assert.rejects(sdk.deleteBillingTeam(dc, deletion(f, await context(f))));
  await sdk.recordBillingStripeEvent(dc, {
    ...event,
    expectedRevision: "1",
    subscriptionStatus: "canceled",
    eventId: `${event.eventId}-ended`,
    eventCreated: "3",
    processedAt: "3",
  });
  await assert.rejects(sdk.deleteBillingTeam(dc, stale));
  await sdk.deleteBillingTeam(dc, deletion(f, await context(f)));
});

test("concurrent Customer creation and deletion cannot both commit", async (t) => {
  const f = await fixture(t);
  const results = await Promise.allSettled([
    sdk.deleteBillingTeam(dc, deletion(f)),
    sdk.createBillingCustomerCreation(dc, {
      teamId: f.teamId,
      userId: f.userId,
      idempotencyKey: randomUUID(),
      livemode: false,
      createdAt: "1",
    }),
  ]);
  assert.equal(results.filter((r) => r.status === "fulfilled").length, 1);
});

test("concurrent Checkout creation and deletion cannot both commit", async (t) => {
  const f = await fixture(t);
  const c = await customer(f);
  const observed = await context(f);
  const results = await Promise.allSettled([
    sdk.deleteBillingTeam(dc, deletion(f, observed)),
    sdk.createBillingCheckoutCreation(dc, {
      teamId: f.teamId,
      userId: f.userId,
      idempotencyKey: randomUUID(),
      livemode: false,
      createdAt: "2",
      planId: "pro",
      stripeCustomerId: c.stripeCustomerId,
      stripePriceId: "price_pro",
      successUrl: "https://example.test/success",
      cancelUrl: "https://example.test/cancel",
    }),
  ]);
  assert.equal(results.filter((r) => r.status === "fulfilled").length, 1);
});

test("generated SDK executes reservation, run binding, measurement and completion", async (t) => {
  const f = await fixture(t);
  const p = await period(f);
  const job = await seedJob(f);
  const atMs = String(Date.now());
  const id = randomUUID();
  const runId = randomUUID();
  const identity = { teamId: f.teamId, jobId: job.id, workerHost: "test-worker", runId };
  await sdk.createBillingAdmission(dc, { id, ...identity, periodId: p.id, atMs, runId: undefined });
  await sdk.bindBillingAdmissionRun(dc, { id, ...identity, expectedUsageRevision: "1", atMs });
  await sdk.startBillingExecution(dc, {
    admissionId: id,
    ...identity,
    expectedUsageRevision: "2",
    atMs,
  });
  const observed = String(BigInt(atMs) + 1000n);
  await sdk.heartbeatBillingExecution(dc, {
    ...identity,
    expectedUsageRevision: "3",
    atMs: observed,
  });
  const usage = (
    await sdk.getBillingPeriodUsage(dc, { teamId: f.teamId, periodId: p.id, atMs: observed })
  ).data.usage;
  assert.equal(usage.revision, "4");
  assert.equal(usage.measuredMillis, "1000");
  await sdk.finishBillingExecution(dc, {
    ...identity,
    expectedUsageRevision: "4",
    atMs: observed,
    outcome: "success",
  });
  assert.equal(
    (await sdk.getBillingExecution(dc, { teamId: f.teamId, runId })).data.billingExecution.outcome,
    "success",
  );
  assert.equal(
    (await sdk.getBillingAdmission(dc, { teamId: f.teamId, id })).data.billingAdmission.openJobId,
    null,
  );
  await assert.rejects(
    sdk.heartbeatBillingExecution(dc, { ...identity, expectedUsageRevision: "5", atMs: observed }),
  );
});

test("CommonJS default SDK and admission expiry preserve queued jobs", async (t) => {
  const f = await fixture(t);
  const cjs = createRequire(import.meta.url)("@openci/billing-admin");
  assert.equal(
    (await cjs.getBillingContext({ teamId: f.teamId, userId: f.userId })).data.customer,
    null,
  );
  const p = await period(f, { startsAt: "1", endsAt: "3600" });
  const job = await seedJob(f);
  const id = randomUUID();
  await sdk.createBillingAdmission(dc, {
    id,
    teamId: f.teamId,
    jobId: job.id,
    workerHost: "test-worker",
    periodId: p.id,
    atMs: "1000",
  });
  const admission = (await sdk.getBillingAdmission(dc, { teamId: f.teamId, id })).data
    .billingAdmission;
  assert.equal(admission.openJobId, job.id);
  assert.equal(admission.runId, null);
  await sdk.expireBillingAdmission(dc, {
    id,
    teamId: f.teamId,
    expectedUsageRevision: "1",
    atMs: "121000",
  });
  assert.equal((await sdk.getBillingJob(dc, { id: job.id })).data.job.status, "QUEUED");
});

test("all billing SDK operations reject Firebase clients, including team members", async (t) => {
  const f = await fixture(t);
  const team = { teamId: f.teamId };
  const member = { ...team, userId: f.userId };
  const identity = { ...team, jobId: "job", workerHost: "worker", runId: "run" };
  const execution = { ...identity, expectedUsageRevision: "0", atMs: "1000" };
  const c = { ...team, livemode: false, idempotencyKey: "key", stripeCustomerId: "customer" };
  const s = {
    ...c,
    planId: "pro",
    stripePriceId: "price",
    successUrl: "https://example.test/success",
    cancelUrl: "https://example.test/cancel",
    createdAt: "1",
  };
  const cases = [
    [sdk.getBillingContext, member],
    [sdk.getBillingMembership, member],
    [sdk.getBillingTeamDeletion, member],
    [sdk.getDueBillingTeamDeletions, undefined],
    [sdk.completeBillingTeamCleanup, team],
    [sdk.deferBillingTeamCleanup, team],
    [sdk.acknowledgeBillingCredentialCleanup, { ...team, path: "path", kind: "secret" }],
    [sdk.getBillingCustomerByStripeId, { stripeCustomerId: "customer", livemode: false }],
    [sdk.getBillingCheckoutCreation, { ...team, idempotencyKey: "key", livemode: false }],
    [sdk.getBillingPeriod, { ...team, id: "period" }],
    [sdk.getBillingJob, { id: "job" }],
    [sdk.deleteBillingTeam, deletion(f)],
    [
      sdk.createBillingPeriod,
      {
        ...team,
        id: "period",
        planId: "pro",
        periodType: "paid",
        startsAt: "1",
        endsAt: "2",
        allowanceSeconds: "1",
      },
    ],
    [
      sdk.createBillingCustomerCreation,
      { ...member, idempotencyKey: "key", livemode: false, createdAt: "1" },
    ],
    [sdk.recordBillingCustomer, c],
    [sdk.createBillingCheckoutCreation, { ...s, userId: f.userId }],
    [sdk.recordBillingCheckoutSession, { ...s, stripeCheckoutSessionId: "session" }],
    [sdk.closeBillingCheckoutCreation, { ...c, stripeCheckoutSessionId: "session", closedAt: "2" }],
    [sdk.getBillingStripeState, { ...team, livemode: false }],
    [sdk.getBillingStripeEvent, { eventId: "event" }],
    [sdk.initializeBillingStripeState, { ...team, stripeCustomerId: "customer", livemode: false }],
    [
      sdk.recordBillingStripeEvent,
      {
        ...team,
        stripeCustomerId: "customer",
        livemode: false,
        expectedRevision: "0",
        subscriptionStatus: "none",
        cancelAtPeriodEnd: false,
        eventId: "event",
        eventType: "customer.subscription.updated",
        eventCreated: "1",
        processedAt: "1",
      },
    ],
    [sdk.getBillingPeriodUsage, { ...team, periodId: "period", atMs: "1000" }],
    [sdk.getTeamMonthlyUsage, { ...team, month: "2026-11-01" }],
    [sdk.getClosedMonthlyStatement, { ...team, month: "2020-04-01" }],
    [sdk.closeTeamMonthlyStatement, { ...team, month: "2020-04-01", currency: "JPY" }],
    [sdk.linkMonthlyStatementInvoice, { ...team, month: "2020-04-01", invoiceId: "in_test" }],
    [sdk.getBillingAdmission, { ...team, id: "admission" }],
    [
      sdk.createBillingAdmission,
      {
        ...team,
        id: "admission",
        jobId: "job",
        workerHost: "worker",
        periodId: "period",
        atMs: "1000",
      },
    ],
    [sdk.bindBillingAdmissionRun, { ...execution, id: "admission" }],
    [
      sdk.expireBillingAdmission,
      { ...team, id: "admission", expectedUsageRevision: "0", atMs: "1000" },
    ],
    [sdk.getBillingExecution, { ...team, runId: "run" }],
    [sdk.startBillingExecution, { ...execution, admissionId: "admission" }],
    [sdk.heartbeatBillingExecution, execution],
    [sdk.finishBillingExecution, { ...execution, outcome: "success" }],
    [
      sdk.expireBillingExecution,
      { ...team, runId: "run", expectedUsageRevision: "0", atMs: "1000" },
    ],
  ];
  for (const actor of [
    { impersonate: { authClaims: { sub: f.userId, firebase: { sign_in_provider: "password" } } } },
    { impersonate: { authClaims: { sub: f.userId, firebase: { sign_in_provider: "anonymous" } } } },
    { impersonate: { unauthenticated: true } },
  ]) {
    for (const [operation, variables] of cases) {
      await assert.rejects(
        variables === undefined ? operation(dc, actor) : operation(dc, variables, actor),
        /permission|auth|access denied/i,
      );
    }
  }
  assert.equal(cases.length, 36);
  assert.equal((await context(f)).account, null);
});

test("creation mutations reject outsiders and membership revoked before the write", async (t) => {
  const f = await fixture(t);
  const input = {
    teamId: f.teamId,
    userId: "outsider",
    livemode: false,
    idempotencyKey: randomUUID(),
    createdAt: "1",
  };
  await assert.rejects(sdk.createBillingCustomerCreation(dc, input));
  const c = await customer(f);
  await graphql(
    `
      mutation Revoke($teamId: String!) {
        teamMember_deleteMany(where: { teamId: { eq: $teamId } })
      }
    `,
    { teamId: f.teamId },
  );
  await assert.rejects(
    sdk.createBillingCheckoutCreation(dc, {
      ...intent(f.teamId),
      stripeCustomerId: c.stripeCustomerId,
      userId: f.userId,
    }),
  );
});

test("deletion durably captures cleanup and a private receipt before cascading credentials", async (t) => {
  const f = await fixture(t);
  const path = `projects/demo-openci/secrets/team-${randomUUID()}/versions/1`;
  const oauth = `projects/demo-openci/secrets/openci-github-${randomUUID()}/versions/1`;
  await graphql(
    `
      mutation Seed($teamId: String!, $path: String!, $oauth: String!) @transaction {
        secretReference_insert(
          data: {
            teamId: $teamId
            name: "TOKEN"
            secretVersionPath: $path
            createdAt: 1
            updatedAt: 1
          }
        )
        gitHubConnectionRequest_insert(
          data: {
            id: $teamId
            teamId: $teamId
            userId: "actor"
            stateHash: $teamId
            codeVerifierSecretVersionPath: $oauth
            createdAt: 1
            expiresAt: 2
          }
        )
      }
    `,
    { teamId: f.teamId, path, oauth },
  );
  await sdk.deleteBillingTeam(dc, deletion(f));
  assert.ok(
    (await sdk.getBillingTeamDeletion(dc, { teamId: f.teamId, userId: f.userId })).data.receipt,
  );
  assert.equal(
    (await sdk.getBillingTeamDeletion(dc, { teamId: f.teamId, userId: "other" })).data.receipt,
    null,
  );
  assert.ok(
    !(await sdk.getDueBillingTeamDeletions(dc)).data.deletions.some((d) => d.teamId === f.teamId),
  );
  await graphql(
    `
      mutation Due($teamId: String!) {
        billingTeamDeletion_update(
          key: { teamId: $teamId }
          data: { cleanupAfter: "2000-01-01T00:00:00Z" }
        )
      }
    `,
    { teamId: f.teamId },
  );
  const cleanup = (await sdk.getDueBillingTeamDeletions(dc)).data.deletions.find(
    (d) => d.teamId === f.teamId,
  );
  assert.deepEqual(cleanup.secretPaths, [path]);
  assert.deepEqual(cleanup.githubPaths, [oauth]);
  await sdk.acknowledgeBillingCredentialCleanup(dc, { teamId: f.teamId, path, kind: "secret" });
  const partial = (await sdk.getDueBillingTeamDeletions(dc)).data.deletions.find(
    (d) => d.teamId === f.teamId,
  );
  assert.deepEqual(partial.secretPaths, []);
  assert.deepEqual(partial.githubPaths, [oauth]);
  await assert.rejects(sdk.completeBillingTeamCleanup(dc, { teamId: f.teamId }));
  await sdk.acknowledgeBillingCredentialCleanup(dc, {
    teamId: f.teamId,
    path: oauth,
    kind: "github",
  });
  await sdk.deferBillingTeamCleanup(dc, { teamId: f.teamId });
  assert.ok(
    !(await sdk.getDueBillingTeamDeletions(dc)).data.deletions.some((d) => d.teamId === f.teamId),
  );
  await sdk.completeBillingTeamCleanup(dc, { teamId: f.teamId });
  assert.ok(
    (await sdk.getBillingTeamDeletion(dc, { teamId: f.teamId, userId: f.userId })).data.receipt,
  );
});

test("parallel callable checkouts share one durable Stripe purchase and recover lost database replies", async (t) => {
  const f = await fixture(t);
  let customer;
  const sessions = new Map();
  const stripe = stripeFixture((r) => {
    const path = r.url.pathname;
    if (path === "/v1/prices/price_light") return price;
    if (path === "/v1/customers" && r.method === "POST") {
      customer ??= { id: `cus_${f.teamId}`, livemode: false, metadata: { team_id: f.teamId } };
      return customer;
    }
    if (path === `/v1/customers/${customer?.id}`) return customer;
    if (path === "/v1/subscriptions") return { data: [], has_more: false };
    if (path === "/v1/checkout/sessions" && r.method === "POST") {
      const key = r.headers.get("idempotency-key");
      const i = {
        ...intent(f.teamId),
        idempotencyKey: key,
        stripeCustomerId: customer.id,
        successUrl: r.body.get("success_url"),
        cancelUrl: r.body.get("cancel_url"),
      };
      if (!sessions.has(key)) sessions.set(key, { ...session(i), id: `cs_${key}` });
      return sessions.get(key);
    }
    return [...sessions.values()].find((s) => path === `/v1/checkout/sessions/${s.id}`);
  });
  const store = new BillingStore(dc);
  const record = store.recordCheckout.bind(store);
  store.recordCheckout = async (...args) => {
    await record(...args);
    throw Error("lost reply after commit");
  };
  const service = new Billing(store, stripe.stripe, config);
  const results = await Promise.all(
    [1, 2].map(() =>
      service.execute(f.userId, { action: "checkout", teamId: f.teamId, planId: "light" }),
    ),
  );
  assert.equal(results[0].url, results[1].url);
  assert.equal(sessions.size, 1);
  assert.equal(
    new Set(
      stripe.requests
        .filter((r) => r.url.pathname === "/v1/customers")
        .map((r) => r.headers.get("idempotency-key")),
    ).size,
    1,
  );
  const saved = await context(f);
  assert.equal(saved.checkout.stripeCheckoutSessionId, [...sessions.values()][0].id);
});

test("membership revoked during Stripe price lookup prevents any purchase creation", async (t) => {
  const f = await fixture(t);
  const stripe = stripeFixture(async (r) => {
    assert.equal(r.url.pathname, "/v1/prices/price_light");
    await graphql(
      `
        mutation Revoke($teamId: String!) {
          teamMember_deleteMany(where: { teamId: { eq: $teamId } })
        }
      `,
      { teamId: f.teamId },
    );
    return price;
  });
  const service = new Billing(new BillingStore(dc), stripe.stripe, config);
  await assert.rejects(
    service.execute(f.userId, { action: "checkout", teamId: f.teamId, planId: "light" }),
    /forbidden/,
  );
  assert.equal(stripe.requests.length, 1);
});

test("paid renewal, failed renewal and cancellation update callable status through the real FSC ledger", async (t) => {
  const f = await fixture(t);
  const c = await customer(f);
  const i = {
    ...intent(f.teamId),
    idempotencyKey: randomUUID(),
    stripeCustomerId: c.stripeCustomerId,
  };
  const s = {
    ...session(i),
    id: `cs_${f.teamId}`,
    status: "complete",
    subscription: `sub_${f.teamId}`,
  };
  await sdk.createBillingCheckoutCreation(dc, { ...i, userId: f.userId });
  await sdk.recordBillingCheckoutSession(dc, { ...i, stripeCheckoutSessionId: s.id });
  const sub = { ...subscription(f.teamId), id: s.subscription, customer: c.stripeCustomerId };
  sub.items.data[0].current_period_end = now + 60;
  let paid = {
    ...invoice(),
    id: `in_${f.teamId}`,
    customer: c.stripeCustomerId,
    parent: { subscription_details: { subscription: sub.id } },
  };
  paid.lines.data[0].invoice = paid.id;
  paid.lines.data[0].parent.subscription_item_details.subscription = sub.id;
  paid.lines.data[0].period.end = now + 60;
  sub.latest_invoice = paid.id;
  let at = now * 1000;
  const stripe = stripeFixture((r) => {
    if (r.url.pathname === `/v1/customers/${c.stripeCustomerId}`)
      return { id: c.stripeCustomerId, metadata: { team_id: f.teamId }, livemode: false };
    if (r.url.pathname === "/v1/subscriptions") return { data: [sub], has_more: false };
    if (r.url.pathname === "/v1/checkout/sessions") return { data: [s], has_more: false };
    if (r.url.pathname === `/v1/invoices/${paid.id}`) return paid;
  });
  const service = new Billing(new BillingStore(dc), stripe.stripe, config, () => at);
  const status = () => service.execute(f.userId, { action: "status", teamId: f.teamId });
  assert.equal((await status()).canStartCi, true);
  paid = { ...paid, id: `in_renew_${f.teamId}`, status: "open" };
  sub.latest_invoice = paid.id;
  sub.status = "past_due";
  sub.items.data[0].current_period_start = now + 60;
  sub.items.data[0].current_period_end = now + 120;
  assert.equal((await status()).canStartCi, true); // Prior paid window is retained.
  at = (now + 61) * 1000;
  assert.equal((await status()).canStartCi, false);
  paid.status = "paid";
  paid.lines.data[0].invoice = paid.id;
  paid.lines.data[0].period = { start: now + 60, end: now + 120 };
  sub.status = "active";
  assert.equal((await status()).canStartCi, true);
  sub.status = "canceled";
  const ended = await status();
  assert.equal(ended.canStartCi, false);
  assert.equal(ended.blockReason, "subscription_ended");
});
