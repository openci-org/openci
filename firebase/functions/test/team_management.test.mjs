import assert from "node:assert/strict";
import { test } from "node:test";
import { TeamManagement, TeamError } from "../../lib/functions/teams/service.js";
import { teamManagement } from "../../lib/functions/team_functions.js";

const claims = { uid: "actor", sub: "actor", firebase: { sign_in_provider: "password" } };
function fixture() {
  const calls = [];
  const store = {
    async list(auth) {
      assert.equal(auth, claims);
      return [
        {
          id: "team",
          name: "日本語",
          members: [{ userId: "actor" }],
          runNumber: "42",
          createdAt: "1704067200",
          updatedAt: "1704153600",
        },
      ];
    },
    async members(teamId, auth) {
      calls.push(["members", teamId, auth.uid]);
      return ["actor", "member"];
    },
    async add(teamId, auth, uid) {
      assert.equal(auth, claims);
      calls.push(["add", teamId, auth.uid, uid]);
    },
  };
  const auth = {
    async getUserByEmail(email) {
      calls.push(["email", email]);
      return { uid: "member", disabled: false };
    },
    async getUsers(ids) {
      calls.push(["users", ids]);
      return {
        users: ids
          .map(({ uid }) => ({
            uid,
            email: `${uid}@test.example`,
            displayName: uid,
            photoURL: "https://example.test/avatar",
            customClaims: { private: true },
          }))
          .reverse(),
        notFound: [],
      };
    },
  };
  return { calls, store, auth, service: new TeamManagement(store, auth) };
}

test("callable rejects missing and anonymous authentication before accessing the runtime", async () => {
  for (const auth of [
    undefined,
    { uid: "actor", token: { firebase: { sign_in_provider: "anonymous" } } },
  ]) {
    await assert.rejects(teamManagement.run({ data: { action: "list" }, auth }), {
      code: "unauthenticated",
    });
  }
});

test("lists the authenticated user's FSC teams in the shared client format", async () => {
  const f = fixture();
  const result = await f.service.execute(claims, { action: "list", userId: "forged-user" });
  assert.deepEqual(result, {
    success: true,
    teams: [
      {
        id: "team",
        name: "日本語",
        members: ["actor"],
        runNumber: 42,
        createdAt: "2024-01-01T00:00:00.000Z",
        updatedAt: "2024-01-02T00:00:00.000Z",
      },
    ],
  });
  assert.equal(f.calls.length, 0);
});

test("rejects malformed requests without account lookup", async () => {
  const f = fixture();
  for (const input of [
    null,
    [],
    "members",
    {},
    { action: ["members"] },
    { action: "remove" },
    { action: "members", teamId: " " },
  ]) {
    await assert.rejects(f.service.execute(claims, input), { code: "invalid-argument" });
  }
  assert.deepEqual(f.calls, []);
});

test("checks membership before exposing user profiles or looking up an email", async () => {
  const f = fixture();
  f.store.members = async () => {
    throw new TeamError("permission-denied", "Team access denied");
  };
  for (const action of ["members", "add"]) {
    await assert.rejects(
      f.service.execute(claims, { action, teamId: "other", email: "private@example.test" }),
      { code: "permission-denied" },
    );
  }
  assert.deepEqual(f.calls, []);
});

test("batches profiles, preserves membership order, and retains deleted users without exposing Auth internals", async () => {
  const f = fixture();
  const ids = Array.from({ length: 205 }, (_, i) => `user-${i}`);
  f.store.members = async () => ids;
  const getUsers = f.auth.getUsers;
  f.auth.getUsers = async (batch) => {
    const result = await getUsers(batch);
    result.users = result.users.filter((user) => user.uid !== "user-3");
    result.users.push({ uid: "unrelated-user", email: "private@example.test" });
    return result;
  };
  const result = await f.service.execute(claims, { action: "members", teamId: "team" });
  assert.deepEqual(
    f.calls.map((call) => call[1].length),
    [100, 100, 5],
  );
  assert.deepEqual(
    result.members.map((member) => member.uid),
    ids,
  );
  assert.deepEqual(result.members[3], { uid: "user-3" });
  assert.equal(result.members[4].email, "user-4@test.example");
  assert.doesNotMatch(JSON.stringify(result), /customClaims|private|unrelated-user/);
});

test("rechecks membership after Auth lookup and filters removed members", async () => {
  const f = fixture();
  let reads = 0;
  f.store.members = async () => (++reads === 1 ? ["actor", "removed"] : ["actor", "new"]);
  const result = await f.service.execute(claims, { action: "members", teamId: "team" });
  assert.deepEqual(
    result.members.map((member) => member.uid),
    ["actor", "new"],
  );
  assert.deepEqual(result.members[1], { uid: "new" });
  f.store.members = async () => {
    if (++reads > 3) throw new TeamError("permission-denied", "Team access denied");
    return ["actor"];
  };
  await assert.rejects(f.service.execute(claims, { action: "members", teamId: "team" }), {
    code: "permission-denied",
  });
});

test("add resolves a normalized email and supplies only the verified actor and resolved UID", async () => {
  const f = fixture();
  assert.deepEqual(
    await f.service.execute(claims, {
      action: "add",
      teamId: "team",
      email: " Member@Example.Test ",
      actorUid: "forged",
      userId: "victim",
    }),
    { success: true },
  );
  assert.deepEqual(f.calls, [
    ["members", "team", "actor"],
    ["email", "member@example.test"],
    ["add", "team", "actor", "member"],
  ]);
});

test("invalid, unknown and disabled accounts cannot be added; upstream details stay private", async () => {
  const f = fixture();
  for (const email of [undefined, [], "", "hello", "two@@example.test", "a\n@example.test"]) {
    await assert.rejects(f.service.execute(claims, { action: "add", teamId: "team", email }), {
      code: "invalid-argument",
    });
  }
  f.auth.getUserByEmail = async () => {
    throw { code: "auth/user-not-found", private: "secret" };
  };
  await assert.rejects(
    f.service.execute(claims, { action: "add", teamId: "team", email: "missing@example.test" }),
    { code: "not-found" },
  );
  f.auth.getUserByEmail = async () => ({ uid: "member", disabled: true });
  await assert.rejects(
    f.service.execute(claims, { action: "add", teamId: "team", email: "disabled@example.test" }),
    { code: "failed-precondition" },
  );
  f.auth.getUserByEmail = async () => {
    throw new Error("private credentials");
  };
  await assert.rejects(
    f.service.execute(claims, { action: "add", teamId: "team", email: "member@example.test" }),
    { message: "Could not look up team member" },
  );
  assert.ok(f.calls.every(([action]) => action === "members"));
});
