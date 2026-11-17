import { execFileSync, spawnSync } from "node:child_process";
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { expect, test } from "vite-plus/test";
import { checkoutScript, localMergeConflictExitCode, type Job } from "../../executor/model.js";
import { ExecutionGitHub } from "../../executor/github.js";

test("実行待ちにブランチが進んでも、pushされたコミットを使う", async ({ onTestFinished }) => {
  const root = mkdtempSync(join(tmpdir(), "openci-push-"));
  onTestFinished(() => rmSync(root, { recursive: true, force: true }));
  const repo = checkoutFixture(root);
  const queuedSha = repo.commitVersion("queued");
  repo.commitVersion("newer");

  const github = new ExecutionGitHub({
    appId: "1",
    privateKey: "unused-for-push",
    apiBaseUrl: "https://api.github.com",
    baseUrl: "https://github.com",
  });
  const context = await github.resolveCheckout(pushJob(queuedSha), "10");
  if (context.event !== "push") throw new Error("Expected a push checkout");
  expect(context).toEqual({
    event: "push",
    branch: "main",
    commitSha: queuedSha,
    checkoutSha: queuedSha,
  });
  const result = repo.exec(checkoutScript(context.checkoutSha, repo.source, "test-token"));
  expect(result.status, result.stderr).toBe(0);
  expect(repo.checkedOutSha()).toBe(queuedSha);
});

test("PR の merge ref が進んでも、解決済みのマージコミットを checkout する", ({
  onTestFinished,
}) => {
  const root = mkdtempSync(join(tmpdir(), "openci-merge-"));
  onTestFinished(() => rmSync(root, { recursive: true, force: true }));
  const repo = checkoutFixture(root);
  repo.commitVersion("initial");
  repo.git("checkout", "-q", "-b", "pr");
  repo.commitVersion("PR change");
  repo.git("checkout", "-q", "main");
  writeFileSync(join(repo.source, "base.txt"), "base change");
  repo.git("add", "base.txt");
  repo.git("commit", "-q", "-m", "base change");
  repo.git("merge", "--quiet", "--no-ff", "pr", "-m", "test merge");
  const mergeSha = repo.git("rev-parse", "HEAD");
  repo.git("update-ref", "refs/pull/7/merge", mergeSha);
  repo.git("commit", "--quiet", "--amend", "-m", "newer test merge");
  repo.git("update-ref", "refs/pull/7/merge", "HEAD");

  const result = repo.exec(checkoutScript(mergeSha, repo.source, "test-token"));

  expect(result.status, result.stderr).toBe(0);
  expect(repo.checkedOutSha()).toBe(mergeSha);
  expect(result.stdout).toContain(mergeSha);
  const checkout = join(root, "vm", "openci-build");
  expect(readFileSync(join(checkout, "base.txt"), "utf8")).toBe("base change");
  expect(readFileSync(join(checkout, "version.txt"), "utf8")).toBe("PR change");
});

test("古い merge ref を使わず固定した base と head からテストマージを作る", ({
  onTestFinished,
}) => {
  const root = mkdtempSync(join(tmpdir(), "openci-local-merge-"));
  onTestFinished(() => rmSync(root, { recursive: true, force: true }));
  const repo = checkoutFixture(root);
  repo.commitVersion("initial");
  repo.git("checkout", "-q", "-b", "pr");
  const headSha = repo.commitVersion("PR change");
  repo.git("checkout", "-q", "main");
  repo.git("merge", "--quiet", "--no-ff", "pr", "-m", "stale test merge");
  repo.git("update-ref", "refs/pull/7/merge", "HEAD");
  repo.git("reset", "--hard", "HEAD^1");
  writeFileSync(join(repo.source, "base.txt"), "latest base change");
  repo.git("add", "base.txt");
  repo.git("commit", "-q", "-m", "base change");
  const baseSha = repo.git("rev-parse", "HEAD");
  // Neither moving branch may change the already selected checkout snapshot.
  repo.commitVersion("later base change");
  repo.git("checkout", "-q", "pr");
  repo.commitVersion("later PR change");

  const result = repo.exec(checkoutScript(headSha, repo.source, "test-token", baseSha));

  expect(result.status, result.stderr).toBe(0);
  expect(repo.checkoutGit("show", "-s", "--format=%P", "HEAD")).toBe(`${baseSha} ${headSha}`);
  expect(result.stdout.trim().split("\n").at(-1)).toBe(repo.checkedOutSha());
  const checkout = join(root, "vm", "openci-build");
  expect(readFileSync(join(checkout, "base.txt"), "utf8")).toBe("latest base change");
  expect(readFileSync(join(checkout, "version.txt"), "utf8")).toBe("PR change");
  expect(readFileSync(join(checkout, ".git/config"), "utf8")).not.toContain("test-token");
});

test("最新 base と PR が競合したらワークツリーへ展開せず専用の終了コードを返す", ({
  onTestFinished,
}) => {
  const root = mkdtempSync(join(tmpdir(), "openci-local-conflict-"));
  onTestFinished(() => rmSync(root, { recursive: true, force: true }));
  const repo = checkoutFixture(root);
  repo.commitVersion("initial");
  repo.git("checkout", "-q", "-b", "pr");
  const headSha = repo.commitVersion("PR change");
  repo.git("checkout", "-q", "main");
  const baseSha = repo.commitVersion("conflicting base change");

  const result = repo.exec(checkoutScript(headSha, repo.source, "test-token", baseSha));

  expect(result.status, result.stderr).toBe(localMergeConflictExitCode);
  expect(existsSync(join(root, "vm", "openci-build", "version.txt"))).toBe(false);
});

for (const scenario of ["fast-forward", "already-contained"]) {
  test(`${scenario} でも両方の親を持つテストマージを作る`, ({ onTestFinished }) => {
    const root = mkdtempSync(join(tmpdir(), "openci-local-ancestor-"));
    onTestFinished(() => rmSync(root, { recursive: true, force: true }));
    const repo = checkoutFixture(root);
    const older = repo.commitVersion("older");
    const newer = repo.commitVersion("newer");
    const [baseSha, headSha] = scenario === "fast-forward" ? [older, newer] : [newer, older];

    const result = repo.exec(checkoutScript(headSha, repo.source, "test-token", baseSha));

    expect(result.status, result.stderr).toBe(0);
    expect(repo.checkoutGit("show", "-s", "--format=%P", "HEAD")).toBe(`${baseSha} ${headSha}`);
    expect(repo.checkoutGit("show", "HEAD:version.txt")).toBe("newer");
  });
}

function pushJob(commitSha: string): Job {
  return {
    retryCount: 0,
    id: "job",
    owner: "org",
    repo: "app",
    status: "RUNNING",
    workflowName: "Test",
    workflowFileName: "ci.dart",
    commitSha,
    pullRequestNumber: null,
    branch: "main",
  };
}

for (const { failures, attempts, status } of [
  { failures: 1, attempts: 2, status: 0 },
  { failures: 3, attempts: 3, status: 1 },
]) {
  test(`checkout handles ${failures} interrupted fetches`, ({ onTestFinished }) => {
    const root = mkdtempSync(join(tmpdir(), "openci-fetch-retry-"));
    onTestFinished(() => rmSync(root, { recursive: true, force: true }));
    const repo = checkoutFixture(root);
    const queuedSha = repo.commitVersion("queued");
    const result = repo.exec(`
fetch_attempts=0
git() {
  if [[ " $* " == *" fetch "* ]]; then
    fetch_attempts=$((fetch_attempts + 1))
    printf 'fetch attempt %s\\n' "$fetch_attempts" >&2
    if (( fetch_attempts <= ${failures} )); then
      printf 'fatal: Recv failure: Connection reset by peer\\n' >&2
      return 128
    fi
  fi
  command git "$@"
}
sleep() { :; }
${checkoutScript(queuedSha, repo.source, "test-token")}`);

    expect(result.status, result.stderr).toBe(status);
    expect(result.stderr.match(/fetch attempt /g)).toHaveLength(attempts);
    if (status === 0) {
      expect(repo.checkedOutSha()).toBe(queuedSha);
    } else {
      expect(existsSync(join(root, "vm", "openci-build", "version.txt"))).toBe(false);
    }
  });
}

function checkoutFixture(root: string) {
  const source = join(root, "source");
  const vmHome = join(root, "vm");
  const env = {
    PATH: process.env.PATH,
    GIT_CONFIG_NOSYSTEM: "1",
    GIT_CONFIG_GLOBAL: "/dev/null",
    CHECKOUT_TEST_HOME: vmHome,
  };
  const git = (cwd: string, ...args: string[]) =>
    execFileSync("git", args, { cwd, env, encoding: "utf8" }).trim();
  git(root, "init", "--quiet", "--initial-branch=main", source);
  git(source, "config", "user.name", "CI test");
  git(source, "config", "user.email", "ci@example.test");
  return {
    source,
    git: (...args: string[]) => git(source, ...args),
    commitVersion(version: string) {
      writeFileSync(join(source, "version.txt"), version);
      git(source, "add", "version.txt");
      git(source, "commit", "--quiet", "-m", version);
      return git(source, "rev-parse", "HEAD");
    },
    exec(script: string) {
      return spawnSync("/bin/bash", ["-s"], {
        input: script.replaceAll("/Users/admin", '"$CHECKOUT_TEST_HOME"'),
        env,
        encoding: "utf8",
      });
    },
    checkedOutSha: () => git(join(vmHome, "openci-build"), "rev-parse", "HEAD"),
    checkoutGit: (...args: string[]) => git(join(vmHome, "openci-build"), ...args),
  };
}
