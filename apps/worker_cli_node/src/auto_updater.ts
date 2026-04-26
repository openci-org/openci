import { existsSync } from "node:fs";
import { open, readFile, stat, unlink } from "node:fs/promises";
import { dirname, join } from "node:path";
import { spawn } from "node:child_process";

import { defaultPackageName, exitCodeUpdateRequested } from "./constants.js";
import { version } from "./version.js";

interface NpmPackageMetadata {
  "dist-tags"?: {
    latest?: string;
  };
}

export type AutoUpdateResult = "current" | "updated" | "failed";

const updateLockPath = process.env.OPENCI_WORKER_UPDATE_LOCK ?? "/tmp/openci-worker-cli-update.lock";
const staleLockMs = 10 * 60 * 1000;
const peerUpdateWaitMs = 5 * 60 * 1000;

function compareSemver(remote: string, current: string): number {
  const remoteParts = remote.split(".").map((part) => Number.parseInt(part, 10));
  const currentParts = current.split(".").map((part) => Number.parseInt(part, 10));
  for (let index = 0; index < 3; index += 1) {
    const remotePart = Number.isFinite(remoteParts[index]) ? remoteParts[index]! : 0;
    const currentPart = Number.isFinite(currentParts[index]) ? currentParts[index]! : 0;
    if (remotePart > currentPart) return 1;
    if (remotePart < currentPart) return -1;
  }
  return 0;
}

async function latestPublishedVersion(): Promise<string | null> {
  const response = await fetch(`https://registry.npmjs.org/${encodeURIComponent(defaultPackageName)}`, {
    headers: { Accept: "application/vnd.npm.install-v1+json" },
  });
  if (!response.ok) {
    console.warn(`Auto-update check failed: npm registry returned ${response.status}`);
    return null;
  }
  const metadata = (await response.json()) as NpmPackageMetadata;
  return metadata["dist-tags"]?.latest ?? null;
}

async function installedPackageVersion(): Promise<string | null> {
  try {
    const packageJsonUrl = new URL("../package.json", import.meta.url);
    const packageJson = JSON.parse(await readFile(packageJsonUrl, "utf8")) as { version?: string };
    return packageJson.version ?? null;
  } catch {
    return null;
  }
}

async function sleep(ms: number): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, ms));
}

function npmExecutable(): string {
  const siblingNpm = join(dirname(process.execPath), "npm");
  return existsSync(siblingNpm) ? siblingNpm : "npm";
}

async function installVersion(nextVersion: string): Promise<void> {
  await new Promise<void>((resolve, reject) => {
    const child = spawn(npmExecutable(), ["install", "-g", `${defaultPackageName}@${nextVersion}`], {
      stdio: "inherit",
      env: process.env,
    });
    child.on("error", reject);
    child.on("close", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`npm install exited with code ${code ?? "unknown"}`));
    });
  });
}

async function acquireUpdateLock(): Promise<boolean> {
  try {
    const handle = await open(updateLockPath, "wx");
    await handle.writeFile(JSON.stringify({ pid: process.pid, startedAt: new Date().toISOString() }));
    await handle.close();
    return true;
  } catch (error) {
    const code = error instanceof Error && "code" in error ? (error as NodeJS.ErrnoException).code : undefined;
    if (code !== "EEXIST") throw error;

    try {
      const current = await stat(updateLockPath);
      if (Date.now() - current.mtimeMs > staleLockMs) {
        await unlink(updateLockPath);
        return acquireUpdateLock();
      }
    } catch {
      return acquireUpdateLock();
    }
    return false;
  }
}

async function releaseUpdateLock(): Promise<void> {
  await unlink(updateLockPath).catch(() => undefined);
}

async function waitForPeerUpdate(latestVersion: string): Promise<boolean> {
  const deadline = Date.now() + peerUpdateWaitMs;
  while (Date.now() < deadline) {
    const installedVersion = await installedPackageVersion();
    if (installedVersion && compareSemver(installedVersion, latestVersion) >= 0) return true;

    try {
      await stat(updateLockPath);
    } catch {
      return false;
    }
    await sleep(2_000);
  }
  return false;
}

export async function checkAndUpdate(): Promise<AutoUpdateResult> {
  let latestVersion: string | null = null;
  try {
    latestVersion = await latestPublishedVersion();
    if (!latestVersion || compareSemver(latestVersion, version) <= 0) return "current";

    console.log(`New worker version available: ${version} -> ${latestVersion}`);
    if (!(await acquireUpdateLock())) {
      console.log(`Another worker is installing ${defaultPackageName}@${latestVersion}; waiting for restart`);
      return (await waitForPeerUpdate(latestVersion)) ? "updated" : "failed";
    }

    try {
      await installVersion(latestVersion);
      console.log(`Installed ${defaultPackageName}@${latestVersion}; exiting for restart`);
      return "updated";
    } finally {
      await releaseUpdateLock();
    }
  } catch (error) {
    console.warn(`Auto-update failed: ${String(error)}`);
    return latestVersion ? "failed" : "current";
  }
}

export function exitForUpdate(): never {
  process.exit(exitCodeUpdateRequested);
}

