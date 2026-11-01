import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { GitRepository } from "../../lib/git.js";
import { PullRequest } from "../../lib/models.js";
import { modify } from "../../test/support/fixtures.mjs";

const execute = promisify(execFile);
export class GitFixture {
  constructor(root) {
    this.root = root;
    this.author = join(root, "author");
    this.remote = join(root, "remote.git");
  }
  static async create(t) {
    const root = await mkdtemp(join(tmpdir(), "stacked-pr-git-"));
    t.after(() => rm(root, { recursive: true, force: true }));
    const f = new GitFixture(root);
    await mkdir(f.author);
    await f.git(["init", "--bare", "--initial-branch=main", f.remote]);
    await f.git(["init", "--initial-branch=main"]);
    f.main = await f.commit("base.txt", "base\n", "base");
    await f.git(["remote", "add", "origin", f.remote]);
    await f.git(["checkout", "-b", "parent"]);
    f.parent = await f.commit("parent.txt", "parent\n", "parent feature");
    await f.git(["checkout", "-b", "child"]);
    f.child = await f.commit("child.txt", "child\n", "child feature");
    await f.git(["checkout", "-b", "grandchild"]);
    f.grandchild = await f.commit("grandchild.txt", "grandchild\n", "grandchild feature");
    await f.git(["push", "origin", "main", "parent", "child", "grandchild"]);
    f.worker = new GitRepository({
      directory: join(root, "worker.git"),
      remote: f.remote,
      allowLocal: true,
    });
    await f.worker.prepare();
    f.pulls = [
      new PullRequest({
        number: 1,
        title: "Parent",
        head: f.parent,
        headRef: "parent",
        base: f.main,
        baseRef: "main",
      }),
      new PullRequest({
        number: 2,
        title: "Child",
        head: f.child,
        headRef: "child",
        base: f.parent,
        baseRef: "parent",
        parent: 1,
        boundary: f.parent,
      }),
      new PullRequest({
        number: 3,
        title: "Grandchild",
        head: f.grandchild,
        headRef: "grandchild",
        base: f.child,
        baseRef: "child",
        parent: 2,
        boundary: f.child,
      }),
    ];
    return f;
  }
  async git(args) {
    const { stdout } = await execute(
      "git",
      [
        "-c",
        "core.hooksPath=/dev/null",
        "-c",
        "commit.gpgSign=false",
        "-c",
        "user.name=Test",
        "-c",
        "user.email=test@example.com",
        ...args,
      ],
      {
        cwd: this.author,
        env: {
          ...process.env,
          GIT_CONFIG_GLOBAL: "/dev/null",
          GIT_CONFIG_NOSYSTEM: "1",
          GIT_AUTHOR_NAME: "Test",
          GIT_AUTHOR_EMAIL: "test@example.com",
          GIT_COMMITTER_NAME: "Test",
          GIT_COMMITTER_EMAIL: "test@example.com",
        },
      },
    );
    return stdout.trim();
  }
  async commit(file, text, message) {
    await writeFile(join(this.author, file), text);
    await this.git(["add", file]);
    await this.git(["commit", "-m", message]);
    return this.git(["rev-parse", "HEAD"]);
  }
  async squash(deleteParent = false) {
    await this.git(["checkout", "main"]);
    await this.git(["merge", "--squash", "parent"]);
    await this.git(["commit", "-m", "squashed parent"]);
    const sha = await this.git(["rev-parse", "HEAD"]);
    await this.git(["push", "origin", "main", ...(deleteParent ? [":parent"] : [])]);
    this.pulls[0] = modify(this.pulls[0], { state: "closed", merged: true });
    await this.worker.prepare();
    return sha;
  }
  async advanceParent() {
    await this.git(["checkout", "parent"]);
    const sha = await this.commit("new.txt", "advance\n", "advance parent");
    await this.git(["push", "origin", "parent"]);
    this.pulls[0].head = sha;
    await this.worker.prepare();
    return sha;
  }
  async output(args) {
    return (await this.worker.run(args)).output;
  }
}
