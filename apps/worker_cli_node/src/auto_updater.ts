import { existsSync, realpathSync } from "node:fs";
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

const updateLockPath =
  process.env.OPENCI_WORKER_UPDATE_LOCK ?? "/tmp/openci-worker-cli-update.lock";
const staleLockMs = 10 * 60 * 1000;
const peerUpdateWaitMs = 5 * 60 * 1000;
const peerUpdatePollMs = 2_000;
const peerUpdateFinalPolls = 3;
const peerUpdateFinalPollMs = 500;

interface WaitForPeerUpdateOptions {
  lockPath?: string;
  waitMs?: number;
  pollMs?: number;
  finalPolls?: number;
  finalPollMs?: number;
  sleep?: (ms: number) => Promise<void>;
  readInstalledVersion?: () => Promise<string | null>;
}

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
  const response = await fetch(
    `https://registry.npmjs.org/${encodeURIComponent(defaultPackageName)}`,
    {
      headers: { Accept: "application/vnd.npm.install-v1+json" },
    },
  );
  if (!response.ok) {
    console.warn(`Auto-update check failed: npm registry returned ${response.status}`);
    return null;
  }
  const metadata = (await response.json()) as NpmPackageMetadata;
  return metadata["dist-tags"]?.latest ?? null;
}

function launchedPackageJsonPath(): string | null {
  const entryPoint = process.argv[1];
  if (!entryPoint) return null;

  try {
    const resolvedEntryPoint = realpathSync(entryPoint);
    return join(dirname(resolvedEntryPoint), "..", "package.json");
  } catch {
    return null;
  }
}

const defaultPackageJsonPath = launchedPackageJsonPath();

function packageJsonCandidatePaths(): string[] {
  return [process.env.OPENCI_WORKER_PACKAGE_JSON_PATH, defaultPackageJsonPath].filter(
    (path): path is string => Boolean(path),
  );
}

export async function installedPackageVersion(): Promise<string | null> {
  for (const packageJsonPath of packageJsonCandidatePaths()) {
    try {
      const packageJson = JSON.parse(await readFile(packageJsonPath, "utf8")) as {
        name?: string;
        version?: string;
      };
      if (packageJson.name !== defaultPackageName) continue;
      return packageJson.version ?? null;
    } catch {
      continue;
    }
  }
  return null;
}

async function installedVersionAtLeast(
  latestVersion: string,
  readInstalledVersion: () => Promise<string | null>,
): Promise<boolean> {
  try {
    const installedVersion = await readInstalledVersion();
    return Boolean(installedVersion && compareSemver(installedVersion, latestVersion) >= 0);
  } catch {
    return false;
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
    const child = spawn(
      npmExecutable(),
      ["install", "-g", `${defaultPackageName}@${nextVersion}`],
      {
        stdio: "inherit",
        env: process.env,
      },
    );
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
    await handle.writeFile(
      JSON.stringify({ pid: process.pid, startedAt: new Date().toISOString() }),
    );
    await handle.close();
    return true;
  } catch (error) {
    const code =
      error instanceof Error && "code" in error ? (error as NodeJS.ErrnoException).code : undefined;
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

async function finalInstalledVersionCheck(
  latestVersion: string,
  options: Required<
    Pick<WaitForPeerUpdateOptions, "finalPolls" | "finalPollMs" | "sleep" | "readInstalledVersion">
  >,
): Promise<boolean> {
  for (let attempt = 0; attempt < options.finalPolls; attempt += 1) {
    if (await installedVersionAtLeast(latestVersion, options.readInstalledVersion)) return true;
    await options.sleep(options.finalPollMs);
  }
  return false;
}

export async function waitForPeerUpdate(
  latestVersion: string,
  options: WaitForPeerUpdateOptions = {},
): Promise<boolean> {
  const lockPath = options.lockPath ?? updateLockPath;
  const sleepFn = options.sleep ?? sleep;
  const readInstalledVersion = options.readInstalledVersion ?? installedPackageVersion;
  const finalCheckOptions = {
    finalPolls: options.finalPolls ?? peerUpdateFinalPolls,
    finalPollMs: options.finalPollMs ?? peerUpdateFinalPollMs,
    sleep: sleepFn,
    readInstalledVersion,
  };
  const deadline = Date.now() + (options.waitMs ?? peerUpdateWaitMs);
  while (Date.now() < deadline) {
    if (await installedVersionAtLeast(latestVersion, readInstalledVersion)) return true;

    try {
      await stat(lockPath);
    } catch {
      return finalInstalledVersionCheck(latestVersion, finalCheckOptions);
    }
    await sleepFn(options.pollMs ?? peerUpdatePollMs);
  }
  return finalInstalledVersionCheck(latestVersion, finalCheckOptions);
}

export async function checkAndUpdate(): Promise<AutoUpdateResult> {
  let latestVersion: string | null = null;
  try {
    latestVersion = await latestPublishedVersion();
    if (!latestVersion || compareSemver(latestVersion, version) <= 0) return "current";

    console.log(`New worker version available: ${version} -> ${latestVersion}`);
    const installedVersion = await installedPackageVersion();
    if (installedVersion && compareSemver(installedVersion, latestVersion) >= 0) {
      console.log(
        `Installed ${defaultPackageName}@${installedVersion} is ready; exiting for restart`,
      );
      return "updated";
    }

    if (!(await acquireUpdateLock())) {
      console.log(
        `Another worker is installing ${defaultPackageName}@${latestVersion}; waiting for restart`,
      );
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
