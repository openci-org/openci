import assert from "node:assert/strict";
import { createHash, randomUUID } from "node:crypto";
import { createRequire } from "node:module";
import { after, test } from "node:test";
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getDataConnect } from "firebase-admin/data-connect";
import * as sdk from "@openci/github-admin";
import { GitHubConnections } from "../../lib/functions/github_connection/service.js";
import { GitHubConnectionStore } from "../../lib/functions/github_connection/store.js";

// Never use fixture mutations against a real project or remote emulator.
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

function hash(value) {
  return createHash("sha256").update(value).digest("hex");
}

test("GitHub Functions context rejects outsiders and direct client execution", async (t) => {
  const f = await fixture(t);
  assert.ok(
    (await sdk.getGitHubConnectionContext(dc, { teamId: f.teamId, userId: f.userId })).data
      .teamMember,
  );
  await assert.rejects(
    sdk.getGitHubConnectionContext(dc, { teamId: f.teamId, userId: "outsider" }),
    /Team access denied/,
  );
  await assert.rejects(
    sdk.getGitHubConnectionContext(dc, { teamId: f.teamId, userId: f.userId }, asUser(f.userId)),
    /permission|unauthoriz|access/i,
  );
});

test("Functions connection flow writes FSC through the generated SDK without returning credentials", async (t) => {
  const f = await fixture(t);
  const config = {
    apiBaseUrl: f.githubApiBaseUrl,
    baseUrl: "https://github.com",
    appId: f.githubAppId,
    clientId: "client",
    clientSecret: "secret",
    callbackUrl: "https://functions.test/githubConnectionCallback",
    returnUrl: "https://dashboard.test/github/connection",
  };
  const credentials = new Map();
  const vault = {
    async create(value) {
      const path = `projects/demo-openci/secrets/openci-github-${randomUUID()}/versions/1`;
      credentials.set(path, value);
      return path;
    },
    async read(path) {
      assert.ok(credentials.has(path));
      return credentials.get(path);
    },
    async destroy(path) {
      credentials.delete(path);
    },
  };
  const github = {
    async exchange(code, verifier) {
      assert.equal(code, "github-code");
      assert.match(verifier, /^[\w-]{43}$/);
      return "github-private-token";
    },
    async user() {
      return 123;
    },
    async candidates(token, userId) {
      assert.equal(token, "github-private-token");
      assert.equal(userId, "123");
      return [
        {
          installationId: 100,
          accountId: 200,
          accountLogin: "verified-org",
          accountType: "Organization",
        },
      ];
    },
  };
  const service = new GitHubConnections(
    config,
    new GitHubConnectionStore(dc, config),
    vault,
    github,
  );
  const start = await service.execute(f.userId, { action: "start", teamId: f.teamId });
  const state = new URL(start.authorizationUrl).searchParams.get("state");
  const callback = new URLSearchParams({ state, code: "github-code" });
  const redirect = await service.callback(callback);
  const reference = new URLSearchParams(new URL(redirect).hash.slice(1)).get("reference");
  assert.match(reference, /^[\w-]{43}$/);
  const input = { teamId: f.teamId, reference };
  assert.equal(
    (await service.execute(f.userId, { ...input, action: "session" })).session.githubUserId,
    123,
  );
  // Another member of the same team does not own this OAuth session.
  await assert.rejects(
    service.execute(f.otherUserId, { ...input, action: "candidates" }),
    /Restart/,
  );
  assert.equal(
    (await service.execute(f.userId, { ...input, action: "candidates" })).candidates[0]
      .accountLogin,
    "verified-org",
  );
  assert.deepEqual(
    await service.execute(f.userId, { ...input, action: "confirm", installationId: 100 }),
    { success: true },
  );
  const connections = (await sdk.getGitHubConnections(dc, { teamId: f.teamId }, asUser(f.userId)))
    .data.connections;
  assert.equal(connections[0].githubAppId, f.githubAppId);
  assert.equal(connections[0].accountId, "200");
  assert.doesNotMatch(
    JSON.stringify(connections),
    /github-private-token|referenceHash|SecretVersionPath/,
  );
  assert.equal(credentials.size, 0);
  assert.match(await service.callback(callback), /error=invalid_state$/);
});

function asUser(uid, provider = "password") {
  return { impersonate: { authClaims: { sub: uid, firebase: { sign_in_provider: provider } } } };
}

async function fixture(t) {
  const id = randomUUID();
  const f = {
    teamId: `${id}-team`,
    otherTeamId: `${id}-other`,
    userId: `${id}-user`,
    otherUserId: `${id}-other-user`,
    githubApiBaseUrl: "https://api.github.com",
    githubAppId: BigInt(`0x${id.replaceAll("-", "").slice(0, 12)}`).toString(),
  };
  t.after(() =>
    graphql(
      `
        mutation Cleanup($ids: [String!]!) {
          team_deleteMany(where: { id: { in: $ids } })
        }
      `,
      { ids: [f.teamId, f.otherTeamId] },
    ),
  );
  await graphql(
    `
      mutation Seed(
        $teamId: String!
        $otherTeamId: String!
        $userId: String!
        $otherUserId: String!
      ) @transaction {
        team_insertMany(
          data: [
            { id: $teamId, name: "Team", createdAt: 1, updatedAt: 1 }
            { id: $otherTeamId, name: "Other", createdAt: 1, updatedAt: 1 }
          ]
        )
        teamMember_insertMany(
          data: [
            { teamId: $teamId, userId: $userId }
            { teamId: $teamId, userId: $otherUserId }
            { teamId: $otherTeamId, userId: $otherUserId }
          ]
        )
      }
    `,
    { teamId: f.teamId, otherTeamId: f.otherTeamId, userId: f.userId, otherUserId: f.otherUserId },
  );
  return f;
}

function requestInput(f) {
  const id = randomUUID();
  return {
    id,
    userId: f.userId,
    teamId: f.teamId,
    stateHash: hash(id),
    codeVerifierSecretVersionPath: `projects/demo-openci/secrets/pkce-${id}/versions/1`,
  };
}

function sessionInput(f) {
  const id = randomUUID();
  return {
    id,
    userId: f.userId,
    teamId: f.teamId,
    githubUserId: "9007199254740993",
    referenceHash: hash(id),
    accessTokenSecretVersionPath: `projects/demo-openci/locations/asia-northeast1/secrets/token-${id}/versions/1`,
  };
}

async function session(f) {
  const input = sessionInput(f);
  await sdk.createGitHubConnectionSession(dc, input);
  return input;
}

function confirmation(f, s, installationId = "100") {
  return {
    teamId: f.teamId,
    userId: f.userId,
    referenceHash: s.referenceHash,
    githubApiBaseUrl: f.githubApiBaseUrl,
    githubAppId: f.githubAppId,
    installationId,
    accountId: "200",
    accountType: "Organization",
    accountLogin: "test-org",
  };
}

function sessionKey(s) {
  return { teamId: s.teamId, userId: s.userId, referenceHash: s.referenceHash };
}

function installationKey(f, installationId = "100") {
  return { githubApiBaseUrl: f.githubApiBaseUrl, githubAppId: f.githubAppId, installationId };
}

async function storedSession(s) {
  return (
    await graphql(
      `
        query Read($id: String!) {
          gitHubConnectionSession(key: { id: $id }) {
            createdAt
            expiresAt
            consumedAt
            accessTokenSecretVersionPath
          }
        }
      `,
      { id: s.id },
    )
  ).gitHubConnectionSession;
}

test("members list only their team's connection metadata in account order", async (t) => {
  const f = await fixture(t);
  await sdk.confirmGitHubConnection(dc, {
    ...confirmation(f, await session(f)),
    accountLogin: "z-org",
  });
  await sdk.confirmGitHubConnection(dc, {
    ...confirmation(f, await session(f), "101"),
    accountLogin: "a-org",
  });
  const other = { ...f, teamId: f.otherTeamId, userId: f.otherUserId };
  await sdk.confirmGitHubConnection(dc, confirmation(other, await session(other), "102"));
  const { data } = await sdk.getGitHubConnections(dc, { teamId: f.teamId }, asUser(f.userId));
  assert.deepEqual(Object.keys(data), ["connections"]);
  assert.deepEqual(
    data.connections.map((row) => row.accountLogin),
    ["a-org", "z-org"],
  );
  for (const row of data.connections) {
    assert.equal(row.teamId, f.teamId);
    assert.deepEqual(Object.keys(row).sort(), [
      "accountId",
      "accountLogin",
      "accountType",
      "githubApiBaseUrl",
      "githubAppId",
      "id",
      "installationId",
      "status",
      "teamId",
      "verifiedAt",
    ]);
  }
});

test("lists include more than 100 connections; active lookups match host and app", async (t) => {
  const f = await fixture(t);
  const rows = Array.from({ length: 101 }, (_, i) => ({
    id: randomUUID(),
    teamId: f.teamId,
    ...installationKey(f, String(i + 1)),
    accountId: "1",
    accountType: "User",
    accountLogin: `user-${String(i).padStart(3, "0")}`,
    verifiedByUserId: f.userId,
    verifiedByGitHubUserId: "1",
    verifiedAt: "1",
    status: "active",
  }));
  for (let offset = 0; offset < rows.length; offset += 100) {
    await graphql(
      `
        mutation Seed($rows: [GitHubConnection_Data!]!) {
          gitHubConnection_insertMany(data: $rows)
        }
      `,
      { rows: rows.slice(offset, offset + 100) },
    );
  }
  assert.equal(
    (await sdk.getGitHubConnections(dc, { teamId: f.teamId }, asUser(f.userId))).data.connections
      .length,
    101,
  );
  assert.equal(
    (await sdk.getActiveGitHubConnection(dc, installationKey(f, "1"))).data.connection.teamId,
    f.teamId,
  );
  assert.equal(
    (await sdk.getActiveGitHubConnection(dc, { ...installationKey(f, "1"), githubAppId: "0" })).data
      .connection,
    null,
  );
  assert.equal(
    (
      await sdk.getActiveGitHubConnection(dc, {
        ...installationKey(f, "1"),
        githubApiBaseUrl: "https://other.example/api/v3",
      })
    ).data.connection,
    null,
  );
  for (const status of ["suspended", "removed"]) {
    await graphql(
      `
        mutation Suspend($id: String!, $status: String!) {
          gitHubConnection_update(key: { id: $id }, data: { status: $status })
        }
      `,
      { id: rows[0].id, status },
    );
    assert.equal(
      (await sdk.getActiveGitHubConnection(dc, installationKey(f, "1"))).data.connection,
      null,
    );
  }
});

test("unauthenticated, anonymous, other-team and removed-member reads are rejected", async (t) => {
  const f = await fixture(t);
  const variables = { teamId: f.teamId };
  assert.deepEqual(
    (await sdk.getGitHubConnections(dc, variables, asUser(f.userId))).data.connections,
    [],
  );
  await assert.rejects(
    sdk.getGitHubConnections(dc, variables, { impersonate: { unauthenticated: true } }),
  );
  await assert.rejects(sdk.getGitHubConnections(dc, variables, asUser(f.userId, "anonymous")));
  await assert.rejects(sdk.getGitHubConnections(dc, variables, asUser("outsider")));
  await assert.rejects(sdk.getGitHubConnections(dc, { teamId: f.otherTeamId }, asUser(f.userId)));
  await graphql(
    `
      mutation Remove($teamId: String!) {
        teamMember_deleteMany(where: { teamId: { eq: $teamId } })
      }
    `,
    variables,
  );
  await assert.rejects(sdk.getGitHubConnections(dc, variables, asUser(f.userId)));
});

test("all nine administrative operations reject client calls without modifying credentials", async (t) => {
  const f = await fixture(t);
  const r = requestInput(f);
  const s = await session(f);
  await sdk.createGitHubConnectionRequest(dc, r);
  for (const actor of [
    asUser(f.userId),
    asUser(f.userId, "anonymous"),
    { impersonate: { unauthenticated: true } },
  ]) {
    await assert.rejects(sdk.createGitHubConnectionRequest(dc, requestInput(f), actor));
    await assert.rejects(sdk.consumeGitHubConnectionRequest(dc, { stateHash: r.stateHash }, actor));
    await assert.rejects(sdk.createGitHubConnectionSession(dc, sessionInput(f), actor));
    await assert.rejects(sdk.getGitHubConnectionSession(dc, sessionKey(s), actor));
    await assert.rejects(sdk.confirmGitHubConnection(dc, confirmation(f, s), actor));
    await assert.rejects(sdk.getActiveGitHubConnection(dc, installationKey(f), actor));
    await assert.rejects(sdk.getExpiredGitHubConnectionCredentials(dc, actor));
    await assert.rejects(sdk.deleteExpiredGitHubConnectionRequest(dc, { id: r.id }, actor));
    await assert.rejects(sdk.deleteExpiredGitHubConnectionSession(dc, { id: s.id }, actor));
  }
  assert.equal((await storedSession(s)).consumedAt, null);
  assert.equal(
    (await sdk.consumeGitHubConnectionRequest(dc, { stateHash: r.stateHash })).data.query.request
      .id,
    r.id,
  );
});

test("request creation validates hashes, paths and membership and uses a ten-minute lifetime", async (t) => {
  const f = await fixture(t);
  const r = requestInput(f);
  await sdk.createGitHubConnectionRequest(dc, r);
  const stored = (
    await graphql(
      `
        query Read($id: String!) {
          gitHubConnectionRequest(key: { id: $id }) {
            createdAt
            expiresAt
          }
        }
      `,
      { id: r.id },
    )
  ).gitHubConnectionRequest;
  assert.equal(BigInt(stored.expiresAt) - BigInt(stored.createdAt), 600n);
  await assert.rejects(sdk.createGitHubConnectionRequest(dc, r));
  await assert.rejects(
    sdk.createGitHubConnectionRequest(dc, { ...requestInput(f), stateHash: r.stateHash }),
  );
  await assert.rejects(
    sdk.createGitHubConnectionRequest(dc, { ...requestInput(f), stateHash: "raw-state" }),
  );
  await assert.rejects(
    sdk.createGitHubConnectionRequest(dc, {
      ...requestInput(f),
      codeVerifierSecretVersionPath: "plaintext-verifier",
    }),
  );
  await assert.rejects(
    sdk.createGitHubConnectionRequest(dc, {
      ...requestInput(f),
      codeVerifierSecretVersionPath: r.codeVerifierSecretVersionPath.replace("/1", "/latest"),
    }),
  );
  await assert.rejects(
    sdk.createGitHubConnectionRequest(dc, { ...requestInput(f), teamId: f.otherTeamId }),
  );
});

test("a request can be consumed only once, including simultaneous callbacks", async (t) => {
  const f = await fixture(t);
  const r = requestInput(f);
  await sdk.createGitHubConnectionRequest(dc, r);
  const results = await Promise.allSettled([
    sdk.consumeGitHubConnectionRequest(dc, { stateHash: r.stateHash }),
    sdk.consumeGitHubConnectionRequest(dc, { stateHash: r.stateHash }),
  ]);
  assert.equal(results.filter((r) => r.status === "fulfilled").length, 1);
  const success = results.find((r) => r.status === "fulfilled").value;
  assert.equal(
    success.data.query.request.codeVerifierSecretVersionPath,
    r.codeVerifierSecretVersionPath,
  );
  await assert.rejects(sdk.consumeGitHubConnectionRequest(dc, { stateHash: r.stateHash }));
});

test("expired requests cannot be consumed", async (t) => {
  const f = await fixture(t);
  const r = requestInput(f);
  await sdk.createGitHubConnectionRequest(dc, r);
  await graphql(
    `
      mutation Expire($id: String!) {
        gitHubConnectionRequest_update(key: { id: $id }, data: { expiresAt: 1 })
      }
    `,
    { id: r.id },
  );
  await assert.rejects(sdk.consumeGitHubConnectionRequest(dc, { stateHash: r.stateHash }));
});

test("sessions validate credentials, expire after ten minutes and bind user and team", async (t) => {
  const f = await fixture(t);
  const s = await session(f);
  const stored = await storedSession(s);
  assert.equal(BigInt(stored.expiresAt) - BigInt(stored.createdAt), 600n);
  assert.equal(stored.consumedAt, null);
  assert.equal(
    (await sdk.getGitHubConnectionSession(dc, sessionKey(s))).data.session.githubUserId,
    s.githubUserId,
  );
  assert.equal(
    (await sdk.getGitHubConnectionSession(dc, { ...sessionKey(s), userId: f.otherUserId })).data
      .session,
    null,
  );
  assert.equal(
    (
      await sdk.getGitHubConnectionSession(dc, {
        ...sessionKey(s),
        teamId: f.otherTeamId,
        userId: f.otherUserId,
      })
    ).data.session,
    null,
  );
  await assert.rejects(sdk.createGitHubConnectionSession(dc, s));
  await assert.rejects(
    sdk.createGitHubConnectionSession(dc, { ...sessionInput(f), referenceHash: s.referenceHash }),
  );
  await assert.rejects(
    sdk.createGitHubConnectionSession(dc, { ...sessionInput(f), referenceHash: "raw-reference" }),
  );
  await assert.rejects(
    sdk.createGitHubConnectionSession(dc, { ...sessionInput(f), githubUserId: "0" }),
  );
  await assert.rejects(
    sdk.createGitHubConnectionSession(dc, {
      ...sessionInput(f),
      accessTokenSecretVersionPath: "plaintext-token",
    }),
  );
  await assert.rejects(
    sdk.createGitHubConnectionSession(dc, { ...sessionInput(f), teamId: f.otherTeamId }),
  );
});

test("confirmation atomically saves the connection and consumes and clears its session", async (t) => {
  const f = await fixture(t);
  const s = await session(f);
  const result = await sdk.confirmGitHubConnection(dc, confirmation(f, s));
  assert.equal(
    result.data.query.session.accessTokenSecretVersionPath,
    s.accessTokenSecretVersionPath,
  );
  const stored = await storedSession(s);
  assert.ok(Number(stored.consumedAt) > 0);
  assert.equal(stored.accessTokenSecretVersionPath, null);
  assert.equal((await sdk.getGitHubConnectionSession(dc, sessionKey(s))).data.session, null);
  const connection = (await sdk.getActiveGitHubConnection(dc, installationKey(f))).data.connection;
  assert.equal(connection.id, result.data.connection.id);
  assert.equal(connection.teamId, f.teamId);
  const audit = (
    await graphql(
      `
        query Read($id: String!) {
          gitHubConnection(key: { id: $id }) {
            verifiedByUserId
            verifiedByGitHubUserId
          }
        }
      `,
      { id: connection.id },
    )
  ).gitHubConnection;
  assert.equal(audit.verifiedByUserId, f.userId);
  assert.equal(audit.verifiedByGitHubUserId, s.githubUserId);
  await assert.rejects(sdk.confirmGitHubConnection(dc, confirmation(f, s, "101")));
});

test("fresh confirmation refreshes the same team's metadata and preserves the connection ID", async (t) => {
  const f = await fixture(t);
  const first = await sdk.confirmGitHubConnection(dc, confirmation(f, await session(f)));
  const next = await sdk.confirmGitHubConnection(dc, {
    ...confirmation(f, await session(f)),
    accountLogin: "renamed-org",
    accountId: "201",
  });
  assert.equal(next.data.connection.id, first.data.connection.id);
  const connection = (await sdk.getActiveGitHubConnection(dc, installationKey(f))).data.connection;
  assert.equal(connection.accountLogin, "renamed-org");
  assert.equal(connection.accountId, "201");
});

test("simultaneous same-team confirmations preserve one connection ID", async (t) => {
  const f = await fixture(t);
  const a = await session(f);
  const b = await session(f);
  const [first, second] = await Promise.all([
    sdk.confirmGitHubConnection(dc, confirmation(f, a)),
    sdk.confirmGitHubConnection(dc, confirmation(f, b)),
  ]);
  assert.equal(first.data.connection.id, second.data.connection.id);
  assert.ok((await storedSession(a)).consumedAt);
  assert.ok((await storedSession(b)).consumedAt);
});

test("another team cannot take a connection and its session remains usable after failure", async (t) => {
  const f = await fixture(t);
  await sdk.confirmGitHubConnection(dc, confirmation(f, await session(f)));
  const other = { ...f, teamId: f.otherTeamId, userId: f.otherUserId };
  const s = await session(other);
  await assert.rejects(sdk.confirmGitHubConnection(dc, confirmation(other, s)));
  assert.equal((await storedSession(s)).consumedAt, null);
  assert.equal(
    (await storedSession(s)).accessTokenSecretVersionPath,
    s.accessTokenSecretVersionPath,
  );
  assert.equal(
    (await sdk.getActiveGitHubConnection(dc, installationKey(f))).data.connection.teamId,
    f.teamId,
  );
});

test("simultaneous first claims by different teams have exactly one winner", async (t) => {
  const f = await fixture(t);
  const other = { ...f, teamId: f.otherTeamId, userId: f.otherUserId };
  const a = await session(f);
  const b = await session(other);
  const results = await Promise.allSettled([
    sdk.confirmGitHubConnection(dc, confirmation(f, a)),
    sdk.confirmGitHubConnection(dc, confirmation(other, b)),
  ]);
  assert.equal(results.filter((r) => r.status === "fulfilled").length, 1);
  const loser = results[0].status === "rejected" ? a : b;
  const winner = results[0].status === "fulfilled" ? f : other;
  assert.equal((await storedSession(loser)).consumedAt, null);
  assert.equal(
    (await sdk.getActiveGitHubConnection(dc, installationKey(f))).data.connection.teamId,
    winner.teamId,
  );
});

test("simultaneous confirmations cannot reuse a session for multiple installations", async (t) => {
  const f = await fixture(t);
  const s = await session(f);
  const results = await Promise.allSettled([
    sdk.confirmGitHubConnection(dc, confirmation(f, s, "100")),
    sdk.confirmGitHubConnection(dc, confirmation(f, s, "101")),
  ]);
  assert.equal(results.filter((r) => r.status === "fulfilled").length, 1);
  assert.equal(
    (await sdk.getGitHubConnections(dc, { teamId: f.teamId }, asUser(f.userId))).data.connections
      .length,
    1,
  );
});

test("invalid verified metadata rolls back confirmation without consuming the session", async (t) => {
  const f = await fixture(t);
  const s = await session(f);
  const input = confirmation(f, s);
  for (const override of [
    { githubAppId: "0" },
    { installationId: "-1" },
    { accountId: "0" },
    { accountType: "Bot" },
    { accountLogin: "  " },
    { githubApiBaseUrl: "https://user:pass@github.example" },
    { githubApiBaseUrl: "https://github.example/api/v3?token=value" },
    { githubApiBaseUrl: "https://api.github.com/" },
  ]) {
    await assert.rejects(sdk.confirmGitHubConnection(dc, { ...input, ...override }));
  }
  assert.equal((await storedSession(s)).consumedAt, null);
  assert.equal((await sdk.getActiveGitHubConnection(dc, installationKey(f))).data.connection, null);
  await sdk.confirmGitHubConnection(dc, {
    ...input,
    githubApiBaseUrl: "https://github.example/api/v3",
  });
});

test("expired sessions and removed members cannot read tokens or confirm connections", async (t) => {
  const f = await fixture(t);
  const expired = await session(f);
  await graphql(
    `
      mutation Expire($id: String!) {
        gitHubConnectionSession_update(key: { id: $id }, data: { expiresAt: 1 })
      }
    `,
    { id: expired.id },
  );
  assert.equal((await sdk.getGitHubConnectionSession(dc, sessionKey(expired))).data.session, null);
  await assert.rejects(sdk.confirmGitHubConnection(dc, confirmation(f, expired)));
  const active = await session(f);
  await graphql(
    `
      mutation Remove($userId: String!) {
        teamMember_deleteMany(where: { userId: { eq: $userId } })
      }
    `,
    { userId: f.userId },
  );
  await assert.rejects(sdk.getGitHubConnectionSession(dc, sessionKey(active)));
  await assert.rejects(sdk.confirmGitHubConnection(dc, confirmation(f, active)));
  assert.equal((await storedSession(active)).consumedAt, null);
});

test("cleanup exposes expired paths only and never deletes active credentials", async (t) => {
  const f = await fixture(t);
  const r = requestInput(f);
  const s = await session(f);
  await sdk.createGitHubConnectionRequest(dc, r);
  assert.equal(
    (await sdk.deleteExpiredGitHubConnectionRequest(dc, { id: r.id })).data
      .gitHubConnectionRequest_deleteMany,
    0,
  );
  assert.equal(
    (await sdk.deleteExpiredGitHubConnectionSession(dc, { id: s.id })).data
      .gitHubConnectionSession_deleteMany,
    0,
  );
  const before = (await sdk.getExpiredGitHubConnectionCredentials(dc)).data;
  assert.ok(!before.requests.some((row) => row.id === r.id));
  assert.ok(!before.sessions.some((row) => row.id === s.id));
  await graphql(
    `
      mutation Expire($requestId: String!, $sessionId: String!) @transaction {
        gitHubConnectionRequest_update(key: { id: $requestId }, data: { expiresAt: 1 })
        gitHubConnectionSession_update(key: { id: $sessionId }, data: { expiresAt: 1 })
      }
    `,
    { requestId: r.id, sessionId: s.id },
  );
  const expired = (await sdk.getExpiredGitHubConnectionCredentials(dc)).data;
  assert.equal(
    expired.requests.find((row) => row.id === r.id).codeVerifierSecretVersionPath,
    r.codeVerifierSecretVersionPath,
  );
  assert.equal(
    expired.sessions.find((row) => row.id === s.id).accessTokenSecretVersionPath,
    s.accessTokenSecretVersionPath,
  );
  assert.equal(
    (await sdk.deleteExpiredGitHubConnectionRequest(dc, { id: r.id })).data
      .gitHubConnectionRequest_deleteMany,
    1,
  );
  assert.equal(
    (await sdk.deleteExpiredGitHubConnectionSession(dc, { id: s.id })).data
      .gitHubConnectionSession_deleteMany,
    1,
  );
  assert.equal(
    (await sdk.deleteExpiredGitHubConnectionRequest(dc, { id: r.id })).data
      .gitHubConnectionRequest_deleteMany,
    0,
  );
  assert.equal(
    (await sdk.deleteExpiredGitHubConnectionSession(dc, { id: s.id })).data
      .gitHubConnectionSession_deleteMany,
    0,
  );
});

test("CommonJS SDK supports the default DataConnect instance", async (t) => {
  const f = await fixture(t);
  const commonjs = createRequire(import.meta.url)("@openci/github-admin");
  assert.deepEqual(
    (await commonjs.getGitHubConnections({ teamId: f.teamId }, asUser(f.userId))).data.connections,
    [],
  );
});
