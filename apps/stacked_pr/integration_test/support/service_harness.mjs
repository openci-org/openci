import { mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { GitRepository } from "../../lib/git.js";
import { PullRequest, Repository } from "../../lib/models.js";
import { Service } from "../../lib/service.js";
import { config, modify, raw, fakeApi } from "../../test/support/fixtures.mjs";
import { GitFixture } from "./git_fixture.mjs";
import { MemoryStackLocks } from "../../test/support/memory_locks.mjs";

export const repo = new Repository(20, "org/repo", "main");
export class Harness {
  constructor(f) {
    this.f = f;
    this.records = f.pulls.map((p) => p.copy());
    this.events = new Map();
    this.reports = [];
    this.patches = [];
    this.failPatch = false;
    this.generation = 0;
    this.enqueued = [];
    this.locks = new MemoryStackLocks();
  }
  static async create(t, autoRestack = true) {
    const h = new Harness(await GitFixture.create(t));
    h.api = fakeApi({
      timeline: async (_installation, _repo, number) => h.events.get(number) ?? [],
      timelines: async (_installation, _repo, numbers) =>
        new Map(numbers.map((n) => [n, h.events.get(n) ?? []])),
      list: async (_installation, path) => {
        const url = new URL(path, "https://example.com"),
          closed = url.searchParams.get("state") === "closed";
        const branch = url.searchParams.get("head")?.split(":").at(-1);
        return Promise.all(
          h.records
            .filter((p) => p.isOpen !== closed && (branch === undefined || p.headRef === branch))
            .map((p) => h.raw(p)),
        );
      },
      request: async (_installation, method, path, body) => {
        if (path === repo.apiPath) return repo.toJson();
        const number = Number(path.split("/").at(-1)),
          pr = h.records.find((p) => p.number === number);
        if (method === "PATCH") {
          if (h.failPatch) throw new Error("simulated outage after push");
          h.patches.push(body);
          h.baseChange(number, pr.baseRef, body.base);
          pr.baseRef = body.base;
        }
        return h.raw(pr);
      },
    });
    h.reporter = {
      publish: async (_installation, _repo, pulls, options) =>
        h.reports.push({ ...options, pulls: pulls.map((p) => p.copy()) }),
    };
    await h.restart(autoRestack);
    return h;
  }
  async restart(autoRestack = true) {
    this.f.worker = new GitRepository({
      directory: join(this.f.root, `invocation-${this.generation++}.git`),
      remote: this.f.remote,
      allowLocal: true,
    });
    await mkdir(this.f.worker.directory);
    this.service = new Service({
      config: config({ dataDir: this.f.root, autoRestack }),
      api: this.api,
      reporter: this.reporter,
      locks: this.locks,
      gitFactory: () => this.f.worker,
      enqueue: async (job) => {
        this.enqueued.push(job);
        return true;
      },
    });
  }
  async raw(pr) {
    const heads = await this.f.worker.remoteHeads([pr.headRef, pr.baseRef]);
    return raw(
      modify(pr, {
        head: heads.get(pr.headRef) ?? pr.head,
        base: heads.get(pr.baseRef) ?? pr.base,
      }),
    );
  }
  forced(number, before, after) {
    this.events.set(number, [
      ...(this.events.get(number) ?? []),
      {
        __typename: "HeadRefForcePushedEvent",
        createdAt: "2026-11-01T00:00:00Z",
        beforeCommit: { oid: before },
        afterCommit: { oid: after },
      },
    ]);
  }
  baseChange(number, before, after, automatic = false) {
    this.events.set(number, [
      ...(this.events.get(number) ?? []),
      {
        __typename: automatic ? "AutomaticBaseChangeSucceededEvent" : "BaseRefChangedEvent",
        createdAt: "2026-11-01T00:00:01Z",
        [automatic ? "oldBase" : "previousRefName"]: before,
        [automatic ? "newBase" : "currentRefName"]: after,
      },
    ]);
  }
  async rewriteParent(recordHistory = true) {
    await this.f.git(["checkout", "parent"]);
    await writeFile(join(this.f.author, "parent.txt"), "revised parent\n");
    await this.f.git(["add", "."]);
    await this.f.git(["commit", "--amend", "-m", "revised parent"]);
    const head = await this.f.git(["rev-parse", "HEAD"]);
    await this.f.git(["push", "--force", "origin", "parent"]);
    if (recordHistory) this.forced(1, this.f.parent, head);
    return head;
  }
  async merge(retarget = false, automatic = false) {
    const sha = await this.f.squash(true);
    this.records[0] = modify(this.records[0], { state: "closed", merged: true, mergeCommit: sha });
    if (retarget) {
      this.baseChange(2, "parent", "main", automatic);
      this.records[1].baseRef = "main";
    }
    return sha;
  }
  async addStack(number, prefix) {
    const items = [];
    let ref = "main",
      sha = this.f.main;
    for (const part of ["parent", "child"]) {
      const name = `${prefix}-${part}`;
      await this.f.git(["checkout", "-b", name, sha]);
      const head = await this.f.commit(`${name}.txt`, `${name}\n`, name);
      items.push(
        new PullRequest({
          number: number++,
          title: name,
          head,
          headRef: name,
          base: sha,
          baseRef: ref,
        }),
      );
      sha = head;
      ref = name;
    }
    await this.f.git(["push", "origin", ...items.map((p) => p.headRef)]);
    this.records.push(...items);
    return items;
  }
  heads() {
    return this.f.worker.remoteHeads(["main", "parent", "child", "grandchild"]);
  }
}
