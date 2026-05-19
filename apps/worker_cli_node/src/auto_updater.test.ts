import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

import { afterEach, describe, expect, it } from "vitest";

import { installedPackageVersion, waitForPeerUpdate } from "./auto_updater.js";

const tempDirs: string[] = [];
const originalEnv = {
  OPENCI_WORKER_PACKAGE_JSON_PATH: process.env.OPENCI_WORKER_PACKAGE_JSON_PATH,
};

function restoreEnvValue(name: string, value: string | undefined): void {
  if (value === undefined) {
    delete process.env[name];
  } else {
    process.env[name] = value;
  }
}

async function tempDir(): Promise<string> {
  const dir = await mkdtemp(join(tmpdir(), "openci-worker-auto-updater-test-"));
  tempDirs.push(dir);
  return dir;
}

afterEach(async () => {
  restoreEnvValue("OPENCI_WORKER_PACKAGE_JSON_PATH", originalEnv.OPENCI_WORKER_PACKAGE_JSON_PATH);
  await Promise.all(tempDirs.splice(0).map((dir) => rm(dir, { recursive: true, force: true })));
});

describe("installedPackageVersion", () => {
  it("reads the worker package version from the configured package.json", async () => {
    const dir = await tempDir();
    const packageJsonPath = join(dir, "package.json");
    await writeFile(
      packageJsonPath,
      JSON.stringify({ name: "openci-worker-cli", version: "0.1.40" }),
    );
    process.env.OPENCI_WORKER_PACKAGE_JSON_PATH = packageJsonPath;

    await expect(installedPackageVersion()).resolves.toBe("0.1.40");
  });

  it("ignores package.json files from other packages", async () => {
    const dir = await tempDir();
    const packageJsonPath = join(dir, "package.json");
    await writeFile(packageJsonPath, JSON.stringify({ name: "vitest", version: "4.1.5" }));
    process.env.OPENCI_WORKER_PACKAGE_JSON_PATH = packageJsonPath;

    await expect(installedPackageVersion()).resolves.toBeNull();
  });
});

describe("waitForPeerUpdate", () => {
  it("treats a peer update as successful when the lock is gone and the installed version is current", async () => {
    let reads = 0;

    const result = await waitForPeerUpdate("0.1.40", {
      lockPath: join(tmpdir(), "openci-worker-missing-update.lock"),
      finalPolls: 2,
      finalPollMs: 0,
      sleep: async () => undefined,
      readInstalledVersion: async () => {
        reads += 1;
        return reads >= 2 ? "0.1.40" : "0.1.39";
      },
    });

    expect(result).toBe(true);
  });
});
