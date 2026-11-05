import { spawn } from "node:child_process";
import { mkdir, mkdtemp, rm } from "node:fs/promises";
import { join } from "node:path";
import type { Environment } from "./config.js";
import type { Deadline } from "./deadline.js";
import { BranchChange, PullRequest, RestackException } from "./models.js";

export class GitException extends Error {
  constructor(
    readonly command: string,
    readonly reason: string,
  ) {
    super(`Git ${command} failed (${reason})`);
  }
}
export function assertSha(sha: string): string {
  if (!/^(?:[a-f0-9]{40}|[a-f0-9]{64})$/.test(sha)) throw new Error("Invalid Git object ID");
  return sha;
}
interface GitOptions {
  directory: string;
  remote: string;
  token?: () => Promise<string>;
  allowLocal?: boolean;
  deadline?: Deadline;
  environment?: Environment;
}
export class GitRepository {
  readonly directory: string;
  readonly remote: string;
  private readonly environment: Environment;
  constructor(private readonly options: GitOptions) {
    if (!options.allowLocal && !options.remote.startsWith("https://"))
      throw new Error("Git remote must use HTTPS");
    this.directory = options.directory;
    this.remote = options.remote;
    this.environment = options.environment ?? process.env;
  }
  async run(
    args: string[],
    options: { cwd?: string; network?: boolean; accepted?: number[] } = {},
  ): Promise<{ code: number; output: string }> {
    const env: Environment = {
      LANG: "C.UTF-8",
      LC_ALL: "C",
      GIT_TERMINAL_PROMPT: "0",
      GIT_CONFIG_NOSYSTEM: "1",
      GIT_CONFIG_GLOBAL: "/dev/null",
      GIT_AUTHOR_NAME: "Stacked PR",
      GIT_AUTHOR_EMAIL: "stacked-pr@localhost",
      GIT_COMMITTER_NAME: "Stacked PR",
      GIT_COMMITTER_EMAIL: "stacked-pr@localhost",
    };
    for (const name of [
      "PATH",
      "TMPDIR",
      "GIT_SSL_CAINFO",
      "HTTPS_PROXY",
      "HTTP_PROXY",
      "NO_PROXY",
      "https_proxy",
      "http_proxy",
      "no_proxy",
    ]) {
      if (this.environment[name] !== undefined) env[name] = this.environment[name];
    }
    this.options.deadline?.limit(120_000);
    if (options.network && this.options.token) {
      const token = await this.options.token();
      if (token)
        Object.assign(env, {
          GIT_CONFIG_COUNT: "1",
          GIT_CONFIG_KEY_0: "http.extraHeader",
          GIT_CONFIG_VALUE_0: `Authorization: Basic ${Buffer.from(`x-access-token:${token}`).toString("base64")}`,
        });
    }
    const timeout = this.options.deadline?.limit(120_000) ?? 120_000;
    return new Promise((resolve, reject) => {
      const child = spawn(
        "git",
        [
          "-c",
          "core.hooksPath=/dev/null",
          "-c",
          "credential.helper=",
          "-c",
          "http.followRedirects=false",
          "-c",
          "protocol.ext.allow=never",
          "-c",
          `protocol.file.allow=${this.options.allowLocal ? "always" : "never"}`,
          "-c",
          "gc.auto=0",
          "-c",
          "maintenance.auto=false",
          "-c",
          "commit.gpgSign=false",
          // Equivalent to --no-update-refs, also supported by the Node 22 runtime's Git 2.34.
          "-c",
          "rebase.updateRefs=false",
          ...args,
        ],
        {
          cwd: options.cwd ?? this.directory,
          env,
          detached: process.platform !== "win32",
          stdio: ["ignore", "pipe", "pipe"],
        },
      );
      const chunks: Buffer[] = [];
      let length = 0;
      let failure: string | undefined;
      const kill = () => {
        try {
          if (child.pid && process.platform !== "win32") process.kill(-child.pid, "SIGKILL");
          else child.kill("SIGKILL");
        } catch {
          /* Already exited. */
        }
      };
      const timer = setTimeout(() => {
        failure = "timeout";
        kill();
      }, timeout);
      child.stdout.on("data", (chunk: Buffer) => {
        length += chunk.length;
        if (length > 8 * 1024 * 1024) {
          failure = "output limit exceeded";
          kill();
        } else chunks.push(chunk);
      });
      // Git errors may contain credentials or repository contents. Never retain them.
      child.stderr.resume();
      child.on("error", () => {
        clearTimeout(timer);
        reject(new GitException(args[0], "execution error"));
      });
      child.on("close", (code) => {
        clearTimeout(timer);
        if (failure || code === null || !(options.accepted ?? [0]).includes(code)) {
          reject(new GitException(args[0], failure ?? String(code)));
        } else resolve({ code, output: Buffer.concat(chunks).toString("utf8").trimEnd() });
      });
    });
  }
  async prepare({
    pulls = [],
    branches,
  }: { pulls?: PullRequest[]; branches?: string[] } = {}): Promise<void> {
    await mkdir(this.directory, { recursive: true });
    await this.run(["init", "--bare", "."]);
    await rm(join(this.directory, "scratch"), { recursive: true, force: true });
    await this.run(["worktree", "prune"]);
    for (const branch of branches ?? [])
      await this.run(["check-ref-format", `refs/heads/${branch}`]);
    const pullRefs = this.options.allowLocal
      ? []
      : pulls.map((pr) => {
          if (!Number.isSafeInteger(pr.number) || pr.number <= 0)
            throw new Error("Invalid PR number");
          return `+refs/pull/${pr.number}/head:refs/pull/${pr.number}/head`;
        });
    await this.run(
      [
        "fetch",
        "--prune",
        "--no-tags",
        this.remote,
        ...(branches === undefined
          ? ["+refs/heads/*:refs/remotes/origin/*"]
          : branches.map((b) => `+refs/heads/${b}:refs/remotes/origin/${b}`)),
        ...pullRefs.slice(0, 50),
      ],
      { network: true },
    );
    for (let start = 50; start < pullRefs.length; start += 50)
      await this.run(["fetch", "--no-tags", this.remote, ...pullRefs.slice(start, start + 50)], {
        network: true,
      });
  }
  async branch(ref: string): Promise<string> {
    await this.run(["check-ref-format", `refs/heads/${ref}`]);
    return assertSha(
      (await this.run(["rev-parse", "--verify", `refs/remotes/origin/${ref}^{commit}`])).output,
    );
  }
  async has(sha: string): Promise<boolean> {
    return (
      (await this.run(["cat-file", "-e", `${assertSha(sha)}^{commit}`], { accepted: [0, 1, 128] }))
        .code === 0
    );
  }
  async ensure(sha: string): Promise<void> {
    if (!(await this.has(sha)))
      await this.run(["fetch", "--no-tags", this.remote, assertSha(sha)], { network: true });
    await this.pin(sha);
  }
  async pin(sha: string): Promise<void> {
    await this.run(["update-ref", `refs/stacked-pr/keep/${assertSha(sha)}`, sha]);
  }
  async ancestor(base: string, head: string): Promise<boolean> {
    return (
      (
        await this.run(["merge-base", "--is-ancestor", assertSha(base), assertSha(head)], {
          accepted: [0, 1],
        })
      ).code === 0
    );
  }
  async mergeBase(left: string, right: string): Promise<string | undefined> {
    const result = await this.run(["merge-base", "--all", assertSha(left), assertSha(right)], {
      accepted: [0, 1],
    });
    const bases = result.output.split("\n").filter(Boolean);
    return bases.length === 1 ? assertSha(bases[0]) : undefined;
  }
  async findMergedBoundary({
    head,
    target,
    mergeCommits,
  }: {
    head: string;
    target: string;
    mergeCommits: string[];
  }): Promise<string | undefined> {
    if (!mergeCommits.length) return undefined;
    for (const sha of [head, target, ...mergeCommits]) await this.ensure(sha);
    for (const sha of mergeCommits)
      if (!(await this.ancestor(sha, head)) || !(await this.ancestor(sha, target)))
        return undefined;
    return this.mergeBase(head, target);
  }
  async rebase({
    number,
    head,
    boundary,
    target,
  }: {
    number: number;
    head: string;
    boundary: string;
    target: string;
  }): Promise<string> {
    for (const sha of [head, boundary, target]) await this.ensure(sha);
    if (head === target)
      throw new RestackException(
        "子PR固有の変更がありません。手動でPRを確認してください。",
        number,
      );
    if (await this.ancestor(target, head)) return head;
    if (!(await this.ancestor(boundary, head)))
      throw new RestackException(
        "確認した変更境界が現在のブランチにありません。手元でrestackしてから /stack sync を実行してください。",
        number,
      );
    if ((await this.run(["rev-list", "--merges", `${boundary}..${head}`])).output)
      throw new RestackException(
        "子PR固有の履歴にmerge commitがあります。直線的な履歴にしてください。",
        number,
      );
    const scratch = join(this.directory, "scratch");
    await mkdir(scratch, { recursive: true });
    const worktree = await mkdtemp(join(scratch, "rebase-"));
    await this.run(["worktree", "add", "--detach", worktree, head]);
    try {
      const result = await this.run(
        [
          "rebase",
          "--no-autostash",
          "--reapply-cherry-picks",
          "--empty=keep",
          "--onto",
          target,
          boundary,
        ],
        { cwd: worktree, accepted: [0, 1] },
      );
      if (result.code !== 0) {
        const files = (
          await this.run(["diff", "--name-only", "--diff-filter=U", "-z"], { cwd: worktree })
        ).output
          .split("\0")
          .filter(Boolean);
        throw new RestackException(
          "rebaseで競合しました。この処理ではブランチを更新していません。",
          number,
          files,
        );
      }
      const sha = assertSha((await this.run(["rev-parse", "HEAD"], { cwd: worktree })).output);
      if (sha === target)
        throw new RestackException("子PRの変更が空になります。手動で確認してください。", number);
      await this.pin(sha);
      return sha;
    } finally {
      await this.run(["worktree", "remove", "--force", worktree]);
    }
  }
  async remoteHeads(refs: string[]): Promise<Map<string, string>> {
    for (const ref of refs) await this.run(["check-ref-format", `refs/heads/${ref}`]);
    if (!refs.length) return new Map();
    const result = await this.run(
      ["ls-remote", "--heads", this.remote, ...refs.map((r) => `refs/heads/${r}`)],
      { network: true },
    );
    return new Map(
      result.output
        .split("\n")
        .filter(Boolean)
        .map((line) => {
          const [sha, ref] = line.split("\t");
          return [ref.replace(/^refs\/heads\//, ""), sha];
        }),
    );
  }
  async push(changes: BranchChange[]): Promise<void> {
    const updates = changes.filter((c) => c.changesHead);
    if (!updates.length) return;
    for (const c of updates) {
      await this.run(["check-ref-format", `refs/heads/${c.headRef}`]);
      assertSha(c.oldHead);
      assertSha(c.newHead);
    }
    // Explicit expected SHAs plus atomic push preserve concurrent user updates.
    await this.run(
      [
        "push",
        "--atomic",
        ...updates.map((c) => `--force-with-lease=refs/heads/${c.headRef}:${c.oldHead}`),
        this.remote,
        ...updates.map((c) => `${c.newHead}:refs/heads/${c.headRef}`),
      ],
      { network: true },
    );
  }
}
