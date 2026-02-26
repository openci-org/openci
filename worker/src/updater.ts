import { execSync, spawn } from "node:child_process";

const GITHUB_API = "https://api.github.com/repos/open-ci-io/openci/releases";
const RELEASE_TAG_PREFIX = "openci-worker-v";

function parseVersion(version: string): number[] {
  return version.split(".").map(Number);
}

function isNewer(latest: string, current: string): boolean {
  const l = parseVersion(latest);
  const c = parseVersion(current);
  for (let i = 0; i < Math.max(l.length, c.length); i++) {
    const lv = l[i] ?? 0;
    const cv = c[i] ?? 0;
    if (lv > cv) return true;
    if (lv < cv) return false;
  }
  return false;
}

export async function checkForUpdate(currentVersion: string): Promise<string | null> {
  try {
    const res = await fetch(`${GITHUB_API}?per_page=20`, {
      headers: { "User-Agent": "openci-worker" },
    });

    if (!res.ok) return null;

    const releases = (await res.json()) as Array<{
      tag_name: string;
      draft: boolean;
      prerelease: boolean;
    }>;

    const workerReleases = releases.filter(
      (r) => r.tag_name.startsWith(RELEASE_TAG_PREFIX) && !r.draft && !r.prerelease,
    );

    if (workerReleases.length === 0) return null;

    const latestTag = workerReleases[0].tag_name;
    const latestVersion = latestTag.replace(RELEASE_TAG_PREFIX, "");

    if (isNewer(latestVersion, currentVersion)) {
      return latestVersion;
    }

    return null;
  } catch {
    return null;
  }
}

export function performUpdate(): boolean {
  const env = {
    ...process.env,
    PATH: `/opt/homebrew/bin:/usr/local/bin:${process.env.PATH ?? ""}`,
  };

  try {
    execSync("brew update", {
      stdio: "inherit",
      timeout: 120_000,
      env,
    });
    execSync("brew upgrade open-ci-io/tap/openci-worker", {
      stdio: "inherit",
      timeout: 120_000,
      env,
    });
    return true;
  } catch (err) {
    console.error("performUpdate failed:", err instanceof Error ? err.message : err);
    return false;
  }
}

export function restartWorker(): never {
  const args = process.argv.slice(1);
  const child = spawn(process.argv[0], args, {
    stdio: "inherit",
    detached: true,
  });
  child.unref();
  process.exit(0);
}
