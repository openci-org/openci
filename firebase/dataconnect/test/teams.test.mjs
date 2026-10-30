import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { after, test } from "node:test";
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getDataConnect } from "firebase-admin/data-connect";
import * as sdk from "@openci/teams-admin";
import { TeamManagement } from "../../lib/functions/teams/service.js";
import { ManagedTeamStore } from "../../lib/functions/teams/store.js";

const host = process.env.DATA_CONNECT_EMULATOR_HOST;
assert.match(host ?? "", /^(127\.0\.0\.1|localhost):\d+$/, "Start the SQL Connect emulator first");
const service = `http://${host}/v1/projects/demo-openci/locations/asia-northeast1/services/openci-b1b91-service`;
const app = initializeApp({ projectId: "demo-openci" }, "teams-test");
const dc = getDataConnect(sdk.connectorConfig, app);
after(() => deleteApp(app));
const claims = (uid, provider = "password") => ({
  uid,
  sub: uid,
  firebase: { sign_in_provider: provider },
});
const asUser = (uid, provider) => ({ impersonate: { authClaims: claims(uid, provider) } });

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
  const f = { teamId: `${id}-team`, userId: `${id}-owner`, memberId: `${id}-member` };
  t.after(() =>
    graphql(
      "mutation($id: String!) { team_delete(id: $id) billingAccount_delete(key: {teamId: $id}) }",
      { id: f.teamId },
    ),
  );
  await sdk.createTeam(dc, { id: f.teamId, name: "Team" }, asUser(f.userId));
  return f;
}

test("team list, creation and rename remain scoped to a nonanonymous Firebase user", async (t) => {
  const f = await fixture(t);
  const teams = (await sdk.getMyTeams(dc, asUser(f.userId))).data.teams;
  assert.equal(teams.length, 1);
  assert.deepEqual(
    teams[0].members.map((member) => member.userId),
    [f.userId],
  );
  assert.equal((await sdk.getMyTeams(dc, asUser("outsider"))).data.teams.length, 0);
  assert.equal(
    (await sdk.getTeamMembers(dc, { teamId: f.teamId }, asUser("outsider"))).data.team,
    null,
  );
  await assert.rejects(
    sdk.renameTeam(dc, { teamId: f.teamId, name: "stolen" }, asUser("outsider")),
    /Team access denied/,
  );
  await sdk.renameTeam(dc, { teamId: f.teamId, name: "日本語" }, asUser(f.userId));
  assert.equal((await sdk.getMyTeams(dc, asUser(f.userId))).data.teams[0].name, "日本語");
  for (const options of [
    { impersonate: { unauthenticated: true } },
    asUser(f.userId, "anonymous"),
  ]) {
    await assert.rejects(sdk.getMyTeams(dc, options));
    await assert.rejects(
      sdk.createTeam(dc, { id: `${f.teamId}-invalid`, name: "Denied" }, options),
    );
  }
});

test("blank names and reused billing identities cannot create or rename a team", async (t) => {
  const f = await fixture(t);
  await assert.rejects(sdk.renameTeam(dc, { teamId: f.teamId, name: " \n\t" }, asUser(f.userId)));
  await graphql(
    "mutation($id: String!) { team_delete(id: $id) billingAccount_insert(data: {teamId: $id}) }",
    { id: f.teamId },
  );
  await assert.rejects(
    sdk.createTeam(dc, { id: f.teamId, name: "new owner" }, asUser("outsider")),
    /already been used/,
  );
  assert.equal(
    (await sdk.getTeamMembers(dc, { teamId: f.teamId }, asUser("outsider"))).data.team,
    null,
  );
});

test("Functions resolves accounts and writes membership through the generated SDK", async (t) => {
  const f = await fixture(t);
  const store = new ManagedTeamStore(dc);
  const api = new TeamManagement(store, {
    async getUserByEmail(email) {
      assert.equal(email, "member@example.test");
      return { uid: f.memberId, disabled: false };
    },
    async getUsers(ids) {
      return {
        users: ids.map(({ uid }) => ({
          uid,
          email: "member@example.test",
          passwordHash: "private",
        })),
        notFound: [],
      };
    },
  });
  await api.execute(claims(f.userId), {
    action: "add",
    teamId: f.teamId,
    email: " Member@Example.Test ",
    userId: "spoofed",
  });
  const result = await api.execute(claims(f.memberId), { action: "members", teamId: f.teamId });
  assert.equal(result.members.length, 2);
  assert.doesNotMatch(JSON.stringify(result), /passwordHash|private|spoofed/);
  assert.equal((await api.execute(claims(f.memberId), { action: "list" })).teams[0].id, f.teamId);
  await assert.rejects(
    api.execute(claims(f.userId), {
      action: "add",
      teamId: f.teamId,
      email: "member@example.test",
    }),
    { code: "already-exists" },
  );
  await sdk.removeTeamMember(dc, { teamId: f.teamId, userId: f.memberId }, asUser(f.userId));
  await assert.rejects(api.execute(claims(f.memberId), { action: "members", teamId: f.teamId }), {
    code: "permission-denied",
  });
  assert.deepEqual((await api.execute(claims(f.memberId), { action: "list" })).teams, []);
});

test("only the server can add a UID and removal rejects outsiders and self-removal", async (t) => {
  const f = await fixture(t);
  await assert.rejects(
    sdk.addTeamMember(
      dc,
      { teamId: f.teamId, actorUid: f.userId, userId: f.memberId },
      asUser(f.userId),
    ),
  );
  await assert.rejects(
    sdk.removeTeamMember(dc, { teamId: f.teamId, userId: f.userId }, asUser(f.userId)),
    /cannot remove yourself/,
  );
  await assert.rejects(
    sdk.removeTeamMember(dc, { teamId: f.teamId, userId: f.userId }, asUser("outsider")),
    /Team access denied/,
  );
  await assert.rejects(
    sdk.removeTeamMember(dc, { teamId: f.teamId, userId: "missing" }, asUser(f.userId)),
    /Team member not found/,
  );
  assert.deepEqual(await new ManagedTeamStore(dc).members(f.teamId, claims(f.userId)), [f.userId]);
});

test("membership revoked during email lookup cannot authorize an addition", async (t) => {
  const f = await fixture(t);
  await sdk.addTeamMember(dc, { teamId: f.teamId, actorUid: f.userId, userId: f.memberId });
  const api = new TeamManagement(new ManagedTeamStore(dc), {
    async getUserByEmail() {
      await sdk.removeTeamMember(dc, { teamId: f.teamId, userId: f.userId }, asUser(f.memberId));
      return { uid: "new-member", disabled: false };
    },
  });
  await assert.rejects(
    api.execute(claims(f.userId), { action: "add", teamId: f.teamId, email: "new@example.test" }),
    { code: "permission-denied" },
  );
  assert.deepEqual(await new ManagedTeamStore(dc).members(f.teamId, claims(f.memberId)), [
    f.memberId,
  ]);
});

test("concurrent mutual removals leave an authorized member", async (t) => {
  const f = await fixture(t);
  await sdk.addTeamMember(dc, { teamId: f.teamId, actorUid: f.userId, userId: f.memberId });
  const results = await Promise.allSettled([
    sdk.removeTeamMember(dc, { teamId: f.teamId, userId: f.memberId }, asUser(f.userId)),
    sdk.removeTeamMember(dc, { teamId: f.teamId, userId: f.userId }, asUser(f.memberId)),
  ]);
  assert.equal(results.filter((result) => result.status === "fulfilled").length, 1);
  const remaining = await graphql(
    "query($id: String!) { teamMembers(where: {teamId: {eq: $id}}) { userId } }",
    { id: f.teamId },
  );
  assert.equal(remaining.teamMembers.length, 1);
});

test("member queries and Functions profile batches include more than 100 members", async (t) => {
  const f = await fixture(t);
  const members = Array.from(
    { length: 104 },
    (_, i) => `{teamId: ${JSON.stringify(f.teamId)}, userId: "user-${i}"}`,
  );
  await graphql(`mutation { teamMember_insertMany(data: [${members.join(",")}]) }`);
  const batches = [];
  const api = new TeamManagement(new ManagedTeamStore(dc), {
    async getUsers(ids) {
      batches.push(ids.length);
      return { users: [], notFound: ids };
    },
  });
  assert.equal(
    (await api.execute(claims(f.userId), { action: "members", teamId: f.teamId })).members.length,
    105,
  );
  assert.deepEqual(batches, [100, 5]);
});
