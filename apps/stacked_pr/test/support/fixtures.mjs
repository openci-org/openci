import { readFileSync } from "node:fs";
import { configFromEnvironment } from "../../lib/config.js";
import { PullRequest } from "../../lib/models.js";

export const secret = "a-long-random-webhook-secret-for-tests";
export const testKey = readFileSync(new URL("../fixtures/test_key.txt", import.meta.url), "utf8");
export function config(overrides = {}) {
  return {
    ...configFromEnvironment(
      {
        GITHUB_URL: "https://git.example.com",
        GITHUB_APP_ID: "7",
        GITHUB_APP_PRIVATE_KEY: testKey,
      },
      overrides.dataDir ?? ".",
    ),
    ...overrides,
  };
}
export const modify = (pr, changes) => new PullRequest({ ...pr, ...changes });
export function chain() {
  return [
    new PullRequest({
      number: 1,
      title: "DB",
      headRef: "db",
      baseRef: "main",
      head: "a".repeat(40),
      base: "0".repeat(40),
    }),
    new PullRequest({
      number: 2,
      title: "API",
      headRef: "api",
      baseRef: "db",
      head: "b".repeat(40),
      base: "a".repeat(40),
      parent: 1,
      boundary: "a".repeat(40),
    }),
    new PullRequest({
      number: 3,
      title: "UI",
      headRef: "ui",
      baseRef: "api",
      head: "c".repeat(40),
      base: "b".repeat(40),
      parent: 2,
      boundary: "b".repeat(40),
    }),
  ];
}
export function raw(pr, repoId = 20) {
  return {
    number: pr.number,
    title: pr.title,
    state: pr.state,
    merged: pr.merged,
    merged_at: pr.mergedAt?.toISOString() ?? (pr.merged ? "2026-11-01T00:00:00Z" : null),
    created_at: pr.createdAt?.toISOString(),
    merge_commit_sha: pr.mergeCommit,
    draft: pr.draft,
    html_url: pr.url,
    head: { ref: pr.headRef, sha: pr.head, repo: { id: pr.sameRepo ? repoId : -1 } },
    base: { ref: pr.baseRef, sha: pr.base, repo: { id: repoId } },
  };
}
export function fakeApi(overrides = {}) {
  return {
    identity: async () => ({ id: 7, slug: "stacked-pr" }),
    list: async () => [],
    request: async () => null,
    timeline: async () => [],
    timelines: async (_installation, _repo, numbers) => new Map(numbers.map((n) => [n, []])),
    installationActive: async () => true,
    canWrite: async () => true,
    ...overrides,
  };
}
