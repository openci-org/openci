import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { test } from "node:test";
import { connectionConfig } from "../../lib/functions/github_connection/config.js";
import {
  ConnectionError,
  OctokitConnectionClient,
} from "../../lib/functions/github_connection/github.js";
import { GitHubConnections, hash } from "../../lib/functions/github_connection/service.js";
import { GitHubCredentialVault } from "../../lib/functions/github_connection/vault.js";
import { githubConnection } from "../../lib/functions/github_connection_functions.js";

const env = {
  GITHUB_APP_ID: "42",
  GITHUB_APP_CLIENT_ID: "client-id",
  GITHUB_APP_CLIENT_SECRET: "private-client-secret",
  GITHUB_OAUTH_REDIRECT_URI: "https://functions.test/githubConnectionCallback",
  GITHUB_CONNECTION_RETURN_URL: "https://dashboard.test/github/connection",
  GITHUB_APP_INSTALLATION_URL: "https://github.com/apps/openci/installations/new",
};
const config = connectionConfig(env);
const chosen = {
  installationId: 12,
  accountId: 34,
  accountType: "Organization",
  accountLogin: "openci",
};

function fixture() {
  const f = {
    member: true,
    requests: new Map(),
    sessions: new Map(),
    secrets: new Map(),
    deleted: [],
    reports: [],
    calls: [],
    confirms: [],
    candidates: [chosen],
    expire: false,
  };
  const authorize = async (team, user) => {
    if (!f.member || team !== "team" || user !== "user")
      throw new ConnectionError("permission-denied", "Team access denied");
  };
  const store = {
    authorize,
    async createRequest(input) {
      await authorize(input.teamId, input.userId);
      f.requests.set(input.stateHash, input);
    },
    async consumeRequest(key) {
      const request = f.requests.get(key);
      if (!request || f.expire)
        throw new ConnectionError("failed-precondition", "Invalid or expired GitHub request");
      f.requests.delete(key);
      return request;
    },
    async createSession(input) {
      await authorize(input.teamId, input.userId);
      f.sessions.set(input.referenceHash, { ...input, expiresAt: String(Date.now() / 1000 + 600) });
    },
    async session(team, user, key) {
      await authorize(team, user);
      return f.expire ? null : f.sessions.get(key);
    },
    async confirm(team, user, key, installation) {
      await authorize(team, user);
      if (f.conflict) throw new ConnectionError("permission-denied", "Already connected");
      if (!f.sessions.delete(key))
        throw new ConnectionError("failed-precondition", "Session consumed");
      f.confirms.push({ team, user, installation });
    },
    async expired() {
      return { requests: [...f.requests.values()], sessions: [...f.sessions.values()] };
    },
    async deleteExpired(kind, id) {
      f.deleted.push([kind, id]);
    },
  };
  let sequence = 0;
  const vault = {
    async create(value) {
      const path = `private-path-${++sequence}`;
      f.secrets.set(path, value);
      return path;
    },
    async read(path) {
      f.calls.push("read");
      return f.secrets.get(path);
    },
    async destroy(path) {
      if (f.cleanupFailure) throw Error("private-value");
      f.secrets.delete(path);
    },
  };
  const github = {
    async exchange(code, verifier) {
      f.calls.push([code, verifier]);
      return "private-token";
    },
    async user() {
      return 56;
    },
    async candidates(token, user) {
      assert.equal(token, "private-token");
      assert.equal(user, "56");
      f.calls.push("verify");
      if (f.revokeDuringVerification) f.member = false;
      return f.candidates;
    },
  };
  f.service = new GitHubConnections(config, store, vault, github, (reason) =>
    f.reports.push(reason),
  );
  f.store = store;
  return f;
}
async function connect(f) {
  const start = await f.service.execute("user", { action: "start", teamId: "team" });
  const state = new URL(start.authorizationUrl).searchParams.get("state");
  const result = await f.service.callback(new URLSearchParams({ state, code: "oauth-code" }));
  return new URLSearchParams(new URL(result).hash.slice(1)).get("reference");
}

test("OAuth uses one-time PKCE, hashes and credential references; responses contain no tokens", async () => {
  const f = fixture();
  const start = await f.service.execute("user", { action: "start", teamId: "team" });
  const url = new URL(start.authorizationUrl);
  const state = url.searchParams.get("state");
  assert.match(state, /^[\w-]{43}$/);
  const request = f.requests.get(hash(state));
  const verifier = f.secrets.get(request.codeVerifierSecretVersionPath);
  assert.equal(
    url.searchParams.get("code_challenge"),
    createHash("sha256").update(verifier).digest("base64url"),
  );
  assert.equal(url.searchParams.get("code_challenge_method"), "S256");
  assert.equal(url.searchParams.get("redirect_uri"), env.GITHUB_OAUTH_REDIRECT_URI);
  assert.ok(!JSON.stringify(request).includes(verifier));
  const result = await f.service.callback(new URLSearchParams({ state, code: "oauth-code" }));
  const reference = new URLSearchParams(new URL(result).hash.slice(1)).get("reference");
  assert.equal(new URL(result).search, "");
  assert.equal(f.secrets.has(request.codeVerifierSecretVersionPath), false);
  const session = await f.service.execute("user", { action: "session", teamId: "team", reference });
  assert.equal(session.session.githubUserId, 56);
  assert.doesNotMatch(JSON.stringify(session), /private-token|SecretVersionPath|referenceHash/);
  const candidates = await f.service.execute("user", {
    action: "candidates",
    teamId: "team",
    reference,
  });
  assert.deepEqual(candidates.candidates, [
    { installationId: 12, accountType: "Organization", accountLogin: "openci" },
  ]);
  await f.service.execute("user", {
    action: "confirm",
    teamId: "team",
    reference,
    installationId: 12,
    githubApiBaseUrl: "https://attacker.test",
  });
  assert.equal(f.confirms.length, 1);
  assert.equal(f.secrets.size, 0);
  await assert.rejects(
    f.service.execute("user", { action: "confirm", teamId: "team", reference, installationId: 12 }),
    /Restart/,
  );
});

test("unauthenticated and anonymous callable requests fail before runtime credentials are loaded", async () => {
  await assert.rejects(githubConnection.run({ data: {} }), { code: "unauthenticated" });
  await assert.rejects(
    githubConnection.run({
      data: {},
      auth: { uid: "anon", token: { firebase: { sign_in_provider: "anonymous" } } },
    }),
    { code: "unauthenticated" },
  );
});

test("invalid actions and input types cannot reach OAuth or confirmation", async () => {
  const f = fixture();
  for (const action of [["start"], ["confirm"], {}, null, "delete"]) {
    await assert.rejects(f.service.execute("user", { action, teamId: "team" }), {
      code: "invalid-argument",
    });
  }
  assert.equal(f.secrets.size, 0);
  assert.equal(f.confirms.length, 0);
});

test("authorization precedes credential access and is rechecked after GitHub verification", async () => {
  const f = fixture();
  f.member = false;
  await assert.rejects(
    f.service.execute("user", { action: "start", teamId: "team" }),
    /Team access denied/,
  );
  assert.equal(f.secrets.size, 0);
  f.member = true;
  const reference = await connect(f);
  await assert.rejects(
    f.service.execute("other-user", { action: "session", teamId: "team", reference }),
    /Team access denied/,
  );
  await assert.rejects(
    f.service.execute("user", { action: "session", teamId: "other-team", reference }),
    /Team access denied/,
  );
  f.revokeDuringVerification = true;
  await assert.rejects(
    f.service.execute("user", { action: "confirm", teamId: "team", reference, installationId: 12 }),
    /Team access denied/,
  );
  assert.equal(f.confirms.length, 0);
});

test("callback rejects duplicate parameters, expired state, replay and denial without another exchange", async () => {
  const f = fixture();
  const start = await f.service.execute("user", { action: "start", teamId: "team" });
  const state = new URL(start.authorizationUrl).searchParams.get("state");
  assert.match(
    await f.service.callback(new URLSearchParams(`state=${state}&code=a&code=b`)),
    /error=invalid_callback$/,
  );
  assert.equal(f.requests.size, 1);
  const callbacks = await Promise.all(
    [1, 2].map(() => f.service.callback(new URLSearchParams({ state, error: "access_denied" }))),
  );
  assert.ok(callbacks.some((value) => value.endsWith("error=access_denied")));
  assert.ok(callbacks.some((value) => value.endsWith("error=invalid_state")));
  assert.equal(f.calls.length, 0);
  assert.equal(f.secrets.size, 0);
  f.expire = true;
  const next = await f.service.execute("user", { action: "start", teamId: "team" });
  assert.match(
    await f.service.callback(
      new URLSearchParams({
        state: new URL(next.authorizationUrl).searchParams.get("state"),
        code: "code",
      }),
    ),
    /invalid_state$/,
  );
});

test("confirmation uses fresh candidates, refuses conflicts, and does not consume a failed choice", async () => {
  const f = fixture();
  const reference = await connect(f);
  const input = { action: "confirm", teamId: "team", reference, installationId: 12 };
  f.candidates = [];
  await assert.rejects(f.service.execute("user", input), { code: "permission-denied" });
  f.candidates = [chosen];
  f.conflict = true;
  await assert.rejects(f.service.execute("user", input), { code: "permission-denied" });
  assert.equal(f.sessions.size, 1);
  f.conflict = false;
  const outcomes = await Promise.allSettled([
    f.service.execute("user", input),
    f.service.execute("user", input),
  ]);
  assert.equal(outcomes.filter((o) => o.status === "fulfilled").length, 1);
});

test("cleanup failure cannot undo a confirmed connection or expose upstream error content", async () => {
  const f = fixture();
  const reference = await connect(f);
  f.cleanupFailure = true;
  assert.deepEqual(
    await f.service.execute("user", {
      action: "confirm",
      teamId: "team",
      reference,
      installationId: 12,
    }),
    { success: true },
  );
  assert.deepEqual(f.reports, ["github_credential_cleanup_failed"]);
  const expired = fixture();
  await connect(expired);
  expired.cleanupFailure = true;
  await expired.service.cleanup();
  assert.equal(expired.deleted.length, 0);
  expired.cleanupFailure = false;
  await expired.service.cleanup();
  assert.equal(expired.deleted.length, 1);
});

function json(value, status = 200, headers = {}) {
  return new Response(JSON.stringify(value), {
    status,
    headers: { "content-type": "application/json", ...headers },
  });
}
function installation(id, appId, accountId, type = "Organization", suspended = null) {
  return {
    id,
    app_id: appId,
    account: { id: accountId, login: `account-${accountId}`, type },
    suspended_at: suspended,
  };
}
test("Octokit enforces user/app/owner/admin/suspension and stays on operator-configured hosts", async () => {
  const calls = [];
  const client = new OctokitConnectionClient(config, async (url, init) => {
    calls.push({ url: String(url), init });
    assert.equal(init.redirect, "error");
    assert.ok(init.signal instanceof AbortSignal);
    const path = new URL(url).pathname;
    if (path === "/login/oauth/access_token") {
      const body = JSON.parse(init.body);
      assert.equal(body.code_verifier, "verifier");
      assert.equal(body.client_secret, env.GITHUB_APP_CLIENT_SECRET);
      assert.equal(new URL(url).origin, "https://github.com");
      return json({ access_token: "private-token", token_type: "bearer" });
    }
    assert.equal(new URL(url).origin, "https://api.github.com");
    if (path === "/user") return json({ id: 56 });
    if (path === "/user/installations")
      return json({
        total_count: 6,
        installations: [
          installation(1, 42, 56, "User"),
          installation(2, 42, 9, "User"),
          installation(3, 1, 56, "User"),
          installation(4, 42, 34),
          installation(5, 42, 35),
          installation(6, 42, 36, "Organization", "2026-01-01"),
        ],
      });
    return json({
      state: "active",
      role: path.endsWith("34") ? "admin" : "member",
      user: { id: 56 },
      organization: { id: path.endsWith("34") ? 34 : 35 },
    });
  });
  assert.equal(await client.exchange("code", "verifier"), "private-token");
  assert.deepEqual(
    (await client.candidates("private-token", "56")).map((i) => i.installationId),
    [1, 4],
  );
  await assert.rejects(client.candidates("private-token", "57"), { code: "permission-denied" });
  assert.ok(calls.length > 4);
});

test("GitHub transient/rate-limit errors fail closed; pagination never follows an untrusted URL", async () => {
  for (const status of [401, 429, 500]) {
    const client = new OctokitConnectionClient(config, async () =>
      json({ message: "private upstream content" }, status),
    );
    await assert.rejects(
      client.candidates("token", "56"),
      (error) => !error.message.includes("private upstream"),
    );
  }
  const pages = [];
  const client = new OctokitConnectionClient(config, async (url) => {
    const u = new URL(url);
    assert.equal(u.origin, "https://api.github.com");
    if (u.pathname === "/user") return json({ id: 56 });
    pages.push(u.searchParams.get("page"));
    return pages.length === 1
      ? json(
          {
            total_count: 101,
            installations: Array.from({ length: 100 }, (_, i) =>
              installation(i + 1, 1, 56, "User"),
            ),
          },
          200,
          { link: '<https://attacker.test/token>; rel="next"' },
        )
      : json({ total_count: 101, installations: [installation(101, 42, 56, "User")] });
  });
  assert.equal((await client.candidates("token", "56"))[0].installationId, 101);
  assert.deepEqual(pages, ["1", "2"]);
});

test("operator endpoints support GHES paths and reject credential-bearing or foreign install URLs", () => {
  assert.equal(
    connectionConfig({
      ...env,
      GITHUB_API_BASE_URL: "https://github.test/prefix/api/v3/",
      GITHUB_APP_INSTALLATION_URL: "https://github.test/prefix/apps/ci/installations/new",
    }).baseUrl,
    "https://github.test/prefix",
  );
  for (const value of [
    "https://user:token@github.test/api/v3",
    "https://github.test/api/v3?token=x",
    "http://github.test/api/v3",
  ])
    assert.throws(() => connectionConfig({ ...env, GITHUB_API_BASE_URL: value }));
  assert.throws(() =>
    connectionConfig({ ...env, GITHUB_APP_INSTALLATION_URL: "https://attacker.test/apps/ci" }),
  );
});

test("GHES token and API requests preserve the operator's path prefix", async () => {
  const ghes = connectionConfig({
    ...env,
    GITHUB_API_BASE_URL: "https://github.test/prefix/api/v3",
    GITHUB_APP_INSTALLATION_URL: "https://github.test/prefix/apps/ci/installations/new",
  });
  const urls = [];
  const client = new OctokitConnectionClient(ghes, async (url) => {
    urls.push(String(url));
    return String(url).endsWith("access_token")
      ? json({ access_token: "token", token_type: "bearer" })
      : json({ id: 56 });
  });
  await client.exchange("code", "verifier");
  await client.user("token");
  assert.deepEqual(urls, [
    "https://github.test/prefix/login/oauth/access_token",
    "https://github.test/prefix/api/v3/user",
  ]);
});

test("enterprise account names are preserved and secondary rate limits do not return partial candidates", async () => {
  let limited = false;
  const client = new OctokitConnectionClient(config, async (url) => {
    const path = new URL(url).pathname;
    if (path === "/user") return json({ id: 56 });
    if (path === "/user/installations")
      return json({
        total_count: 2,
        installations: [
          {
            ...installation(1, 42, 56, "User"),
            account: { id: 56, login: "managed_user", type: "User" },
          },
          installation(2, 42, 34),
        ],
      });
    return json(
      {
        message: limited
          ? "You have exceeded a secondary rate limit"
          : "Resource not accessible by integration",
      },
      403,
    );
  });
  assert.equal((await client.candidates("token", "56"))[0].accountLogin, "managed_user");
  limited = true;
  await assert.rejects(client.candidates("token", "56"), { code: "unavailable" });
});

test("OAuth credentials auto-expire and cleanup is restricted to owned resources", async () => {
  let name, createInput, deleted;
  let label = "github-oauth";
  const sdk = {
    async createSecret(input) {
      createInput = input;
      name = `${input.parent}/secrets/${input.secretId}`;
      return [{ name }];
    },
    async addSecretVersion(input) {
      assert.equal(input.payload.data.toString(), "private-token");
      return [{ name: name.replace("demo-project", "123456") + "/versions/1" }];
    },
    async accessSecretVersion() {
      return [{ payload: { data: Buffer.from("private-token") } }];
    },
    async getSecret() {
      return [{ labels: { "openci-purpose": label } }];
    },
    async deleteSecret(input) {
      deleted = input.name;
    },
  };
  const vault = new GitHubCredentialVault("demo-project", sdk);
  const path = await vault.create("private-token");
  assert.equal(createInput.secret.ttl.seconds, 1800);
  assert.equal(await vault.read(path), "private-token");
  await assert.rejects(
    vault.destroy("projects/demo-project/secrets/team-secret/versions/1"),
    /Invalid/,
  );
  label = "other";
  await assert.rejects(vault.destroy(path), /not owned/);
  label = "github-oauth";
  await vault.destroy(path);
  assert.equal(deleted, name);
  sdk.getSecret = async () => {
    throw { code: 5 };
  };
  await vault.destroy(path);
});
