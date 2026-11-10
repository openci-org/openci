import { execFileSync, spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { expect, test } from "vite-plus/test";
import { checkoutScript, type Job } from "../../executor/model.js";
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
  const checkoutSha = await github.resolveCheckoutCommit(pushJob(queuedSha), "10");
  const result = repo.exec(checkoutScript(checkoutSha, repo.source, "test-token"));
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

function pushJob(commitSha: string): Job {
  return {
    id: "job",
    owner: "org",
    repo: "app",
    status: "RUNNING",
    workflowName: "Test",
    workflowFileName: "ci.dart",
    commitSha,
    pullRequestNumber: null,
  };
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
  };
}
