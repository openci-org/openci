import { generateKeyPairSync } from "node:crypto";
import { setTimeout as delay } from "node:timers/promises";
import { afterEach, expect, test, vi } from "vite-plus/test";
import { ExecutionGitHub } from "../../executor/github.js";
import { PullRequestCheckoutError } from "../../executor/checkout_error.js";
import type { Job } from "../../executor/model.js";

vi.mock("node:timers/promises", () => ({
  setTimeout: vi.fn(async (_ms: number, _value: undefined, options?: { signal?: AbortSignal }) => {
    options?.signal?.throwIfAborted();
  }),
}));

afterEach(() => {
  vi.unstubAllGlobals();
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
    head: { repo: repository, sha: headSha },
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
      if (path === "/repos/org/app/pulls/7") return Response.json(pullRequests.shift() ?? pr);
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

  expect(await f.github.resolveCheckoutCommit(f.job, "10")).toBe(mergeSha);
  expect(f.job.commitSha).toBe(headSha);
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("GitHub がマージ可能性を計算中なら PR API を再取得する", async () => {
  const f = fixture();
  f.pullRequests.push({ ...f.pr, mergeable: null, merge_commit_sha: null });

  expect(await f.github.resolveCheckoutCommit(f.job, "10")).toBe(mergeSha);
  expect(delay).toHaveBeenCalledTimes(1);
  expect(f.calls.filter((path) => path.endsWith("/pulls/7"))).toHaveLength(2);
});

test("PR の古い base SHA ではなく実際の base ref と照合する", async () => {
  const f = fixture();
  f.pr.base.sha = "d".repeat(40);

  expect(await f.github.resolveCheckoutCommit(f.job, "10")).toBe(mergeSha);
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

  expect(await f.github.resolveCheckoutCommit(f.job, "10")).toBe(newerMergeSha);
  expect(delay).toHaveBeenCalledTimes(1);
  expect(f.calls.filter((path) => path.includes("/git/ref/"))).toHaveLength(2);
});

test("古い PR base SHA と一致するだけの候補は実行しない", async () => {
  const f = fixture();
  f.baseRef.object.sha = "d".repeat(40);

  await expect(f.github.resolveCheckoutCommit(f.job, "10")).rejects.toThrow(
    "Wait a moment and rerun this job",
  );
  expect(f.calls.filter((path) => path.includes("/git/ref/"))).toHaveLength(5);
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("スラッシュを含む base ブランチ名も検証する", async () => {
  const f = fixture();
  f.pr.base.ref = "release/2026-11";
  f.baseRef.ref = "refs/heads/release/2026-11";

  expect(await f.github.resolveCheckoutCommit(f.job, "10")).toBe(mergeSha);
});

test.each([
  { ref: "refs/heads/other", object: { type: "commit", sha: baseSha } },
  { ref: "refs/heads/develop", object: { type: "tag", sha: baseSha } },
  { ref: "refs/heads/develop", object: { type: "commit", sha: "private-invalid-sha" } },
])("不正な base ref を拒否してトークンを失効する %j", async (base) => {
  const f = fixture();
  Object.assign(f.baseRef, base);

  await expect(f.github.resolveCheckoutCommit(f.job, "10")).rejects.toThrow(
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

  await expect(f.github.resolveCheckoutCommit(f.job, "10")).rejects.toThrow(
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

  await expect(f.github.resolveCheckoutCommit(f.job, "10", controller.signal)).rejects.toThrow(
    "Build cancelled",
  );
  expect(f.calls.some((path) => path.includes("/git/commits/"))).toBe(false);
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("生成待ちの間に PR の head が更新されたらジョブを拒否する", async () => {
  const f = fixture();
  f.pullRequests.push({ ...f.pr, mergeable: null, merge_commit_sha: null });
  f.pr.head = { ...f.pr.head, sha: "d".repeat(40) };

  await expect(f.github.resolveCheckoutCommit(f.job, "10")).rejects.toThrow(
    "Run CI for the latest pull request commit",
  );
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test.each([{ mergeable: false }, { state: "closed" }, { merged: true }])(
  "競合・クローズ済み・マージ済みの PR を拒否する %j",
  async (change) => {
    const f = fixture();
    Object.assign(f.pr, change);

    await expect(f.github.resolveCheckoutCommit(f.job, "10")).rejects.toThrow(
      /Resolve the conflicts|Reopen it/,
    );
    expect(f.calls.some((path) => path.includes("/git/commits/"))).toBe(false);
    expect(f.calls.at(-1)).toBe("/installation/token");
  },
);

test.each([{ mergeable: null }, { merge_commit_sha: null }, { merge_commit_sha: "invalid-sha" }])(
  "merge SHA が準備できなければ 5 回で打ち切る %j",
  async (change) => {
    const f = fixture();
    Object.assign(f.pr, change);

    await expect(f.github.resolveCheckoutCommit(f.job, "10")).rejects.toThrow(
      "Wait a moment and rerun this job",
    );
    expect(f.calls.filter((path) => path.endsWith("/pulls/7"))).toHaveLength(5);
    expect(delay).toHaveBeenCalledTimes(4);
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

  await expect(f.github.resolveCheckoutCommit(f.job, "10")).rejects.toThrow(
    "Wait a moment and rerun this job",
  );
  expect(f.calls.at(-1)).toBe("/installation/token");
});

test("マージコミットの取得に失敗した場合もトークンを失効する", async () => {
  const f = fixture();
  f.commits.clear();

  await expect(f.github.resolveCheckoutCommit(f.job, "10")).rejects.toThrow(
    new PullRequestCheckoutError("unavailable"),
  );
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

  await expect(f.github.resolveCheckoutCommit(f.job, "10", controller.signal)).rejects.toThrow(
    "Build cancelled",
  );
  expect(f.calls.filter((path) => path.endsWith("/pulls/7"))).toHaveLength(1);
  expect(f.calls.at(-1)).toBe("/installation/token");
});
