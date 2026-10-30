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

async function read(f, name = "TOKEN") {
  return (await sdk.getSecretReference(dc, { teamId: f.teamId, name })).data.secretReference;
}

test("members see only their team's sorted metadata, without paths or values", async (t) => {
  const f = await fixture(t);
  await sdk.createSecretReference(dc, input(f, "Z_TOKEN"));
  await sdk.createSecretReference(dc, input(f, "A_TOKEN"));
  await sdk.createSecretReference(dc, { ...input(f, "OTHER"), teamId: f.otherTeamId });

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

test("all reference operations reject clients, including team members", async (t) => {
  const f = await fixture(t);
  const original = input(f);
  await sdk.createSecretReference(dc, original);
  for (const actor of [
    asUser(f.user),
    asUser(f.user, "anonymous"),
    { impersonate: { unauthenticated: true } },
  ]) {
    await assert.rejects(sdk.getSecretReference(dc, { teamId: f.teamId, name: "TOKEN" }, actor));
    await assert.rejects(sdk.createSecretReference(dc, input(f, "NEW"), actor));
    await assert.rejects(
      sdk.updateSecretReference(
        dc,
        {
          ...input(f, "TOKEN", "2"),
          expectedSecretVersionPath: original.secretVersionPath,
        },
        actor,
      ),
    );
    await assert.rejects(
      sdk.deleteSecretReference(
        dc,
        {
          teamId: f.teamId,
          name: "TOKEN",
          expectedSecretVersionPath: original.secretVersionPath,
        },
        actor,
      ),
    );
  }
  assert.equal((await read(f)).secretVersionPath, original.secretVersionPath);
  assert.equal(await read(f, "NEW"), null);
});

test("creation uses server timestamps and does not overwrite duplicates", async (t) => {
  const f = await fixture(t);
  const before = BigInt(Math.floor(Date.now() / 1000));
  await sdk.createSecretReference(dc, input(f));
  const saved = await read(f);
  assert.ok(BigInt(saved.createdAt) >= before);
  assert.ok(BigInt(saved.updatedAt) <= BigInt(Math.floor(Date.now() / 1000)));
  assert.equal(saved.createdAt, saved.updatedAt);
  await assert.rejects(sdk.createSecretReference(dc, input(f, "TOKEN", "2")));
  assert.deepEqual(await read(f), saved);
});

test("creation rejects missing teams, blank names and non-numeric version paths", async (t) => {
  const f = await fixture(t);
  await assert.rejects(
    sdk.createSecretReference(dc, { ...input(f), teamId: "missing-team" }),
    /Team not found/,
  );
  await assert.rejects(
    sdk.createSecretReference(dc, { ...input(f), name: " \t\n" }),
    /Secret name must not be blank/,
  );
  for (const path of [
    "",
    "plaintext",
    input(f).secretVersionPath + "/extra",
    input(f, "TOKEN", "latest").secretVersionPath,
    input(f, "TOKEN", "0").secretVersionPath,
  ]) {
    await assert.rejects(
      sdk.createSecretReference(dc, { ...input(f), secretVersionPath: path }),
      /numeric Secret Manager version path/,
    );
    assert.equal(await read(f), null);
  }
});

test("regional numeric Secret Manager references are supported", async (t) => {
  const f = await fixture(t);
  const secretVersionPath = `projects/123456/locations/asia-northeast1/secrets/${f.teamId}/versions/2`;
  await sdk.createSecretReference(dc, { ...input(f), secretVersionPath });
  assert.equal((await read(f)).secretVersionPath, secretVersionPath);
});

test("updates preserve creation time and invalid paths roll back", async (t) => {
  const f = await fixture(t);
  const original = input(f);
  await sdk.createSecretReference(dc, original);
  await graphql(
    `
      mutation OldTimestamps($teamId: String!) {
        secretReference_update(
          key: { teamId: $teamId, name: "TOKEN" }
          data: { createdAt: 1, updatedAt: 2 }
        )
      }
    `,
    { teamId: f.teamId },
  );
  const saved = await read(f);
  await assert.rejects(
    sdk.updateSecretReference(dc, {
      ...original,
      expectedSecretVersionPath: original.secretVersionPath,
      secretVersionPath: "plaintext",
    }),
    /numeric Secret Manager version path/,
  );
  assert.deepEqual(await read(f), saved);
  await sdk.updateSecretReference(dc, {
    ...input(f, "TOKEN", "2"),
    expectedSecretVersionPath: original.secretVersionPath,
  });
  const updated = await read(f);
  assert.equal(updated.createdAt, "1");
  assert.ok(BigInt(updated.updatedAt) > 2n);
  assert.equal(updated.secretVersionPath, input(f, "TOKEN", "2").secretVersionPath);
});

test("concurrent updates allow only one writer and stale writes cannot delete it", async (t) => {
  const f = await fixture(t);
  const original = input(f);
  await sdk.createSecretReference(dc, original);
  const updates = [input(f, "TOKEN", "2"), input(f, "TOKEN", "3")];
  const results = await Promise.allSettled(
    updates.map((update) =>
      sdk.updateSecretReference(dc, {
        ...update,
        expectedSecretVersionPath: original.secretVersionPath,
      }),
    ),
  );
  assert.equal(results.filter((result) => result.status === "fulfilled").length, 1);
  const winner = updates[results.findIndex((result) => result.status === "fulfilled")];
  const saved = await read(f);
  assert.equal(saved.secretVersionPath, winner.secretVersionPath);
  await assert.rejects(
    sdk.updateSecretReference(dc, {
      ...input(f, "TOKEN", "4"),
      expectedSecretVersionPath: original.secretVersionPath,
    }),
    /not found or changed/,
  );
  await assert.rejects(
    sdk.deleteSecretReference(dc, {
      teamId: f.teamId,
      name: "TOKEN",
      expectedSecretVersionPath: original.secretVersionPath,
    }),
    /not found or changed/,
  );
  assert.deepEqual(await read(f), saved);
});

test("deletion matches team, name and version and preserves other teams", async (t) => {
  const f = await fixture(t);
  const original = input(f);
  const other = { ...f, teamId: f.otherTeamId };
  await sdk.createSecretReference(dc, original);
  await sdk.createSecretReference(dc, input(other));
  await assert.rejects(
    sdk.deleteSecretReference(dc, {
      teamId: other.teamId,
      name: "TOKEN",
      expectedSecretVersionPath: original.secretVersionPath,
    }),
    /not found or changed/,
  );
  await sdk.deleteSecretReference(dc, {
    teamId: f.teamId,
    name: "TOKEN",
    expectedSecretVersionPath: original.secretVersionPath,
  });
  assert.equal(await read(f), null);
  assert.equal((await read(other)).secretVersionPath, input(other).secretVersionPath);
  await assert.rejects(
    sdk.deleteSecretReference(dc, {
      teamId: f.teamId,
      name: "TOKEN",
      expectedSecretVersionPath: original.secretVersionPath,
    }),
    /not found or changed/,
  );
});

test("the CommonJS package also supports the default DataConnect overload", async (t) => {
  const f = await fixture(t);
  const cjs = createRequire(import.meta.url)("@openci/secrets-admin");
  await cjs.createSecretReference(input(f));
  const result = await cjs.getSecretReference({ teamId: f.teamId, name: "TOKEN" });
  assert.equal(result.data.secretReference.secretVersionPath, input(f).secretVersionPath);
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
  await sdk.createSecretReference(dc, original);
  await sdk.createSecretReference(dc, input(f, "EXISTS"));
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
