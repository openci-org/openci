import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import { prQrOutputDirectory, workflowScript } from "../../lib/functions/executor/model.js";

const root = fileURLToPath(new URL("../../../", import.meta.url));
const dart = execFileSync("which", ["dart"], { encoding: "utf8" }).trim();
const head = "a".repeat(40);
const base = "b".repeat(40);
const merge = "c".repeat(40);

for (const checkout of [
  { event: "push", branch: "develop", commitSha: head, checkoutSha: head },
  {
    event: "pull_request",
    number: 123,
    headBranch: "feature/it's-$(echo_unexpected)",
    baseBranch: "release/日本語",
    headSha: head,
    baseSha: base,
    checkoutSha: merge,
  },
]) {
  test(`executor shell exports a ${checkout.event} context consumed by the Dart SDK`, (t) => {
    const temporary = mkdtempSync(join(tmpdir(), "openci-context-"));
    t.after(() => rmSync(temporary, { recursive: true, force: true }));
    const dispatch = { id: "dispatch", runId: "run-dispatch", teamId: "team" };
    const job = {
      id: "job",
      owner: "org",
      repo: "app",
      githubBaseUrl: checkout.event === "push" ? "https://github.com" : "https://github.example",
      workflowFileName: "ci.dart",
      pullRequestNumber: checkout.event === "push" ? null : String(checkout.number),
    };
    const script = workflowScript(
      job,
      dispatch,
      42,
      { EXAMPLE_SECRET: "never-context" },
      checkout,
    ).replaceAll(prQrOutputDirectory, join(temporary, "qr"));
    // Execute the real shell exports and Dart decoder. Only VM navigation and
    // Flutter package/entrypoint commands are replaced with the SDK probe.
    const result = spawnSync("/bin/bash", ["-s"], {
      input:
        `
cd() { :; }
flutter() {
  if [[ "$2" == run ]]; then
    "$CONTEXT_TEST_DART" --packages="$CONTEXT_TEST_PACKAGES" "$CONTEXT_TEST_PROBE"
  fi
}
` + script,
      env: {
        PATH: "/usr/bin:/bin",
        CONTEXT_TEST_DART: dart,
        CONTEXT_TEST_PACKAGES: join(root, ".dart_tool/package_config.json"),
        CONTEXT_TEST_PROBE: join(
          root,
          "packages/openci_workflow/test/fixtures/read_workflow_context.dart",
        ),
      },
      encoding: "utf8",
      timeout: 30000,
    });
    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(JSON.parse(result.stdout), {
      repository: { owner: job.owner, name: job.repo, githubBaseUrl: job.githubBaseUrl },
      jobId: job.id,
      runId: dispatch.runId,
      runNumber: 42,
      ...checkout,
    });
    assert.ok(!result.stdout.includes("never-context"));
  });
}
