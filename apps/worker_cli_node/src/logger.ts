import { randomUUID } from "node:crypto";
import { appendBuildLogs } from "./firestore.js";

type LogLevel = "info" | "warning" | "error";

interface LogBufferEntry {
  id: string;
  message: string;
  level: LogLevel;
  timestamp: string;
  stackTrace?: string;
}

interface BufferGroup {
  buildJobId: string;
  runId: string;
  entries: LogBufferEntry[];
  timer: NodeJS.Timeout | null;
}

const maxBufferCount = 50;
const flushIntervalMs = 1000;
const maxWriteAttempts = 5;
const initialRetryDelayMs = 500;

const bufferGroups = new Map<string, BufferGroup>();
let activeWritePromises: Promise<void>[] = [];

function getBufferGroup(buildJobId: string, runId: string): BufferGroup {
  const key = `${buildJobId}:${runId}`;
  let group = bufferGroups.get(key);
  if (!group) {
    group = {
      buildJobId,
      runId,
      entries: [],
      timer: null,
    };
    bufferGroups.set(key, group);
  }
  return group;
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function sendLogsWithRetry(
  buildJobId: string,
  runId: string,
  logs: LogBufferEntry[],
): Promise<void> {
  for (let attempt = 1; attempt <= maxWriteAttempts; attempt++) {
    try {
      await appendBuildLogs({
        buildJobId,
        runId,
        logs,
      });
      return;
    } catch (error) {
      if (attempt === maxWriteAttempts) {
        console.warn(`[BuildLog] Failed to send bulk logs: ${String(error)}`);
        return;
      }
      await delay(initialRetryDelayMs * 2 ** (attempt - 1));
    }
  }
}

function triggerFlush(group: BufferGroup): void {
  if (group.timer) {
    clearTimeout(group.timer);
    group.timer = null;
  }

  if (group.entries.length === 0) return;

  const logsToSend = [...group.entries];
  group.entries = []; // バッファを即時クリア

  const writePromise = sendLogsWithRetry(group.buildJobId, group.runId, logsToSend).finally(() => {
    activeWritePromises = activeWritePromises.filter((p) => p !== writePromise);
  });

  activeWritePromises.push(writePromise);
}

async function writeBuildLog(
  buildJobId: string,
  runId: string,
  level: LogLevel,
  message: string,
  stackTrace?: string,
): Promise<void> {
  const group = getBufferGroup(buildJobId, runId);
  group.entries.push({
    id: randomUUID(),
    message,
    level,
    timestamp: new Date().toISOString(),
    ...(stackTrace ? { stackTrace } : {}),
  });

  if (group.entries.length >= maxBufferCount) {
    triggerFlush(group);
  } else if (!group.timer) {
    group.timer = setTimeout(() => {
      triggerFlush(group);
    }, flushIntervalMs);
  }
}

export async function flushLogs(): Promise<void> {
  // 残っているすべてのバッファを強制的にフラッシュ
  for (const group of bufferGroups.values()) {
    triggerFlush(group);
  }

  // 実行中のすべての書き込みが完了するのを待つ
  while (activeWritePromises.length > 0) {
    await Promise.all(activeWritePromises);
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
