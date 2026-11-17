import { generateKeyPairSync } from "node:crypto";
import { setTimeout as delay } from "node:timers/promises";
import { afterEach, beforeEach, expect, test, vi } from "vite-plus/test";
import { ExecutionGitHub } from "../../executor/github.js";
import { PullRequestCheckoutError } from "../../executor/checkout_error.js";
import type { Job } from "../../executor/model.js";

const clock = vi.hoisted(() => ({ now: 0 }));

vi.mock("node:timers/promises", () => ({
  setTimeout: vi.fn(async (ms: number, _value: undefined, options?: { signal?: AbortSignal }) => {
    options?.signal?.throwIfAborted();
    clock.now += ms;
  }),
}));

beforeEach(() => {
  clock.now = Date.now();
  vi.spyOn(Date, "now").mockImplementation(() => clock.now);
  vi.mocked(delay).mockImplementation(async (ms, _value, options) => {
    options?.signal?.throwIfAborted();
    clock.now += Number(ms);
  });
});

afterEach(() => {
  expect(delay).not.toHaveBeenCalled();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
  vi.clearAllMocks();
});

const { privateKey } = generateKeyPairSync("rsa", {
  modulusLength: 2048,
  privateKeyEncoding: { type: "pkcs8", format: "pem" },
  publicKeyEncoding: { type: "spki", format: "pem" },
});
const headSha = "a".repeat(40);
const baseSha = "b".repeat(40);
const mergeSha = "c".repeat(40);

function fixture(apiBaseUrl = "https://api.github.com", baseUrl = "https://github.com") {
  const repository = { id: 101, full_name: "org/app", owner: { id: 10 } };
  const pr = {
    number: 7,
    state: "open",
    merged: false,
    mergeable: true as boolean | null,
    merge_commit_sha: mergeSha as string | null,
    head: { repo: repository, sha: headSha, ref: "feature/context" },
    base: { repo: repository, sha: baseSha, ref: "develop" },
  };
  const pullRequests: (typeof pr)[] = [];
  const commits = new Map([
    [mergeSha, { sha: mergeSha, parents: [{ sha: baseSha }, { sha: headSha }] }],
  ]);
  const baseRef = { ref: "refs/heads/develop", object: { type: "commit", sha: baseSha } };
  const headRef = { ref: "refs/heads/feature/context", object: { type: "commit", sha: headSha } };
  const calls: string[] = [];
  const job: Job = {
    id: "job",
    retryCount: 0,
    status: "QUEUED",
    owner: "org",
    repo: "app",
    installationId: "123",
    githubBaseUrl: baseUrl,
    workflowName: "CI",
    workflowFileName: "ci.dart",
    commitSha: headSha,
    pullRequestNumber: "7",
  };
  vi.stubGlobal(
    "fetch",
    vi.fn(async (url: string | URL | Request, init: RequestInit) => {
      const address = String(url);
      expect(address.startsWith(`${apiBaseUrl}/`)).toBe(true);
      const path = address.slice(apiBaseUrl.length);
      calls.push(path);
      if (path.endsWith("/access_tokens")) {
        const body = JSON.parse(String(init.body));
        expect(body.permissions).toEqual({ pull_requests: "read", contents: "read" });
        return Response.json({
          token: "pr-read-token",
          expires_at: new Date(Date.now() + 3600000).toISOString(),
        });
      }
      if (path === "/repos/org/app") return Response.json(repository);
      if (path === "/repos/org/app/pulls/7") {
        // This field is absent in API version 2026-03-10.
        const data = { ...(pullRequests.shift() ?? pr) };
        if (new Headers(init.headers).get("x-github-api-version") !== "2022-11-28")
          delete (data as Partial<typeof pr>).merge_commit_sha;
        return Response.json(data, { headers: { "x-github-request-id": "ABCD:1234:5678" } });
      }
      if (decodeURIComponent(path) === `/repos/org/app/git/ref/heads/${pr.base.ref}`) {
        return Response.json(baseRef);
      }
      if (decodeURIComponent(path) === `/repos/org/app/git/ref/heads/${pr.head.ref}`) {
        return Response.json(headRef);
      }
      if (path.startsWith("/repos/org/app/git/commits/")) {
        const commit = commits.get(path.split("/").at(-1)!);
        return commit ? Response.json(commit) : Response.json({}, { status: 404 });
      }
      if (path === "/installation/token") {
        expect(init.method).toBe("DELETE");
        expect(init.signal?.aborted).toBe(false);
        return new Response(null, { status: 204 });
      }
      throw new Error(`Unexpected GitHub request ${path}`);
    }),
  );
  const github = new ExecutionGitHub({ appId: "1", privateKey, apiBaseUrl, baseUrl });
  return { github, job, pr, pullRequests, commits, calls, baseRef, headRef };
}

function staleFixture() {
  const f = fixture();
  f.baseRef.object.sha = "d".repeat(40);
  return f;
}

test.each([
  ["https://api.github.com", "https://github.com"],
  ["https://github.example/api/v3", "https://github.example"],
])("%s の最新のマージコミットはそのまま使う", async (apiBaseUrl, baseUrl) => {
  const f = fixture(apiBaseUrl, baseUrl);

  expect(await f.github.resolveCheckout(f.job, "10")).toEqual({
    event: "pull_request",
    number: 7,
    headBranch: "feature/context",
    baseBranch: "develop",
    headSha,
    baseSha,
    checkoutSha: mergeSha,
  });
  expect(f.calls.filter((path) => path.endsWith("/pulls/7"))).toHaveLength(1);
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("PR メタデータの古い base SHA ではなく現在のブランチと照合する", async () => {
  const f = fixture();
  f.pr.base.sha = "d".repeat(40);

  expect(await f.github.resolveCheckout(f.job, "10")).toMatchObject({
    baseSha,
    checkoutSha: mergeSha,
  });
});

test("古いマージ候補なら待機せず再検証してローカルマージへ切り替える", async () => {
  const f = staleFixture();
  const started = clock.now;

  expect(await f.github.resolveCheckout(f.job, "10")).toEqual({
    event: "pull_request",
    number: 7,
    headBranch: "feature/context",
    baseBranch: "develop",
    headSha,
    baseSha: f.baseRef.object.sha,
    checkoutSha: null,
    fallback: {
      attempts: 2,
      elapsedMs: 0,
      requestId: "ABCD:1234:5678",
      headSha,
      baseSha: f.baseRef.object.sha,
      mergeSha,
      mergeBaseSha: baseSha,
    },
  });
  expect(clock.now - started).toBe(0);
  expect(f.calls.filter((path) => path.endsWith("/pulls/7"))).toHaveLength(2);
  expect(f.calls.slice(-2).map(decodeURIComponent)).toEqual([
    "/repos/org/app/git/ref/heads/feature/context",
    "/installation/token",
  ]);
  expect(f.calls.some((path) => path.includes("/compare/"))).toBe(false);
});

test.each([
  { mergeable: null, merge_commit_sha: null },
  { mergeable: null },
  { merge_commit_sha: null },
  { merge_commit_sha: "invalid-sha" },
])("GitHub のマージ結果が未生成でも現在の base/head から開始する %j", async (change) => {
  const f = fixture();
  Object.assign(f.pr, change);

  expect(await f.github.resolveCheckout(f.job, "10")).toMatchObject({
    checkoutSha: null,
    baseSha,
    headSha,
    fallback: { attempts: 2, elapsedMs: 0 },
  });
  expect(f.calls.some((path) => path.includes("/git/commits/"))).toBe(false);
  expect(f.calls.filter((path) => path.endsWith("/pulls/7"))).toHaveLength(2);
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("マージコミットが404でも待機せずローカルマージを選ぶ", async () => {
  const f = fixture();
  f.commits.clear();

  expect(await f.github.resolveCheckout(f.job, "10")).toMatchObject({
    checkoutSha: null,
    baseSha,
    headSha,
    fallback: { attempts: 2, elapsedMs: 0 },
  });
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test.each([
  { parents: [{ sha: baseSha }, { sha: "d".repeat(40) }] },
  { parents: [{ sha: headSha }, { sha: baseSha }] },
  { parents: [{ sha: baseSha }] },
  { parents: [{ sha: "invalid-sha" }, { sha: headSha }] },
  { parents: [{ sha: "e".repeat(40) }, { sha: headSha }] },
])("古い候補の親を流用せず現在の base/head でマージする %j", async ({ parents }) => {
  const f = fixture();
  f.commits.set(mergeSha, { sha: mergeSha, parents });

  expect(await f.github.resolveCheckout(f.job, "10")).toMatchObject({
    checkoutSha: null,
    baseSha,
    headSha,
  });
  expect(f.calls.some((path) => path.includes("/compare/"))).toBe(false);
});

test.each(["stale", "missing", "calculating"])(
  "即時の再検証中に最新の GitHub マージが用意できれば優先する %s",
  async (scenario) => {
    const f = fixture();
    const initial = structuredClone(f.pr);
    if (scenario === "stale") {
      const newerBase = "d".repeat(40);
      const newerMerge = "e".repeat(40);
      f.baseRef.object.sha = newerBase;
      f.pr.merge_commit_sha = newerMerge;
      f.commits.set(newerMerge, {
        sha: newerMerge,
        parents: [{ sha: newerBase }, { sha: headSha }],
      });
    } else if (scenario === "missing") {
      initial.merge_commit_sha = "d".repeat(40);
    } else {
      initial.mergeable = null;
      initial.merge_commit_sha = null;
    }
    f.pullRequests.push(initial);

    expect(await f.github.resolveCheckout(f.job, "10")).toMatchObject({
      checkoutSha: f.pr.merge_commit_sha,
      baseSha: f.baseRef.object.sha,
    });
    expect(f.calls.filter((path) => path.endsWith("/pulls/7"))).toHaveLength(2);
  },
);

test.each([
  [{ mergeable: false }, "conflicts"],
  [{ state: "closed" }, "closed"],
  [{ merged: true }, "closed"],
] as const)("切替前に競合・クローズ・マージ済みを検出したら停止する %j", async (change, reason) => {
  for (const recheck of [false, true]) {
    const f = staleFixture();
    if (recheck) f.pullRequests.push(structuredClone(f.pr));
    Object.assign(f.pr, change);

    await expect(f.github.resolveCheckout(f.job, "10")).rejects.toMatchObject({ reason });
    expect(f.calls.at(-1)).toBe("/installation/token");
  }
});

test.each(["pr", "ref"])("切替前に対象 head が変われば停止する %s", async (source) => {
  const f = staleFixture();
  f.pullRequests.push(structuredClone(f.pr));
  if (source === "pr") f.pr.head.sha = "e".repeat(40);
  else f.headRef.object.sha = "e".repeat(40);

  await expect(f.github.resolveCheckout(f.job, "10")).rejects.toMatchObject({
    reason: "head_changed",
  });
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("再検証で別のリポジトリを返してもローカルマージしない", async () => {
  const f = staleFixture();
  f.pullRequests.push(structuredClone(f.pr));
  f.pr.head.repo = { ...f.pr.head.repo, id: 999 };

  await expect(f.github.resolveCheckout(f.job, "10")).rejects.toThrow(
    "Untrusted pull request source",
  );
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("切替直前に進んだ base を再取得して固定する", async () => {
  const f = staleFixture();
  const fetch = vi.mocked(globalThis.fetch);
  const original = fetch.getMockImplementation()!;
  let reads = 0;
  fetch.mockImplementation(async (url, init) => {
    if (String(url).endsWith("/pulls/7") && ++reads === 2) f.baseRef.object.sha = "e".repeat(40);
    return original(url, init);
  });

  expect(await f.github.resolveCheckout(f.job, "10")).toMatchObject({
    checkoutSha: null,
    baseSha: "e".repeat(40),
  });
});

test("再取得で計算中に戻っても古いマージ情報を捨ててローカルマージを選ぶ", async () => {
  const f = staleFixture();
  f.pullRequests.push(structuredClone(f.pr));
  f.pr.mergeable = null;
  f.pr.merge_commit_sha = null;

  const result = await f.github.resolveCheckout(f.job, "10");
  expect(result).toMatchObject({ checkoutSha: null, baseSha: f.baseRef.object.sha, headSha });
  if (result.checkoutSha !== null) throw new Error("Expected a local merge");
  expect(result.fallback).not.toHaveProperty("mergeSha");
  expect(result.fallback).not.toHaveProperty("mergeBaseSha");
});

test.each([
  { ref: "refs/heads/other", object: { type: "commit", sha: baseSha } },
  { ref: "refs/heads/develop", object: { type: "tag", sha: baseSha } },
  { ref: "refs/heads/develop", object: { type: "commit", sha: "private-invalid-sha" } },
])("不正な base ref を拒否してトークンを失効する %j", async (base) => {
  for (const calculating of [false, true]) {
    const f = fixture();
    if (calculating) f.pr.mergeable = null;
    Object.assign(f.baseRef, base);

    await expect(f.github.resolveCheckout(f.job, "10")).rejects.toThrow(
      "Untrusted pull request base ref",
    );
    expect(f.calls.some((path) => path.includes("/git/commits/"))).toBe(false);
    expect(f.calls.at(-1)).toBe("/installation/token");
  }
});

test.each([
  { ref: "refs/heads/other", object: { type: "commit", sha: headSha } },
  { ref: "refs/heads/feature/context", object: { type: "tag", sha: headSha } },
])("不正な head ref でローカルマージしない %j", async (head) => {
  const f = staleFixture();
  Object.assign(f.headRef, head);

  await expect(f.github.resolveCheckout(f.job, "10")).rejects.toThrow(
    "Untrusted pull request head ref",
  );
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("スラッシュを含む base ブランチ名も検証する", async () => {
  const f = staleFixture();
  f.pr.base.ref = "release/2026-11";
  f.baseRef.ref = "refs/heads/release/2026-11";

  expect(await f.github.resolveCheckout(f.job, "10")).toMatchObject({
    checkoutSha: null,
    baseBranch: "release/2026-11",
  });
});

test.each([
  ["/repos/org/app", 403],
  ["/pulls/7", 404],
  ["/git/ref/heads/develop", 404],
  ["/git/ref/heads/feature/context", 404],
  ["/git/commits/", 401],
  ["/git/commits/", 403],
  ["/git/commits/", 500],
] as const)("ソースを検証できない API エラーを準備遅延と扱わない %s %i", async (path, status) => {
  const f = staleFixture();
  const fetch = vi.mocked(globalThis.fetch);
  const original = fetch.getMockImplementation()!;
  fetch.mockImplementation(async (url, init) => {
    const requestPath = decodeURIComponent(new URL(String(url)).pathname);
    const matches = path === "/repos/org/app" ? requestPath === path : requestPath.includes(path);
    return matches ? Response.json({ message: "private body" }, { status }) : original(url, init);
  });

  await expect(f.github.resolveCheckout(f.job, "10")).rejects.toThrow();
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test.each([
  "/repos/org/app",
  "/pulls/7",
  "/git/ref/heads/develop",
  "/git/commits/",
  "/git/ref/heads/feature/context",
])("検証中のキャンセルで開始せずトークンを失効する %s", async (path) => {
  const f = staleFixture();
  const controller = new AbortController();
  const fetch = vi.mocked(globalThis.fetch);
  const original = fetch.getMockImplementation()!;
  fetch.mockImplementation(async (url, init) => {
    const requestPath = decodeURIComponent(new URL(String(url)).pathname);
    const matches = path === "/repos/org/app" ? requestPath === path : requestPath.includes(path);
    if (matches) {
      controller.abort(new Error("Build cancelled"));
      throw new Error("Private transport failure");
    }
    return original(url, init);
  });

  await expect(f.github.resolveCheckout(f.job, "10", controller.signal)).rejects.toThrow(
    "Build cancelled",
  );
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("API 応答時間を含む30秒の検証期限を過ぎたら追加要求せず停止する", async () => {
  const f = fixture();
  f.pr.mergeable = null;
  const fetch = vi.mocked(globalThis.fetch);
  const original = fetch.getMockImplementation()!;
  fetch.mockImplementation(async (url, init) => {
    if (String(url).endsWith("/pulls/7")) clock.now += 15000;
    return original(url, init);
  });

  await expect(f.github.resolveCheckout(f.job, "10")).rejects.toMatchObject({
    reason: "not_ready",
    diagnostics: { attempts: 2, elapsedMs: 30000 },
  });
  expect(f.calls.filter((path) => path.includes("/git/ref/"))).toHaveLength(1);
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test.each(["/pulls/7", "/git/ref/heads/feature/context"])(
  "検証期限は実行中の API を中断しても独立したトークン失効を行う %s",
  async (path) => {
    const f = staleFixture();
    const timeout = new AbortController();
    const originalTimeout = AbortSignal.timeout.bind(AbortSignal);
    vi.spyOn(AbortSignal, "timeout").mockImplementation((ms) =>
      ms === 30000 ? timeout.signal : originalTimeout(ms),
    );
    const fetch = vi.mocked(globalThis.fetch);
    const original = fetch.getMockImplementation()!;
    fetch.mockImplementation(async (url, init) => {
      if (decodeURIComponent(String(url)).includes(path)) {
        timeout.abort(new DOMException("Verification deadline", "TimeoutError"));
        init?.signal?.throwIfAborted();
      }
      return original(url, init);
    });

    await expect(f.github.resolveCheckout(f.job, "10")).rejects.toBeInstanceOf(
      PullRequestCheckoutError,
    );
    expect(f.calls.at(-1)).toBe("/installation/token");
  },
);

test("検証できた GitHub マージでも期限後の応答は採用しない", async () => {
  const f = fixture();
  const fetch = vi.mocked(globalThis.fetch);
  const original = fetch.getMockImplementation()!;
  fetch.mockImplementation(async (url, init) => {
    if (String(url).includes("/git/commits/")) clock.now += 30000;
    return original(url, init);
  });

  await expect(f.github.resolveCheckout(f.job, "10")).rejects.toBeInstanceOf(
    PullRequestCheckoutError,
  );
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("診断情報に未検証の API 値や応答本文を含めない", async () => {
  const f = fixture();
  f.pr.merge_commit_sha = "private-invalid-sha";
  const fetch = vi.mocked(globalThis.fetch);
  const original = fetch.getMockImplementation()!;
  fetch.mockImplementation(async (url, init) => {
    if (String(url).endsWith("/pulls/7"))
      return Response.json(
        { ...f.pr, message: "private response body" },
        { headers: { "x-github-request-id": "private token=value" } },
      );
    return original(url, init);
  });

  const result = await f.github.resolveCheckout(f.job, "10");
  expect(result).toMatchObject({ checkoutSha: null, fallback: { attempts: 2, elapsedMs: 0 } });
  expect(JSON.stringify(result)).not.toContain("private");
});
