import { readFileSync } from "node:fs";

import type { WorkerConfig } from "./types.js";
import { version } from "./version.js";

const defaultPollIntervalMs = 10_000;

function readOption(args: string[], name: string, shortName?: string): string | undefined {
  const longPrefix = `--${name}=`;
  const longValue = args.find((arg) => arg.startsWith(longPrefix));
  if (longValue) return longValue.slice(longPrefix.length);

  const longIndex = args.indexOf(`--${name}`);
  if (longIndex >= 0) return args[longIndex + 1];

  if (shortName) {
    const shortIndex = args.indexOf(`-${shortName}`);
    if (shortIndex >= 0) return args[shortIndex + 1];
  }
  return undefined;
}

export function printUsage(): void {
  console.log(`Usage: openci_worker --service-account <path> --worker-id <id> [options]

Options:
  -s, --service-account <path>  Firebase service account JSON file
  -w, --worker-id <id>          Unique worker ID
      --poll-interval <ms>      Poll interval in milliseconds (default: ${defaultPollIntervalMs})
      --runs-on <pattern>       SQL LIKE pattern to claim specific jobs (e.g. %macos-dedicated%)
      --once                    Process at most one job, then exit
  -h, --help                    Print this help
      --version                 Print version
`);
}

export function parseConfig(args: string[]): WorkerConfig | null {
  if (args.includes("--help") || args.includes("-h")) {
    printUsage();
    return null;
  }
  if (args.includes("--version")) {
    console.log(`openci-worker-node ${version}`);
    return null;
  }

  const serviceAccountPath = readOption(args, "service-account", "s");
  const workerId = readOption(args, "worker-id", "w");
  if (!serviceAccountPath) throw new Error("--service-account is required");
  if (!workerId) throw new Error("--worker-id is required");

  const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, "utf8")) as {
    project_id?: string;
  };
  const projectId = serviceAccount.project_id;
  if (!projectId) throw new Error("project_id not found in service account file");

  const pollIntervalRaw = readOption(args, "poll-interval");
  const pollIntervalMs = pollIntervalRaw
    ? Number.parseInt(pollIntervalRaw, 10)
    : defaultPollIntervalMs;
  if (!Number.isFinite(pollIntervalMs) || pollIntervalMs <= 0) {
    throw new Error("--poll-interval must be a positive integer");
  }

  process.env.GOOGLE_APPLICATION_CREDENTIALS = serviceAccountPath;

  const runsOnPattern = readOption(args, "runs-on");

  return {
    serviceAccountPath,
    workerId,
    projectId,
    pollIntervalMs,
    once: args.includes("--once"),
    runsOnPattern,
  };
}
