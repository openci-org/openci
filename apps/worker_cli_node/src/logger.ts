import { randomUUID } from "node:crypto";

import { appendLog } from "./dataconnect.js";

type LogLevel = "info" | "warning" | "error";

interface PendingLogEntry {
  buildJobId: string;
  runId: string;
  level: LogLevel;
  message: string;
  stackTrace?: string;
}

const maxWriteAttempts = 5;
const initialRetryDelayMs = 500;

let pendingWrites = 0;
let logWriteTail: Promise<void> = Promise.resolve();

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function appendLogWithRetry(entry: PendingLogEntry): Promise<void> {
  for (let attempt = 1; attempt <= maxWriteAttempts; attempt++) {
    try {
      await appendLog({
        buildJobId: entry.buildJobId,
        runId: entry.runId,
        id: randomUUID(),
        message: entry.message,
        level: entry.level,
        timestamp: new Date().toISOString(),
        ...(entry.stackTrace ? { stackTrace: entry.stackTrace } : {}),
      });
      return;
    } catch (error) {
      if (attempt === maxWriteAttempts) {
        console.warn(`[BuildLog] Failed to write log: ${String(error)}`);
        return;
      }
      await delay(initialRetryDelayMs * 2 ** (attempt - 1));
    }
  }
}

async function writeBuildLog(
  buildJobId: string,
  runId: string,
  level: LogLevel,
  message: string,
  stackTrace?: string,
): Promise<void> {
  pendingWrites++;
  logWriteTail = logWriteTail
    .then(() => appendLogWithRetry({ buildJobId, runId, level, message, stackTrace }))
    .finally(() => {
      pendingWrites--;
    });
  await Promise.resolve();
}

export async function flushLogs(): Promise<void> {
  while (pendingWrites > 0) {
    await logWriteTail;
  }
}

export async function logInfo(buildJobId: string, runId: string, message: string): Promise<void> {
  console.log(message);
  await writeBuildLog(buildJobId, runId, "info", message);
}

export async function logWarning(
  buildJobId: string,
  runId: string,
  message: string,
): Promise<void> {
  console.warn(message);
  await writeBuildLog(buildJobId, runId, "warning", message);
}

export async function logError(
  buildJobId: string,
  runId: string,
  message: string,
  stackTrace?: string,
): Promise<void> {
  console.error(message);
  if (stackTrace) console.error(stackTrace);
  await writeBuildLog(buildJobId, runId, "error", message, stackTrace);
}
