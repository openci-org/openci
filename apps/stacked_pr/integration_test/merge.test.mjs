import { test } from "node:test";
import assert from "node:assert/strict";
import { join } from "node:path";
import { randomUUID } from "node:crypto";
import { GitRepository } from "../lib/git.js";
import { Reporter } from "../lib/report.js";
import { Service } from "../lib/service.js";
import { config, modify } from "../test/support/fixtures.mjs";
import { MemoryMergeStops } from "../test/support/merge_stops.mjs";
import { Harness, repo } from "./support/service_harness.mjs";

test(
  "the leaf Check lands three separate squash merges on main across fresh workers and CI waits",
  { timeout: 60_000 },
  async (t) => {
    const h = await Harness.create(t),
      f = h.f;
    await f.git(["checkout", "-b", "sibling", f.parent]);
    const siblingHead = await f.commit("sibling.txt", "sibling\n", "sibling change");
    await f.git(["push", "origin", "sibling"]);
    h.records.push(modify(h.records[1], { number: 4, headRef: "sibling", head: siblingHead }));
    const comments = new Map(),
      checks = [],
      jobs = [],
      seen = new Set(),
      merges = [];
    let id = 0,
      approved = false;
    const user = { login: "stacked-pr[bot]", type: "Bot" },
      app = { id: 7 };
    const list = h.api.list,
      request = h.api.request;
    h.api.list = async (i, path, ...rest) => {
      if (path.includes("/issues/")) return comments.get(Number(path.split("/").at(-2))) ?? [];
      if (path.includes("/check-runs")) return checks.filter((c) => path.includes(c.head_sha));
      return list(i, path, ...rest);
    };
    h.api.request = async (i, method, path, body) => {
      if (path === repo.apiPath) return { ...repo.toJson(), allow_squash_merge: true };
      if (path === "/graphql") {
        const pr = h.records.find((p) => p.number === body.variables.number),
          live = await h.raw(pr);
        return {
          data: {
            repository: {
              pullRequest: {
                state: "OPEN",
                isDraft: false,
                headRefOid: live.head.sha,
                baseRefName: pr.baseRef,
                mergeStateStatus: "CLEAN",
                mergeable: "MERGEABLE",
                reviewDecision: pr.number === 2 && !approved ? "REVIEW_REQUIRED" : "APPROVED",
                commits: {
                  nodes: [
                    { commit: { oid: live.head.sha, statusCheckRollup: { state: "SUCCESS" } } },
                  ],
                },
              },
            },
          },
        };
      }
      if (path.endsWith("/comments") && method === "POST") {
        const n = Number(path.split("/").at(-2)),
          c = { id: ++id, user, performed_via_github_app: app, ...body };
        comments.set(n, [...(comments.get(n) ?? []), c]);
        return c;
      }
      if (path.includes("/issues/comments/"))
        return Object.assign(
          [...comments.values()].flat().find((c) => c.id === Number(path.split("/").at(-1))),
          body,
        );
      if (path.endsWith("/check-runs") && method === "POST") {
        const c = { id: ++id, app, ...body };
        checks.push(c);
        return c;
      }
      if (path.includes("/check-runs/"))
        return Object.assign(
          checks.find((c) => c.id === Number(path.split("/").at(-1))),
          body,
        );
      if (method === "PUT") {
        const n = Number(path.split("/").at(-2)),
          pr = h.records.find((p) => p.number === n),
          live = await h.raw(pr);
        assert.equal(pr.isOpen, true);
        assert.equal(pr.baseRef, "main");
        assert.equal(body.sha, live.head.sha);
        assert.equal(body.merge_method, "squash");
        assert.ok(n !== 2 || approved);
        assert.ok(h.locks.held.size > 0);
        await f.git(["fetch", "origin"]);
        await f.git(["checkout", "main"]);
        await f.git(["reset", "--hard", "origin/main"]);
        await f.git(["merge", "--squash", `origin/${pr.headRef}`]);
        await f.git(["commit", "-m", `Land #${n}`]);
        const main = await f.git(["rev-parse", "HEAD"]);
        await f.git(["push", "origin", "main", `:${pr.headRef}`]);
        Object.assign(pr, {
          head: body.sha,
          state: "closed",
          merged: true,
          mergeCommit: main,
          mergedAt: new Date("2026-11-01T00:00:00Z"),
        });
        for (const child of h.records.filter((p) => p.isOpen && p.baseRef === pr.headRef)) {
          h.baseChange(child.number, pr.headRef, "main", true);
          child.baseRef = "main";
        }
        merges.push(n);
        return { merged: true };
      }
      return request(i, method, path, body);
    };
    const stops = new MemoryMergeStops();
    const worker = () =>
      new Service({
        config: config({ dataDir: f.root }),
        api: h.api,
        reporter: new Reporter(h.api),
        locks: h.locks,
        mergeStops: stops,
        enqueue: async (job) => {
          if (seen.has(job.id)) return false;
          seen.add(job.id);
          jobs.push(structuredClone(job));
          return true;
        },
        gitFactory: () => {
          const git = new GitRepository({
            directory: join(f.root, `merge-${randomUUID()}.git`),
            remote: f.remote,
            allowLocal: true,
          });
          const push = git.push.bind(git);
          git.push = async (changes) => {
            await push(changes);
            for (const change of changes.filter((c) => c.changesHead))
              h.events.set(change.number, [
                ...(h.events.get(change.number) ?? []),
                {
                  __typename: "HeadRefForcePushedEvent",
                  actor: { __typename: "Bot", login: "stacked-pr" },
                  beforeCommit: { oid: change.oldHead },
                  afterCommit: { oid: change.newHead },
                },
              ]);
          };
          return git;
        },
      });
    await worker().handle({
      id: "button-delivery",
      event: "check_run",
      payload: {
        action: "requested_action",
        installation: { id: 10 },
        repository: repo.toJson(),
        sender: { type: "User", login: "maintainer" },
        check_run: { app, external_id: "stacked-pr:20:3", head_sha: f.grandchild },
        requested_action: { identifier: "merge-stack" },
      },
    });
    for (let n = 0; jobs.length && n < 18; n++) {
      await worker().handle(jobs.shift());
      if (!approved && comments.get(3)?.some((c) => c.body.includes("承認・CI"))) {
        assert.deepEqual(merges, [1]);
        assert.ok(
          checks.some(
            (c) =>
              c.external_id === "stacked-pr:20:3" &&
              c.actions.some((a) => a.identifier === "cancel-merge"),
          ),
        );
        approved = true;
      }
    }
    assert.equal(jobs.length, 0);
    assert.equal(approved, true);
    assert.deepEqual(merges, [1, 2, 3]);
    assert.equal(
      await f.git(["--git-dir", f.remote, "log", "--reverse", "--format=%s", `${f.main}..main`]),
      "Land #1\nLand #2\nLand #3",
    );
    assert.equal(
      await f.git(["--git-dir", f.remote, "ls-tree", "-r", "--name-only", "main"]),
      "base.txt\nchild.txt\ngrandchild.txt\nparent.txt",
    );
    assert.equal(h.records[3].isOpen, true);
    assert.ok(comments.get(3).some((c) => c.body.includes(":complete")));
    assert.equal(h.locks.held.size, 0);
  },
);
