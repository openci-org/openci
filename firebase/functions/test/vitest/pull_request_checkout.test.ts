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
});

afterEach(() => {
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
  return { github, job, pr, pullRequests, commits, calls, baseRef };
}

test.each([
  ["https://api.github.com", "https://github.com"],
  ["https://github.example/api/v3", "https://github.example"],
])("%s の PR から親コミットを検証した merge SHA を取得する", async (apiBaseUrl, baseUrl) => {
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
  expect(f.job.commitSha).toBe(headSha);
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("GitHub がマージ可能性を計算中なら PR API を再取得する", async () => {
  const f = fixture();
  f.pullRequests.push({ ...f.pr, mergeable: null, merge_commit_sha: null });

  expect((await f.github.resolveCheckout(f.job, "10")).checkoutSha).toBe(mergeSha);
  expect(delay).toHaveBeenCalledTimes(1);
  expect(f.calls.filter((path) => path.endsWith("/pulls/7"))).toHaveLength(2);
});

test("2分を超えて準備を待ち、間隔を最大30秒まで広げる", async () => {
  const f = fixture();
  f.pullRequests.push(
    ...Array.from({ length: 8 }, () => ({
      ...f.pr,
      mergeable: null,
      merge_commit_sha: null,
    })),
  );

  expect((await f.github.resolveCheckout(f.job, "10")).checkoutSha).toBe(mergeSha);
  expect(vi.mocked(delay).mock.calls.map(([ms]) => ms)).toEqual([
    1000, 2000, 4000, 8000, 16000, 30000, 30000, 30000,
  ]);
  expect(f.calls.filter((path) => path.endsWith("/pulls/7"))).toHaveLength(9);
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("PR の古い base SHA ではなく実際の base ref と照合する", async () => {
  const f = fixture();
  f.pr.base.sha = "d".repeat(40);

  expect(await f.github.resolveCheckout(f.job, "10")).toMatchObject({
    baseSha,
    checkoutSha: mergeSha,
  });
  expect(f.calls.some((path) => decodeURIComponent(path).endsWith("/git/ref/heads/develop"))).toBe(
    true,
  );
  expect(delay).not.toHaveBeenCalled();
});

test("base が進んだときは古い PR 情報とマージ候補を除外して更新後の SHA を取得する", async () => {
  const f = fixture();
  const newerBaseSha = "d".repeat(40);
  const newerMergeSha = "e".repeat(40);
  f.baseRef.object.sha = newerBaseSha;
  f.pr.merge_commit_sha = newerMergeSha;
  f.pullRequests.push({ ...f.pr, merge_commit_sha: mergeSha });
  f.commits.set(newerMergeSha, {
    sha: newerMergeSha,
    parents: [{ sha: newerBaseSha }, { sha: headSha }],
  });

  expect(await f.github.resolveCheckout(f.job, "10")).toMatchObject({
    baseSha: newerBaseSha,
    checkoutSha: newerMergeSha,
  });
  expect(delay).toHaveBeenCalledTimes(1);
  expect(f.calls.filter((path) => path.includes("/git/ref/"))).toHaveLength(2);
});

test("古い候補が続く場合も再取得し、期限後に診断情報付きで停止する", async () => {
  const f = fixture();
  f.baseRef.object.sha = "d".repeat(40);

  await expect(f.github.resolveCheckout(f.job, "10")).rejects.toMatchObject({
    reason: "stale_merge",
    diagnostics: {
      attempts: 24,
      elapsedMs: 600000,
      requestId: "ABCD:1234:5678",
      headSha,
      baseSha: f.baseRef.object.sha,
      mergeSha,
      mergeBaseSha: baseSha,
    },
  });
  expect(f.calls.filter((path) => path.includes("/git/ref/"))).toHaveLength(24);
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("古い候補の後に計算中へ戻った場合は最新の観測結果を報告する", async () => {
  const f = fixture();
  f.pullRequests.push({ ...f.pr });
  f.baseRef.object.sha = "d".repeat(40);
  f.pr.mergeable = null;
  f.pr.merge_commit_sha = null;

  await expect(f.github.resolveCheckout(f.job, "10")).rejects.toMatchObject({
    reason: "not_ready",
    diagnostics: {
      attempts: 24,
      elapsedMs: 600000,
      requestId: "ABCD:1234:5678",
      headSha,
    },
  });
  expect(f.calls.filter((path) => path.includes("/git/ref/"))).toHaveLength(1);
});

test("古い候補の再取得中に head が変わった場合はそのジョブを停止する", async () => {
  const f = fixture();
  f.pullRequests.push({ ...f.pr, head: { ...f.pr.head } });
  f.baseRef.object.sha = "d".repeat(40);
  f.pr.head.sha = "e".repeat(40);

  await expect(f.github.resolveCheckout(f.job, "10")).rejects.toThrow(
    new PullRequestCheckoutError("head_changed"),
  );
  expect(delay).toHaveBeenCalledTimes(1);
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

  const error = await f.github.resolveCheckout(f.job, "10").catch((error: unknown) => error);
  expect(error).toMatchObject({
    reason: "not_ready",
    diagnostics: { attempts: 24, elapsedMs: 600000, headSha },
  });
  expect(JSON.stringify(error)).not.toContain("private");
});

test("スラッシュを含む base ブランチ名も検証する", async () => {
  const f = fixture();
  f.pr.base.ref = "release/2026-11";
  f.baseRef.ref = "refs/heads/release/2026-11";

  expect((await f.github.resolveCheckout(f.job, "10")).checkoutSha).toBe(mergeSha);
});

test.each([
  { ref: "refs/heads/other", object: { type: "commit", sha: baseSha } },
  { ref: "refs/heads/develop", object: { type: "tag", sha: baseSha } },
  { ref: "refs/heads/develop", object: { type: "commit", sha: "private-invalid-sha" } },
])("不正な base ref を拒否してトークンを失効する %j", async (base) => {
  const f = fixture();
  Object.assign(f.baseRef, base);

  await expect(f.github.resolveCheckout(f.job, "10")).rejects.toThrow(
    "Untrusted pull request base ref",
  );
  expect(f.calls.some((path) => path.includes("/git/commits/"))).toBe(false);
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("base ref の取得失敗時に古い PR SHA へフォールバックしない", async () => {
  const f = fixture();
  const fetch = vi.mocked(globalThis.fetch);
  const original = fetch.getMockImplementation()!;
  fetch.mockImplementation(async (url, init) =>
    String(url).includes("/git/ref/") ? Response.json({}, { status: 404 }) : original(url, init),
  );

  await expect(f.github.resolveCheckout(f.job, "10")).rejects.toThrow(
    new PullRequestCheckoutError("unavailable"),
  );
  expect(f.calls.some((path) => path.includes("/git/commits/"))).toBe(false);
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("base ref の読み取り中にキャンセルしてもトークンを失効する", async () => {
  const f = fixture();
  const controller = new AbortController();
  const fetch = vi.mocked(globalThis.fetch);
  const original = fetch.getMockImplementation()!;
  fetch.mockImplementation(async (url, init) => {
    if (String(url).includes("/git/ref/")) {
      controller.abort(new Error("Build cancelled"));
      throw new Error("Private transport failure");
    }
    return original(url, init);
  });

  await expect(f.github.resolveCheckout(f.job, "10", controller.signal)).rejects.toThrow(
    "Build cancelled",
  );
  expect(f.calls.some((path) => path.includes("/git/commits/"))).toBe(false);
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("生成待ちの間に PR の head が更新されたらジョブを拒否する", async () => {
  const f = fixture();
  f.pullRequests.push({ ...f.pr, mergeable: null, merge_commit_sha: null });
  f.pr.head = { ...f.pr.head, sha: "d".repeat(40) };

  await expect(f.github.resolveCheckout(f.job, "10")).rejects.toThrow(
    "Run CI for the latest pull request commit",
  );
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test.each([{ mergeable: false }, { state: "closed" }, { merged: true }])(
  "競合・クローズ済み・マージ済みの PR を拒否する %j",
  async (change) => {
    const f = fixture();
    Object.assign(f.pr, change);

    await expect(f.github.resolveCheckout(f.job, "10")).rejects.toThrow(
      /Resolve the conflicts|Reopen it/,
    );
    expect(f.calls.some((path) => path.includes("/git/commits/"))).toBe(false);
    expect(f.calls.at(-1)).toBe("/installation/token");
  },
);

test.each([{ mergeable: null }, { merge_commit_sha: null }, { merge_commit_sha: "invalid-sha" }])(
  "merge SHA が準備できなければ10分で打ち切る %j",
  async (change) => {
    const f = fixture();
    Object.assign(f.pr, change);
    const started = clock.now;

    await expect(f.github.resolveCheckout(f.job, "10")).rejects.toThrow(
      "Wait a moment and rerun this job",
    );
    expect(clock.now - started).toBe(600000);
    expect(f.calls.filter((path) => path.endsWith("/pulls/7"))).toHaveLength(24);
    expect(delay).toHaveBeenCalledTimes(24);
    expect(vi.mocked(delay).mock.calls.at(-1)?.[0]).toBe(29000);
    expect(f.calls.at(-1)).toBe("/installation/token");
  },
);

test.each([
  { parents: [{ sha: baseSha }, { sha: "d".repeat(40) }] },
  { parents: [{ sha: headSha }, { sha: baseSha }] },
  { parents: [{ sha: baseSha }] },
])("対象 PR と親が一致しない候補を実行しない %j", async ({ parents }) => {
  const f = fixture();
  f.commits.set(mergeSha, { sha: mergeSha, parents });

  await expect(f.github.resolveCheckout(f.job, "10")).rejects.toThrow(
    "Wait a moment and rerun this job",
  );
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("マージコミットの404は期限まで再確認してトークンを失効する", async () => {
  const f = fixture();
  f.commits.clear();

  await expect(f.github.resolveCheckout(f.job, "10")).rejects.toMatchObject({
    reason: "not_ready",
    diagnostics: { attempts: 24, elapsedMs: 600000 },
  });
  expect(f.calls.filter((path) => path.endsWith("/pulls/7"))).toHaveLength(24);
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("マージコミットが一時的に404でも準備後に親を検証して続行する", async () => {
  const f = fixture();
  const fetch = vi.mocked(globalThis.fetch);
  const original = fetch.getMockImplementation()!;
  let missing = true;
  fetch.mockImplementation(async (url, init) => {
    if (String(url).includes("/git/commits/") && missing) {
      missing = false;
      return Response.json({}, { status: 404 });
    }
    return original(url, init);
  });

  expect((await f.github.resolveCheckout(f.job, "10")).checkoutSha).toBe(mergeSha);
  expect(delay).toHaveBeenCalledTimes(1);
  expect(f.calls.filter((path) => path.endsWith("/pulls/7"))).toHaveLength(2);
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test.each([401, 403, 500])("マージコミットのHTTP %iは準備待ちに隠さない", async (status) => {
  const f = fixture();
  const fetch = vi.mocked(globalThis.fetch);
  const original = fetch.getMockImplementation()!;
  fetch.mockImplementation(async (url, init) =>
    String(url).includes("/git/commits/") ? Response.json({}, { status }) : original(url, init),
  );

  await expect(f.github.resolveCheckout(f.job, "10")).rejects.toThrow(
    new PullRequestCheckoutError("unavailable"),
  );
  expect(delay).not.toHaveBeenCalled();
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("API応答の時間も待機期限に含める", async () => {
  const f = fixture();
  f.pr.mergeable = null;
  const fetch = vi.mocked(globalThis.fetch);
  const original = fetch.getMockImplementation()!;
  fetch.mockImplementation(async (url, init) => {
    if (String(url).endsWith("/pulls/7")) clock.now += 30000;
    return original(url, init);
  });

  await expect(f.github.resolveCheckout(f.job, "10")).rejects.toMatchObject({
    reason: "not_ready",
    diagnostics: { attempts: 12, elapsedMs: 600000 },
  });
  expect(f.calls.filter((path) => path.endsWith("/pulls/7"))).toHaveLength(12);
  expect(delay).toHaveBeenCalledTimes(12);
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("準備待ちの期限は実行中のAPIを中断しトークンを失効する", async () => {
  const f = fixture();
  const timeout = new AbortController();
  const originalTimeout = AbortSignal.timeout.bind(AbortSignal);
  vi.spyOn(AbortSignal, "timeout").mockImplementation((ms) =>
    ms === 600000 ? timeout.signal : originalTimeout(ms),
  );
  const fetch = vi.mocked(globalThis.fetch);
  const original = fetch.getMockImplementation()!;
  fetch.mockImplementation(async (url, init) => {
    if (String(url).endsWith("/pulls/7")) {
      timeout.abort(new DOMException("Readiness deadline", "TimeoutError"));
      init?.signal?.throwIfAborted();
    }
    return original(url, init);
  });

  await expect(f.github.resolveCheckout(f.job, "10")).rejects.toMatchObject({
    reason: "not_ready",
    diagnostics: { attempts: 1 },
  });
  expect(delay).not.toHaveBeenCalled();
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("生成待ちをキャンセルしてもトークンを失効する", async () => {
  const f = fixture();
  f.pr.mergeable = null;
  const controller = new AbortController();
  vi.mocked(delay).mockImplementationOnce(async () => {
    controller.abort(new Error("Build cancelled"));
    throw controller.signal.reason;
  });

  await expect(f.github.resolveCheckout(f.job, "10", controller.signal)).rejects.toThrow(
    "Build cancelled",
  );
  expect(f.calls.filter((path) => path.endsWith("/pulls/7"))).toHaveLength(1);
  expect(f.calls.at(-1)).toBe("/installation/token");
});
