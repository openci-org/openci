import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { createRequire } from "node:module";
import { after, test } from "node:test";
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getDataConnect } from "firebase-admin/data-connect";
import * as sdk from "@openci/secrets-admin";

// Fixture writes must stay in the local demo project.
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

function asUser(uid, provider = "password") {
  return { impersonate: { authClaims: { sub: uid, firebase: { sign_in_provider: provider } } } };
}

async function fixture(t) {
  const id = randomUUID();
  const f = { teamId: `${id}-team`, otherTeamId: `${id}-other`, user: `${id}-user` };
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
      mutation Seed($teamId: String!, $otherTeamId: String!, $user: String!) @transaction {
        team_insertMany(
          data: [
            { id: $teamId, name: "Test", createdAt: 1, updatedAt: 1 }
            { id: $otherTeamId, name: "Other", createdAt: 1, updatedAt: 1 }
          ]
        )
        teamMember_insert(data: { teamId: $teamId, userId: $user })
      }
    `,
    f,
  );
  return f;
}

function input(f, name = "TOKEN", version = "1") {
  return {
    teamId: f.teamId,
    name,
    secretVersionPath: `projects/demo-openci/secrets/${f.teamId}-${name}/versions/${version}`,
  };
}

async function seedReference(data) {
  await graphql(
    `
      mutation SeedReference($data: SecretReference_Data!) {
        secretReference_insert(data: $data)
      }
    `,
    { data: { ...data, createdAt: "1", updatedAt: "1" } },
  );
}

async function read(f, name = "TOKEN") {
  const context = await sdk.getManagedSecretContext(dc, { teamId: f.teamId, actorUid: f.user });
  return context.data.secrets.find((secret) => secret.name === name) ?? null;
}

test("members see only their team's sorted metadata, without paths or values", async (t) => {
  const f = await fixture(t);
  await seedReference(input(f, "Z_TOKEN"));
  await seedReference(input(f, "A_TOKEN"));
  await seedReference({ ...input(f, "OTHER"), teamId: f.otherTeamId });

  const { data } = await sdk.getSecrets(dc, { teamId: f.teamId }, asUser(f.user));
  assert.deepEqual(Object.keys(data), ["secrets"]);
  assert.deepEqual(
    data.secrets.map((secret) => secret.name),
    ["A_TOKEN", "Z_TOKEN"],
  );
  for (const secret of data.secrets) {
    assert.deepEqual(Object.keys(secret).sort(), ["createdAt", "name", "teamId", "updatedAt"]);
    assert.equal(secret.teamId, f.teamId);
  }
});

test("lists remain complete beyond the default 100 rows", async (t) => {
  const f = await fixture(t);
  const rows = Array.from({ length: 101 }, (_, i) => ({
    ...input(f, `KEY_${String(i).padStart(3, "0")}`),
    createdAt: "1",
    updatedAt: "2",
  }));
  for (let offset = 0; offset < rows.length; offset += 100) {
    await graphql(
      `
        mutation SeedSecrets($rows: [SecretReference_Data!]!) {
          secretReference_insertMany(data: $rows)
        }
      `,
      { rows: rows.slice(offset, offset + 100) },
    );
  }
  const { data } = await sdk.getSecrets(dc, { teamId: f.teamId }, asUser(f.user));
  assert.equal(data.secrets.length, 101);
  assert.equal(data.secrets[100].name, "KEY_100");
});

test("empty teams return an empty list and missing references return null", async (t) => {
  const f = await fixture(t);
  assert.deepEqual(
    (await sdk.getSecrets(dc, { teamId: f.teamId }, asUser(f.user))).data.secrets,
    [],
  );
  assert.equal(await read(f), null);
});

test("unauthenticated, anonymous, nonmember and removed-member reads are denied", async (t) => {
  const f = await fixture(t);
  const variables = { teamId: f.teamId };
  await assert.rejects(sdk.getSecrets(dc, variables, { impersonate: { unauthenticated: true } }));
  await assert.rejects(sdk.getSecrets(dc, variables, asUser(f.user, "anonymous")));
  await assert.rejects(sdk.getSecrets(dc, variables, asUser("outsider")));
  await assert.rejects(sdk.getSecrets(dc, { teamId: f.otherTeamId }, asUser(f.user)));
  await assert.rejects(sdk.getSecrets(dc, { teamId: "missing-team" }, asUser(f.user)));
  await graphql(
    `
      mutation RemoveMember($teamId: String!) {
        teamMember_deleteMany(where: { teamId: { eq: $teamId } })
      }
    `,
    variables,
  );
  await assert.rejects(sdk.getSecrets(dc, variables, asUser(f.user)));
});

test("managed writes enforce membership and compare the previous version atomically", async (t) => {
  const f = await fixture(t);
  const vars = {
    teamId: f.teamId,
    actorUid: f.user,
    name: "TOKEN",
    path: input(f).secretVersionPath,
    expectedPath: null,
  };
  await assert.rejects(sdk.commitManagedSecret(dc, { ...vars, actorUid: "outsider" }));
  await assert.rejects(sdk.commitManagedSecret(dc, vars, asUser(f.user)));
  await sdk.commitManagedSecret(dc, vars);
  const results = await Promise.allSettled(
    ["2", "3"].map((version) =>
      sdk.commitManagedSecret(dc, {
        ...vars,
        expectedPath: vars.path,
        path: input(f, "TOKEN", version).secretVersionPath,
      }),
    ),
  );
  assert.equal(results.filter((result) => result.status === "fulfilled").length, 1);
  assert.notEqual((await read(f)).secretVersionPath, vars.path);
});

test("managed rename rolls back on collision and can atomically replace the value", async (t) => {
  const f = await fixture(t);
  const original = input(f);
  await seedReference(original);
  await seedReference(input(f, "EXISTS"));
  const vars = {
    teamId: f.teamId,
    actorUid: f.user,
    name: "TOKEN",
    newName: "EXISTS",
    expectedPath: original.secretVersionPath,
  };
  await assert.rejects(sdk.renameManagedSecret(dc, vars));
  assert.equal((await read(f)).secretVersionPath, original.secretVersionPath);
  const path = input(f, "TOKEN", "2").secretVersionPath;
  await sdk.renameManagedSecret(dc, { ...vars, newName: "RENAMED", path });
  assert.equal(await read(f), null);
  assert.equal((await read(f, "RENAMED")).secretVersionPath, path);
  await assert.rejects(
    sdk.deleteManagedSecret(dc, {
      teamId: f.teamId,
      actorUid: "outsider",
      name: "RENAMED",
      expectedPath: path,
    }),
    /Team access denied/,
  );
  await sdk.deleteManagedSecret(dc, {
    teamId: f.teamId,
    actorUid: f.user,
    name: "RENAMED",
    expectedPath: path,
  });
  assert.equal(await read(f, "RENAMED"), null);
});

test("all managed secret operations reject Firebase clients, including team members", async (t) => {
  const f = await fixture(t);
  const variables = {
    teamId: f.teamId,
    actorUid: f.user,
    name: "TOKEN",
    path: input(f).secretVersionPath,
  };
  const cases = [
    [sdk.getManagedSecretContext, { teamId: f.teamId, actorUid: f.user }],
    [sdk.commitManagedSecret, { ...variables, expectedPath: null }],
    [sdk.renameManagedSecret, { ...variables, newName: "NEXT", expectedPath: variables.path }],
    [
      sdk.deleteManagedSecret,
      { teamId: f.teamId, actorUid: f.user, name: "TOKEN", expectedPath: variables.path },
    ],
    [sdk.queueSecretVersionCleanup, { path: variables.path }],
    [sdk.getDueSecretVersions, undefined],
    [sdk.getSecretVersionReferences, { path: variables.path }],
    [sdk.completeSecretVersionCleanup, { path: variables.path }],
  ];
  for (const actor of [
    asUser(f.user),
    asUser(f.user, "anonymous"),
    { impersonate: { unauthenticated: true } },
  ]) {
    for (const [operation, input] of cases)
      await assert.rejects(
        input === undefined ? operation(dc, actor) : operation(dc, input, actor),
        /permission|auth|access/i,
      );
  }
  assert.equal(await read(f), null);
});

test("managed create and replacement use server timestamps and preserve creation time", async (t) => {
  const f = await fixture(t);
  const before = BigInt(Math.floor(Date.now() / 1000));
  const variables = {
    teamId: f.teamId,
    actorUid: f.user,
    name: "TOKEN",
    path: input(f).secretVersionPath,
    expectedPath: null,
  };
  await sdk.commitManagedSecret(dc, variables);
  const saved = await read(f);
  assert.ok(BigInt(saved.createdAt) >= before);
  assert.ok(BigInt(saved.updatedAt) <= BigInt(Math.floor(Date.now() / 1000)));
  assert.equal(saved.createdAt, saved.updatedAt);
  await assert.rejects(
    sdk.commitManagedSecret(dc, { ...variables, path: input(f, "TOKEN", "2").secretVersionPath }),
  );
  assert.deepEqual(await read(f), saved);
  await sdk.commitManagedSecret(dc, {
    ...variables,
    expectedPath: variables.path,
    path: input(f, "TOKEN", "2").secretVersionPath,
  });
  const updated = await read(f);
  assert.equal(updated.createdAt, saved.createdAt);
  assert.equal(updated.secretVersionPath, input(f, "TOKEN", "2").secretVersionPath);
});

test("CommonJS managed operations support the default DataConnect overload", async (t) => {
  const f = await fixture(t);
  const cjs = createRequire(import.meta.url)("@openci/secrets-admin");
  await cjs.commitManagedSecret({
    teamId: f.teamId,
    actorUid: f.user,
    name: "TOKEN",
    path: input(f).secretVersionPath,
    expectedPath: null,
  });
  const result = await cjs.getManagedSecretContext({ teamId: f.teamId, actorUid: f.user });
  assert.equal(result.data.secrets[0].secretVersionPath, input(f).secretVersionPath);
});
