import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { test } from "node:test";

// Never run these fixture-writing tests against a real Firebase project.
const host = process.env.DATA_CONNECT_EMULATOR_HOST;
assert.match(
  host ?? "",
  /^(127\.0\.0\.1|localhost):\d+$/,
  "Start the SQL Connect emulator first",
);
const service = `http://${host}/v1/projects/demo-openci/locations/asia-northeast1/services/openci-b1b91-service`;

async function request(path, body) {
  const response = await fetch(service + path, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(15000),
  });
  const result = await response.json();
  const errors = result.errors ?? result.details ?? [];
  const message = [
    result.message,
    ...errors.map(
      (error) => `${error.extensions?.code ?? ""}: ${error.message}`,
    ),
  ]
    .filter(Boolean)
    .join("\n");
  if (!response.ok || result.errors?.length) {
    throw new Error(message, { cause: result.data });
  }
  return result.data;
}

function graphql(query, variables) {
  return request(":executeGraphql", { query, variables });
}

function operation(kind, operationName, variables, actor) {
  const impersonate =
    actor === null
      ? { unauthenticated: true }
      : {
          authClaims:
            typeof actor === "string"
              ? { sub: actor, firebase: { sign_in_provider: "password" } }
              : actor,
        };
  return request(`/connectors/logs:impersonate${kind}`, {
    operationName,
    variables,
    // Omitting impersonation uses the privileged Admin path in the emulator.
    ...(actor === undefined ? {} : { extensions: { impersonate } }),
  });
}

async function fixture(t) {
  const prefix = randomUUID();
  const f = {
    teamId: `${prefix}-team`,
    otherTeamId: `${prefix}-other-team`,
    user: `${prefix}-user`,
    otherUser: `${prefix}-other-user`,
    jobId: `${prefix}-job`,
    otherJobId: `${prefix}-other-job`,
    runId: `${prefix}-run`,
    siblingRunId: `${prefix}-sibling`,
    otherRunId: `${prefix}-other-run`,
  };
  t.after(() =>
    graphql(
      `
        mutation Cleanup($jobs: [String!]!, $teams: [String!]!) @transaction {
          buildJob_deleteMany(where: { id: { in: $jobs } })
          team_deleteMany(where: { id: { in: $teams } })
        }
      `,
      { jobs: [f.jobId, f.otherJobId], teams: [f.teamId, f.otherTeamId] },
    ),
  );
  await graphql(
    `
      mutation Seed(
        $teamId: String!
        $otherTeamId: String!
        $user: String!
        $otherUser: String!
        $jobId: String!
        $otherJobId: String!
        $runId: String!
        $siblingRunId: String!
        $otherRunId: String!
      ) @transaction {
        team: team_insert(
          data: { id: $teamId, name: "Test", createdAt: 1, updatedAt: 1 }
        )
        otherTeam: team_insert(
          data: { id: $otherTeamId, name: "Other", createdAt: 1, updatedAt: 1 }
        )
        member: teamMember_insert(data: { teamId: $teamId, userId: $user })
        otherMember: teamMember_insert(
          data: { teamId: $otherTeamId, userId: $otherUser }
        )
        job: buildJob_insert(
          data: {
            id: $jobId
            teamId: $teamId
            status: "IN_PROGRESS"
            owner: "test"
            repo: "test"
            workflowName: "Test"
            workflowFileName: "test.dart"
            createdAt: 1
            updatedAt: 1
          }
        )
        otherJob: buildJob_insert(
          data: {
            id: $otherJobId
            teamId: $otherTeamId
            status: "IN_PROGRESS"
            owner: "test"
            repo: "test"
            workflowName: "Test"
            workflowFileName: "test.dart"
            createdAt: 1
            updatedAt: 1
          }
        )
        run: buildRun_insert(
          data: {
            id: $runId
            buildJobId: $jobId
            status: "in_progress"
            createdAt: 1
            updatedAt: 1
          }
        )
        sibling: buildRun_insert(
          data: {
            id: $siblingRunId
            buildJobId: $jobId
            status: "in_progress"
            createdAt: 1
            updatedAt: 1
          }
        )
        otherRun: buildRun_insert(
          data: {
            id: $otherRunId
            buildJobId: $otherJobId
            status: "in_progress"
            createdAt: 1
            updatedAt: 1
          }
        )
      }
    `,
    f,
  );
  return f;
}

function log(f, sequence = 1, overrides = {}) {
  return {
    runId: f.runId,
    sequence: String(sequence),
    logId: randomUUID(),
    source: "worker",
    stream: "stdout",
    message: `line ${sequence}`,
    occurredAt: "2026-01-01T01:02:03.123456Z",
    ...overrides,
  };
}

function append(f, logs, overrides = {}, actor) {
  return operation(
    "Mutation",
    "AppendBuildLogs",
    {
      teamId: f.teamId,
      runId: f.runId,
      expectedLastSequence: "0",
      logs,
      ...overrides,
    },
    actor,
  );
}

async function writeState(f, logIds = []) {
  return (
    await operation("Query", "GetBuildLogWriteState", {
      teamId: f.teamId,
      runId: f.runId,
      logIds,
    })
  ).run;
}

function createStep(f, overrides = {}, actor) {
  return operation(
    "Mutation",
    "CreateBuildStep",
    {
      teamId: f.teamId,
      runId: f.runId,
      stepId: "build",
      name: "Build",
      stepOrder: 0,
      ...overrides,
    },
    actor,
  );
}

function updateStep(f, overrides = {}, actor) {
  return operation(
    "Mutation",
    "UpdateBuildStep",
    {
      teamId: f.teamId,
      runId: f.runId,
      stepId: "build",
      status: "SUCCESS",
      durationMs: "100",
      ...overrides,
    },
    actor,
  );
}

async function stepState(f, stepId = "build") {
  return (
    await operation("Query", "GetBuildStepWriteState", {
      teamId: f.teamId,
      runId: f.runId,
      stepId,
    })
  ).run.steps;
}

async function readLogs(f, overrides = {}, actor = f.user) {
  return (
    await operation(
      "Query",
      "GetBuildLogs",
      { teamId: f.teamId, runId: f.runId, ...overrides },
      actor,
    )
  ).run;
}

test("batch commit uses server timestamps and sequence cursor pagination", async (t) => {
  const f = await fixture(t);
  const first = log(f, 1, { message: "開始\ncheckout" });
  const second = log(f, 2, {
    message: "",
    stream: "stderr",
    source: "workflow",
  });
  await append(f, [second, first]);
  const page = await readLogs(f, { limit: 1 });
  assert.equal(page.lastLogSequence, "2");
  assert.equal(page.logsExpireAt, null);
  assert.equal(page.logs[0].logId, first.logId.replaceAll("-", ""));
  assert.equal(page.logs[0].message, first.message);
  assert.equal(page.logs[0].occurredAt, first.occurredAt);
  assert.ok(Date.parse(page.logs[0].createdAt) > Date.parse(first.occurredAt));
  assert.equal(page.logs[0].stepId, null);
  const next = await readLogs(f, {
    afterSequence: page.logs[0].sequence,
    limit: 1,
  });
  assert.equal(next.logs[0].logId, second.logId.replaceAll("-", ""));
  assert.deepEqual((await readLogs(f, { afterSequence: "2" })).logs, []);
  assert.equal(
    (await writeState(f, [first.logId, second.logId])).logs.length,
    2,
  );
});

test("queries reject unauthenticated, anonymous and other-team users", async (t) => {
  const f = await fixture(t);
  await append(f, [log(f)]);
  await assert.rejects(readLogs(f, {}, null), /auth|UNAUTHENTICATED/);
  await assert.rejects(
    readLogs(
      f,
      {},
      { sub: f.user, firebase: { sign_in_provider: "anonymous" } },
    ),
    /auth|PERMISSION_DENIED/,
  );
  await assert.rejects(readLogs(f, {}, f.otherUser), (error) => {
    assert.match(error.message, /Team access denied/);
    assert.equal(
      error.cause?.run ?? null,
      null,
      "An authorization error must not include logs",
    );
    return true;
  });
  await assert.rejects(readLogs(f, { runId: f.otherRunId }), /Run not found/);
  await assert.rejects(
    operation(
      "Query",
      "GetBuildSteps",
      { teamId: f.teamId, runId: f.runId },
      f.otherUser,
    ),
    /Team access denied/,
  );
  await assert.rejects(
    operation(
      "Query",
      "GetBuildSteps",
      { teamId: f.teamId, runId: f.otherRunId },
      f.user,
    ),
    /Run not found/,
  );
  await graphql(
    "mutation($team: String!) { teamMember_deleteMany(where: {teamId: {eq: $team}}) }",
    { team: f.teamId },
  );
  await assert.rejects(readLogs(f), /Team access denied/);
});

test("all mutations and recovery queries are server-only", async (t) => {
  const f = await fixture(t);
  await assert.rejects(createStep(f, {}, f.user), /NO_ACCESS|auth/);
  await assert.rejects(updateStep(f, {}, f.user), /NO_ACCESS|auth/);
  await assert.rejects(append(f, [log(f)], {}, f.user), /NO_ACCESS|auth/);
  await assert.rejects(
    operation(
      "Query",
      "GetBuildLogWriteState",
      { teamId: f.teamId, runId: f.runId, logIds: [] },
      f.user,
    ),
    /NO_ACCESS|auth/,
  );
  await assert.rejects(
    operation(
      "Query",
      "GetBuildStepWriteState",
      { teamId: f.teamId, runId: f.runId, stepId: "build" },
      f.user,
    ),
    /NO_ACCESS|auth/,
  );
  assert.equal((await writeState(f)).lastLogSequence, "0");
});

test("step listing has deterministic order and pagination", async (t) => {
  const f = await fixture(t);
  await createStep(f, { stepId: "z", stepOrder: 1 });
  await createStep(f, { stepId: "b", stepOrder: 0 });
  await createStep(f, { stepId: "a", stepOrder: 0 });
  const vars = { teamId: f.teamId, runId: f.runId, limit: 2 };
  const page = await operation("Query", "GetBuildSteps", vars, f.user);
  assert.deepEqual(
    page.run.steps.map((s) => s.stepId),
    ["a", "b"],
  );
  assert.equal(page.run.steps[0].durationMs, "0");
  assert.equal(page.run.steps[0].status, "IN_PROGRESS");
  assert.equal(page.run.steps[0].createdAt, page.run.steps[0].updatedAt);
  const next = await operation(
    "Query",
    "GetBuildSteps",
    { ...vars, offset: 2 },
    f.user,
  );
  assert.deepEqual(
    next.run.steps.map((s) => s.stepId),
    ["z"],
  );
});

test("step creation rejects invalid metadata and never overwrites a duplicate", async (t) => {
  const f = await fixture(t);
  await assert.rejects(createStep(f, { stepId: " " }), /Invalid step/);
  await assert.rejects(createStep(f, { name: " " }), /Invalid step/);
  await assert.rejects(createStep(f, { stepOrder: -1 }), /Invalid step/);
  await assert.rejects(
    createStep(f, { name: "a".repeat(1025) }),
    /Invalid step/,
  );
  await createStep(f);
  await assert.rejects(
    createStep(f, { name: "Replacement" }),
    /duplicate|unique/i,
  );
  assert.equal((await stepState(f))[0].name, "Build");
});

test("step updates reject duration regression and preserve terminal state on retries", async (t) => {
  const f = await fixture(t);
  await createStep(f);
  await assert.rejects(updateStep(f, { status: "BAD" }), /Invalid step/);
  await assert.rejects(updateStep(f, { durationMs: "-1" }), /Invalid step/);
  await updateStep(f, { status: "IN_PROGRESS", durationMs: "100" });
  await assert.rejects(
    updateStep(f, { status: "IN_PROGRESS", durationMs: "50" }),
    /stale/,
  );
  await updateStep(f, { durationMs: "200" });
  const saved = (await stepState(f))[0];
  await assert.rejects(
    updateStep(f, { status: "IN_PROGRESS", durationMs: "300" }),
    /finished/,
  );
  await assert.rejects(
    updateStep(f, { status: "FAILURE", durationMs: "200" }),
    /finished/,
  );
  await assert.rejects(updateStep(f, { durationMs: "200" }), /finished/);
  await assert.rejects(createStep(f), /duplicate|unique/i);
  assert.deepEqual((await stepState(f))[0], saved);
});

test("concurrent terminal step updates commit only one outcome", async (t) => {
  const f = await fixture(t);
  await createStep(f);
  const outcomes = await Promise.allSettled([
    updateStep(f),
    updateStep(f, { status: "FAILURE" }),
  ]);
  assert.equal(outcomes.filter((r) => r.status === "fulfilled").length, 1);
  assert.equal(
    (await stepState(f))[0].status,
    outcomes[0].status === "fulfilled" ? "SUCCESS" : "FAILURE",
  );
});

test("writes cannot cross team or run boundaries", async (t) => {
  const f = await fixture(t);
  await createStep(f);
  await assert.rejects(
    createStep(f, { teamId: f.otherTeamId, stepId: "other" }),
    /this team/,
  );
  await assert.rejects(updateStep(f, { teamId: f.otherTeamId }), /this team/);
  await assert.rejects(
    append(f, [log(f)], { teamId: f.otherTeamId }),
    /this team/,
  );
  await assert.rejects(
    append(f, [log(f, 1, { runId: f.otherRunId })]),
    /does not match/,
  );
  await assert.rejects(
    operation("Query", "GetBuildLogWriteState", {
      teamId: f.otherTeamId,
      runId: f.runId,
      logIds: [],
    }),
    /Run not found/,
  );
  assert.equal((await writeState(f)).lastLogSequence, "0");
});

test("batch step must exist in the same run and match every entry", async (t) => {
  const f = await fixture(t);
  await createStep(f, { runId: f.siblingRunId });
  const entry = log(f, 1, { stepId: "build" });
  await assert.rejects(
    append(f, [entry], { stepId: "build" }),
    /Step does not belong/,
  );
  await createStep(f);
  await assert.rejects(append(f, [entry]), /does not match/);
  await assert.rejects(
    append(f, [log(f)], { stepId: "build" }),
    /does not match/,
  );
  await append(f, [entry], { stepId: "build" });
  assert.equal((await readLogs(f)).logs[0].stepId, "build");
});

test("empty and oversized batches are rejected; 100 entries are allowed", async (t) => {
  const f = await fixture(t);
  await assert.rejects(append(f, []), /batch size/);
  await assert.rejects(
    append(
      f,
      Array.from({ length: 101 }, (_, i) => log(f, i + 1)),
    ),
    /100|maxCount|size|maximum/i,
  );
  assert.equal((await writeState(f)).lastLogSequence, "0");
  await append(
    f,
    Array.from({ length: 100 }, (_, i) => log(f, i + 1)),
  );
  assert.equal((await readLogs(f, { limit: 200 })).logs.length, 100);
});

test("message limit counts UTF-8 bytes", async (t) => {
  const f = await fixture(t);
  await assert.rejects(
    append(f, [log(f, 1, { message: "あ".repeat(5462) })]),
    /Invalid log/,
  );
  await append(f, [log(f, 1, { message: "あ".repeat(5461) + "a" })]);
  assert.equal(Buffer.byteLength((await readLogs(f)).logs[0].message), 16384);
});

test("invalid fields and sender-supplied server timestamps are rejected atomically", async (t) => {
  const f = await fixture(t);
  await assert.rejects(
    append(f, [log(f, 1, { source: "bad" })]),
    /Invalid log/,
  );
  await assert.rejects(
    append(f, [log(f, 1, { stream: "bad" })]),
    /Invalid log/,
  );
  await assert.rejects(
    append(f, [log(f, 1, { occurredAt: null })]),
    /Invalid log|INVALID_ARGUMENT/,
  );
  await assert.rejects(
    append(f, [log(f, 1, { message: null })]),
    /Invalid log|INVALID_ARGUMENT/,
  );
  await assert.rejects(append(f, [log(f, 1, { sequence: null })]));
  await assert.rejects(
    append(f, [log(f, 1, { createdAt: "2020-01-01T00:00:00Z" })]),
    /createdAt|allow/,
  );
  const missing = log(f);
  delete missing.message;
  await assert.rejects(append(f, [missing]), /Invalid log|INVALID_ARGUMENT/);
  assert.equal((await writeState(f)).lastLogSequence, "0");
  assert.deepEqual((await readLogs(f)).logs, []);
});

test("duplicate sequence or log ID rolls back the whole batch and counter", async (t) => {
  const f = await fixture(t);
  await assert.rejects(append(f, [log(f), log(f)]), /duplicate|unique/i);
  const first = log(f);
  await assert.rejects(
    append(f, [first, log(f, 2, { logId: first.logId })]),
    /duplicate|unique/i,
  );
  assert.equal((await writeState(f)).lastLogSequence, "0");
  assert.deepEqual((await readLogs(f)).logs, []);
});

test("retries recover saved payload without replacing it or partially appending", async (t) => {
  const f = await fixture(t);
  const original = log(f);
  await append(f, [original]);
  const saved = (await writeState(f, [original.logId])).logs[0];
  // No key collision: this must fail the counter condition itself.
  const skipped = log(f, 3);
  await assert.rejects(
    append(f, [skipped], { expectedLastSequence: "2" }),
    /sequence changed/,
  );
  await assert.rejects(
    append(f, [original]),
    /sequence changed|unique constraint/,
  );
  const fresh = log(f, 2);
  await assert.rejects(
    append(f, [fresh, { ...original, sequence: "3", message: "changed" }], {
      expectedLastSequence: "1",
    }),
    /duplicate|unique/i,
  );
  const state = await writeState(f, [
    original.logId,
    fresh.logId,
    skipped.logId,
  ]);
  assert.equal(state.lastLogSequence, "1");
  assert.deepEqual(state.logs, [saved]);
});

test("concurrent appends have one winner and the loser can retry with fresh state", async (t) => {
  const f = await fixture(t);
  const first = log(f);
  const second = log(f);
  const results = await Promise.allSettled([
    append(f, [first]),
    append(f, [second]),
  ]);
  assert.equal(results.filter((r) => r.status === "fulfilled").length, 1);
  const state = await writeState(f, [first.logId, second.logId]);
  assert.equal(state.lastLogSequence, "1");
  assert.equal(state.logs.length, 1);
  const loser = results[0].status === "fulfilled" ? second : first;
  await append(f, [{ ...loser, sequence: "2" }], {
    expectedLastSequence: state.lastLogSequence,
  });
  const after = await readLogs(f);
  assert.equal(after.lastLogSequence, "2");
  assert.deepEqual(
    after.logs.map((l) => l.sequence),
    ["1", "2"],
  );
});

test("sequence gaps and overflow are rejected; Int64 precision is preserved", async (t) => {
  const f = await fixture(t);
  await assert.rejects(append(f, [log(f, 2)]), /sequence does not match/);
  await assert.rejects(
    append(f, [log(f)], { expectedLastSequence: "-1" }),
    /Invalid batch/,
  );
  await assert.rejects(
    append(f, [log(f)], { expectedLastSequence: "9223372036854775807" }),
    /Invalid batch/,
  );
  await graphql(
    'mutation($id: String!) { buildRun_update(id: $id, data: {lastLogSequence: "9007199254740992"}) }',
    { id: f.runId },
  );
  await append(f, [log(f, "9007199254740993")], {
    expectedLastSequence: "9007199254740992",
  });
  assert.equal((await writeState(f)).lastLogSequence, "9007199254740993");
  assert.equal(
    (await readLogs(f, { afterSequence: "9007199254740992" })).logs[0].sequence,
    "9007199254740993",
  );
});

test("expired retention rejects writes without preventing historical reads", async (t) => {
  const f = await fixture(t);
  await graphql(
    'mutation($id: String!) { buildRun_update(id: $id, data: {logsExpireAt: "2100-01-01T00:00:00Z"}) }',
    { id: f.runId },
  );
  await createStep(f);
  await append(f, [log(f)]);
  await graphql(
    'mutation($id: String!) { buildRun_update(id: $id, data: {logsExpireAt: "2020-01-01T00:00:00Z"}) }',
    { id: f.runId },
  );
  await assert.rejects(
    append(f, [log(f, 2)], { expectedLastSequence: "1" }),
    /retention has expired/,
  );
  await assert.rejects(
    createStep(f, { stepId: "late" }),
    /retention has expired/,
  );
  await assert.rejects(updateStep(f), /retention has expired/);
  assert.equal((await readLogs(f)).logs.length, 1);
});

test("query pagination and recovery sizes are bounded", async (t) => {
  const f = await fixture(t);
  await assert.rejects(readLogs(f, { limit: 0 }), /auth/);
  await assert.rejects(readLogs(f, { limit: 201 }), /auth/);
  await assert.rejects(readLogs(f, { limit: null }));
  await assert.rejects(readLogs(f, { afterSequence: "-1" }), /auth/);
  await assert.rejects(
    operation(
      "Query",
      "GetBuildSteps",
      { teamId: f.teamId, runId: f.runId, offset: -1 },
      f.user,
    ),
  );
  await assert.rejects(
    writeState(
      f,
      Array.from({ length: 101 }, () => randomUUID()),
    ),
    /Too many log IDs/,
  );
});
