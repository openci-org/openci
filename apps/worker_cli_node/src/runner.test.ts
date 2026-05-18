import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

import { afterEach, describe, expect, it } from "vitest";

import { baseVmName } from "./constants.js";
import {
  ensureBaseVm,
  parseLumeVmJsonList,
  parseLumeVmTextList,
  rewriteWorkflowForSingleOpenCiJob,
  type LumeVm,
} from "./runner.js";

const tempDirs: string[] = [];

async function tempLockPath(): Promise<string> {
  const dir = await mkdtemp(join(tmpdir(), "openci-worker-runner-test-"));
  tempDirs.push(dir);
  return join(dir, "vm-image.lock");
}

afterEach(async () => {
  await Promise.all(tempDirs.splice(0).map((dir) => rm(dir, { recursive: true, force: true })));
});

describe("parseLumeVmJsonList", () => {
  it("parses array output", () => {
    expect(
      parseLumeVmJsonList(
        JSON.stringify([
          { name: "openci-vm-worker-12345678", status: "running" },
          { name: "base-vm", state: "stopped" },
        ]),
      ),
    ).toEqual([
      { name: "openci-vm-worker-12345678", status: "running" },
      { name: "base-vm", status: "stopped" },
    ]);
  });

  it("parses wrapped output", () => {
    expect(
      parseLumeVmJsonList(JSON.stringify({ vms: [{ name: "openci-vm-worker-12345678" }] })),
    ).toEqual([{ name: "openci-vm-worker-12345678", status: "" }]);
  });
});

describe("parseLumeVmTextList", () => {
  it("keeps normal table VM names", () => {
    const output = [
      "NAME OS CPU MEMORY DISK DISPLAY STATUS IP",
      "openci-vm-worker-12345678 macOS 4 8GB 50GB 1024x768 stopped 192.168.64.2",
    ].join("\n");

    expect(parseLumeVmTextList(output)).toEqual([
      { name: "openci-vm-worker-12345678", status: "stopped" },
    ]);
  });

  it("strips an OS column that is joined to an overflowing VM name", () => {
    const output = [
      "NAME OS CPU MEMORY DISK DISPLAY STATUS IP",
      "openci-vm-admins-Mini-2-worker1-51ad7c53macOS 4 8GB 50GB 1024x768 stopped 192.168.64.2",
    ].join("\n");

    expect(parseLumeVmTextList(output)).toEqual([
      { name: "openci-vm-admins-Mini-2-worker1-51ad7c53", status: "stopped" },
    ]);
  });
});

describe("rewriteWorkflowForSingleOpenCiJob", () => {
  it("removes needs only from the target job", () => {
    const workflow = [
      "name: CI",
      "on: pull_request",
      "jobs:",
      "  ci:",
      "    runs-on: ubuntu-latest",
      "    steps:",
      "      - run: echo ci",
      "  deploy-web:",
      "    needs: [ci]",
      "    runs-on: ubuntu-latest",
      "    steps:",
      "      - run: echo web",
      "  build-macos:",
      "    needs: [ci]",
      "    runs-on: macos-latest",
      "    steps:",
      "      - run: echo mac",
      "",
    ].join("\n");

    const result = rewriteWorkflowForSingleOpenCiJob(workflow, "deploy-web", ["ci"]);

    expect(result.rewritten).toBe(true);
    expect(result.content).toContain("deploy-web:");
    expect(result.content).toContain("build-macos:\n    needs:");
    expect(result.content).not.toContain("deploy-web:\n    needs:");
  });

  it("keeps the original workflow when the job reads needs context", () => {
    const workflow = [
      "name: CI",
      "on: pull_request",
      "jobs:",
      "  ci:",
      "    runs-on: ubuntu-latest",
      "    outputs:",
      "      artifact-name: ${{ steps.build.outputs.artifact-name }}",
      "    steps:",
      "      - id: build",
      '        run: echo artifact-name=app >> "$GITHUB_OUTPUT"',
      "  deploy-web:",
      "    needs: [ci]",
      "    runs-on: ubuntu-latest",
      "    steps:",
      "      - run: echo ${{ needs.ci.outputs.artifact-name }}",
      "",
    ].join("\n");

    const result = rewriteWorkflowForSingleOpenCiJob(workflow, "deploy-web", ["ci"]);

    expect(result).toEqual({
      content: workflow,
      rewritten: false,
      reason: "needs-context",
    });
  });

  it("does not rewrite jobs without OpenCI-resolved needs", () => {
    const workflow = [
      "name: CI",
      "on: pull_request",
      "jobs:",
      "  ci:",
      "    runs-on: ubuntu-latest",
      "    steps:",
      "      - run: echo ci",
      "",
    ].join("\n");

    const result = rewriteWorkflowForSingleOpenCiJob(workflow, "ci", []);

    expect(result).toEqual({
      content: workflow,
      rewritten: false,
      reason: "no-needs",
    });
  });
});

describe("ensureBaseVm", () => {
  it("pulls the base VM when it is missing", async () => {
    const lockPath = await tempLockPath();
    const pullCalls: string[] = [];
    const vms: LumeVm[] = [];

    await ensureBaseVm({
      lockPath,
      listVms: async () => vms,
      pullBaseVm: async () => {
        pullCalls.push("pull");
        vms.push({ name: baseVmName, status: "stopped" });
      },
    });

    expect(pullCalls).toEqual(["pull"]);
  });

  it("skips pulling when the base VM already exists", async () => {
    const lockPath = await tempLockPath();
    const pullCalls: string[] = [];

    await ensureBaseVm({
      lockPath,
      listVms: async () => [{ name: baseVmName, status: "stopped" }],
      pullBaseVm: async () => {
        pullCalls.push("pull");
      },
    });

    expect(pullCalls).toEqual([]);
  });

  it("serializes concurrent base VM pulls on the same host", async () => {
    const lockPath = await tempLockPath();
    let vms: LumeVm[] = [];
    let pullCount = 0;
    let finishPull!: () => void;
    let markPullStarted!: () => void;
    const pullFinished = new Promise<void>((resolve) => {
      finishPull = resolve;
    });
    const pullStarted = new Promise<void>((resolve) => {
      markPullStarted = resolve;
    });
    const options = {
      lockPath,
      listVms: async () => vms,
      pullBaseVm: async () => {
        pullCount += 1;
        markPullStarted();
        await pullFinished;
        vms = [{ name: baseVmName, status: "stopped" }];
      },
      sleep: async (ms: number) => {
        await new Promise((resolve) => setTimeout(resolve, ms));
      },
      peerPollMs: 1,
      peerWaitMs: 1_000,
      staleLockMs: 1_000,
    };

    const first = ensureBaseVm(options);
    await pullStarted;

    const second = ensureBaseVm(options);
    await new Promise((resolve) => setTimeout(resolve, 10));
    expect(pullCount).toBe(1);

    finishPull!();
    await Promise.all([first, second]);

    expect(pullCount).toBe(1);
  });
});
