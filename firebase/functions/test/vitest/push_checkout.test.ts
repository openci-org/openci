import { execFileSync, spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { expect, test } from "vite-plus/test";
import { checkoutScript, type Job } from "../../executor/model.js";

test("実行待ちにブランチが進んでも、pushされたコミットを使う", ({ onTestFinished }) => {
  const root = mkdtempSync(join(tmpdir(), "openci-push-"));
  onTestFinished(() => rmSync(root, { recursive: true, force: true }));
  const repo = checkoutFixture(root);
  const queuedSha = repo.commitVersion("queued");
  repo.commitVersion("newer");

  const result = repo.exec(checkoutScript(pushJob(queuedSha), repo.source, "test-token"));
  expect(result.status, result.stderr).toBe(0);
  expect(repo.checkedOutSha()).toBe(queuedSha);
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
