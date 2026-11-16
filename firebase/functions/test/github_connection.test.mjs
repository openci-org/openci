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

test("GHES installation links support github-apps while preserving the configured host", () => {
  const enterprise = {
    ...env,
    GITHUB_API_BASE_URL: "https://github.example/api/v3",
    GITHUB_APP_INSTALLATION_URL: "https://github.example/github-apps/openci/installations/new",
  };
  assert.equal(
    connectionConfig(enterprise).installationUrl,
    enterprise.GITHUB_APP_INSTALLATION_URL,
  );
  for (const url of [
    "https://evil.example/github-apps/openci",
    "https://github.example/settings/apps/openci",
  ]) {
    assert.throws(() => connectionConfig({ ...enterprise, GITHUB_APP_INSTALLATION_URL: url }));
  }
});
const chosen = {
  installationId: 12,
  repositoryId: 120,
  accountId: 34,
  accountType: "Organization",
  accountLogin: "openci",
  repositoryName: "app",
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
    unavailable: new Set(),
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
    async unavailableRepositories(team, user, candidates) {
      await authorize(team, user);
      assert.deepEqual(candidates, f.candidates);
      if (f.lookupFailure) throw new ConnectionError("unavailable", "Storage unavailable");
      if (f.revokeDuringLookup) f.member = false;
      return f.unavailable;
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
    {
      installationId: 12,
      repositoryId: 120,
      accountType: "Organization",
      accountLogin: "openci",
      repositoryName: "app",
    },
  ]);
  await f.service.execute("user", {
    action: "confirm",
    teamId: "team",
    reference,
    installationId: 12,
    repositoryId: 120,
    githubApiBaseUrl: "https://attacker.test",
  });
  assert.equal(f.confirms.length, 1);
  assert.equal(f.secrets.size, 0);
  await assert.rejects(
    f.service.execute("user", {
      action: "confirm",
      teamId: "team",
      reference,
      installationId: 12,
      repositoryId: 120,
    }),
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
    f.service.execute("user", {
      action: "confirm",
      teamId: "team",
      reference,
      installationId: 12,
      repositoryId: 120,
    }),
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

test("candidates exclude repositories owned by another team without consuming the session", async () => {
  const f = fixture();
  const reference = await connect(f);
  const available = {
    ...chosen,
    installationId: 13,
    repositoryId: 130,
    repositoryName: "app",
    accountLogin: "available-org",
  };
  f.candidates = [chosen, available];
  f.unavailable.add(chosen.repositoryId);
  const input = { action: "candidates", teamId: "team", reference };
  assert.deepEqual((await f.service.execute("user", input)).candidates, [
    {
      installationId: 13,
      repositoryId: 130,
      repositoryName: "app",
      accountLogin: "available-org",
      accountType: "Organization",
    },
  ]);
  f.unavailable.add(available.repositoryId);
  const result = await f.service.execute("user", input);
  assert.deepEqual(result.candidates, []);
  assert.equal(result.installationUrl, env.GITHUB_APP_INSTALLATION_URL);
  assert.equal(f.sessions.size, 1);
  assert.equal(f.confirms.length, 0);
});

test("candidate ownership lookup fails closed and rechecks membership after the lookup", async () => {
  for (const mode of ["lookupFailure", "revokeDuringLookup"]) {
    const f = fixture();
    const reference = await connect(f);
    f[mode] = true;
    await assert.rejects(
      f.service.execute("user", { action: "candidates", teamId: "team", reference }),
      { code: mode === "lookupFailure" ? "unavailable" : "permission-denied" },
    );
    assert.equal(f.sessions.size, 1);
    assert.equal(f.confirms.length, 0);
  }
});

test("confirmation uses fresh candidates, refuses conflicts, and does not consume a failed choice", async () => {
  const f = fixture();
  const reference = await connect(f);
  const input = {
    action: "confirm",
    teamId: "team",
    reference,
    installationId: 12,
    repositoryId: 120,
  };
  await f.service.execute("user", { action: "candidates", teamId: "team", reference });
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

test("confirmation rejects forged repository/installation pairs and missing or invalid repository IDs", async () => {
  const f = fixture();
  const reference = await connect(f);
  const input = {
    action: "confirm",
    teamId: "team",
    reference,
    installationId: 12,
    repositoryId: 120,
  };
  for (const repositoryId of [undefined, null, 0, -1, "120", 1.5, Number.MAX_SAFE_INTEGER + 1]) {
    await assert.rejects(f.service.execute("user", { ...input, repositoryId }), {
      code: "invalid-argument",
    });
  }
  for (const override of [{ repositoryId: 999 }, { installationId: 999 }]) {
    await assert.rejects(f.service.execute("user", { ...input, ...override }), {
      code: "permission-denied",
    });
  }
  assert.equal(f.confirms.length, 0);
  assert.equal(f.sessions.size, 1);
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
      repositoryId: 120,
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
function repository(id, accountId, permissions = { push: true }) {
  return {
    id,
    name: "repo-" + id,
    full_name: "account-" + accountId + "/repo-" + id,
    owner: { id: accountId },
    permissions,
  };
}

test("repository candidates require user Write access, the configured App, and an active installation", async () => {
  const calls = [];
  const client = new OctokitConnectionClient(config, async (url, init) => {
    calls.push(String(url));
    assert.equal(init.redirect, "error");
    assert.ok(init.signal instanceof AbortSignal);
    const u = new URL(url);
    if (u.pathname === "/login/oauth/access_token") {
      const body = JSON.parse(init.body);
      assert.equal(body.code_verifier, "verifier");
      assert.equal(body.client_secret, env.GITHUB_APP_CLIENT_SECRET);
      assert.equal(u.origin, "https://github.com");
      return json({ access_token: "private-token", token_type: "bearer" });
    }
    assert.equal(u.origin, "https://api.github.com");
    if (u.pathname === "/user") return json({ id: 56 });
    if (u.pathname === "/user/installations")
      return json({
        total_count: 4,
        installations: [
          installation(1, 42, 34),
          installation(2, 42, 9, "User"),
          installation(3, 1, 34),
          installation(4, 42, 34, "Organization", "2026-01-01"),
        ],
      });
    if (u.pathname === "/user/installations/1/repositories")
      return json({
        total_count: 6,
        repositories: [
          repository(101, 34, { push: true, admin: false }),
          repository(102, 34, { push: true, maintain: true }),
          repository(103, 34, { push: true, admin: true }),
          repository(104, 34, { pull: true, push: false }),
          repository(105, 34, { pull: true, triage: true }),
          repository(106, 34, {}),
        ],
      });
    assert.equal(u.pathname, "/user/installations/2/repositories");
    return json({ total_count: 1, repositories: [repository(201, 9)] });
  });
  assert.equal(await client.exchange("code", "verifier"), "private-token");
  assert.deepEqual(
    (await client.candidates("private-token", "56")).map((x) => x.repositoryId),
    [101, 102, 103, 201],
  );
  assert.ok(!calls.some((url) => url.includes("memberships")));
  await assert.rejects(client.candidates("private-token", "57"), { code: "permission-denied" });
});

test("repository pagination includes later Write repositories and never follows Link hosts", async () => {
  const pages = [];
  const client = new OctokitConnectionClient(config, async (url) => {
    const u = new URL(url);
    assert.equal(u.origin, "https://api.github.com");
    if (u.pathname === "/user") return json({ id: 56 });
    if (u.pathname === "/user/installations")
      return json({ total_count: 1, installations: [installation(1, 42, 34)] });
    assert.equal(u.pathname, "/user/installations/1/repositories");
    pages.push(u.searchParams.get("page"));
    if (pages.length === 1)
      return json(
        {
          total_count: 101,
          repositories: Array.from({ length: 100 }, (_, i) =>
            repository(i + 1, 34, { pull: true }),
          ),
        },
        200,
        { link: '<https://attacker.test/token>; rel="next"' },
      );
    return json({ total_count: 101, repositories: [repository(101, 34)] });
  });
  assert.deepEqual(
    (await client.candidates("token", "56")).map((x) => x.repositoryId),
    [101],
  );
  assert.deepEqual(pages, ["1", "2"]);
});

test("malformed, inconsistent, duplicate, and foreign repository pages fail closed", async () => {
  for (const body of [
    { total_count: 1 },
    { total_count: 2, repositories: [repository(1, 34)] },
    { total_count: 2, repositories: [repository(1, 34), repository(1, 34)] },
    { total_count: 1, repositories: [repository(1, 99)] },
    { total_count: 1, repositories: [{ ...repository(1, 34), full_name: "foreign/repo-1" }] },
    { total_count: 1001, repositories: [] },
  ]) {
    const client = new OctokitConnectionClient(config, async (url) => {
      const path = new URL(url).pathname;
      if (path === "/user") return json({ id: 56 });
      if (path === "/user/installations")
        return json({ total_count: 1, installations: [installation(1, 42, 34)] });
      return json(body);
    });
    await assert.rejects(client.candidates("token", "56"), { code: "unavailable" });
  }
});

test("installation pagination remains bounded to the configured host", async () => {
  const pages = [];
  const client = new OctokitConnectionClient(config, async (url) => {
    const u = new URL(url);
    assert.equal(u.origin, "https://api.github.com");
    if (u.pathname === "/user") return json({ id: 56 });
    if (u.pathname.endsWith("/repositories"))
      return json({ total_count: 1, repositories: [repository(1, 56)] });
    assert.equal(u.pathname, "/user/installations");
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

test("GitHub transient failures, expired tokens, and rate limits never return partial candidates", async () => {
  for (const [status, headers, message] of [
    [401, {}, "private upstream content"],
    [429, {}, "private upstream content"],
    [500, {}, "private upstream content"],
    [403, { "x-ratelimit-remaining": "0" }, "rate limit"],
    [403, { "retry-after": "30" }, "try later"],
    [403, {}, "secondary rate limit"],
  ]) {
    const client = new OctokitConnectionClient(config, async (url) => {
      const path = new URL(url).pathname;
      if (path === "/user") return json({ id: 56 });
      if (path === "/user/installations")
        return json({
          total_count: 2,
          installations: [installation(1, 42, 34), installation(2, 42, 35)],
        });
      if (path === "/user/installations/1/repositories")
        return json({ total_count: 1, repositories: [repository(1, 34)] });
      return json({ message }, status, headers);
    });
    await assert.rejects(
      client.candidates("token", "56"),
      (error) =>
        error.code === (status === 401 ? "failed-precondition" : "unavailable") &&
        !error.message.includes("private upstream"),
    );
  }
});

test("revoked installation access omits only its repositories", async () => {
  for (const status of [403, 404]) {
    const client = new OctokitConnectionClient(config, async (url) => {
      const path = new URL(url).pathname;
      if (path === "/user") return json({ id: 56 });
      if (path === "/user/installations")
        return json({
          total_count: 2,
          installations: [installation(1, 42, 34), installation(2, 42, 35)],
        });
      if (path === "/user/installations/1/repositories") return json({ message: "denied" }, status);
      return json({ total_count: 1, repositories: [repository(2, 35)] });
    });
    assert.deepEqual(
      (await client.candidates("token", "56")).map((x) => x.repositoryId),
      [2],
    );
  }
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

test("enterprise account names are preserved for repository candidates", async () => {
  const client = new OctokitConnectionClient(config, async (url) => {
    const path = new URL(url).pathname;
    if (path === "/user") return json({ id: 56 });
    if (path === "/user/installations")
      return json({
        total_count: 1,
        installations: [
          {
            ...installation(1, 42, 56, "User"),
            account: { id: 56, login: "managed_user", type: "User" },
          },
        ],
      });
    return json({
      total_count: 1,
      repositories: [{ ...repository(1, 56), full_name: "managed_user/repo-1" }],
    });
  });
  assert.equal((await client.candidates("token", "56"))[0].accountLogin, "managed_user");
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
