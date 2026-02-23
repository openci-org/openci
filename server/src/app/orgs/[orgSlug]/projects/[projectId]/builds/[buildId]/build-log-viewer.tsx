"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import type { BuildLog, BuildStatus } from "@/lib/supabase/types";
import { Download, ChevronDown, ChevronRight, CheckCircle2, XCircle, Clock } from "lucide-react";

interface BuildLogViewerProps {
  buildId: string;
  buildRunId: string | null;
  initialStatus: BuildStatus;
  initialLogs: BuildLog[];
  logArchivePath: string | null;
}

const LOG_LEVEL_COLORS = {
  info: "text-foreground",
  warning: "text-yellow-500",
  error: "text-red-500",
} as const;

interface StepGroup {
  index: number;
  name: string;
  logs: BuildLog[];
}

function groupLogsByStep(logs: BuildLog[]): { steps: StepGroup[]; preamble: BuildLog[] } {
  const preamble: BuildLog[] = [];
  const stepMap = new Map<number, StepGroup>();

  for (const log of logs) {
    if (log.step_index === null || log.step_index === undefined) {
      preamble.push(log);
    } else {
      if (!stepMap.has(log.step_index)) {
        stepMap.set(log.step_index, {
          index: log.step_index,
          name: log.step_name ?? `Step ${log.step_index + 1}`,
          logs: [],
        });
      }
      stepMap.get(log.step_index)?.logs.push(log);
    }
  }

  const steps = Array.from(stepMap.values()).toSorted((a, b) => a.index - b.index);
  return { steps, preamble };
}

function stepHasError(step: StepGroup): boolean {
  return step.logs.some((l) => l.level === "error");
}

function stepIsComplete(step: StepGroup): boolean {
  return step.logs.some((l) => l.message.startsWith("✓ Step completed:"));
}

function StepHeader({
  step,
  isRunning,
  isOpen,
  onToggle,
}: {
  step: StepGroup;
  isRunning: boolean;
  isOpen: boolean;
  onToggle: () => void;
}) {
  const hasError = stepHasError(step);
  const isDone = stepIsComplete(step);
  const isCurrent = isRunning && !isDone && !hasError;

  return (
    <button
      onClick={onToggle}
      className="flex items-center gap-2 w-full text-left py-1.5 px-2 rounded hover:bg-muted/30 transition-colors"
    >
      {isOpen ? (
        <ChevronDown className="size-3.5 shrink-0 text-muted-foreground" />
      ) : (
        <ChevronRight className="size-3.5 shrink-0 text-muted-foreground" />
      )}
      {hasError && <XCircle className="size-3.5 shrink-0 text-red-500" />}
      {!hasError && isDone && <CheckCircle2 className="size-3.5 shrink-0 text-green-500" />}
      {!hasError && !isDone && (
        <Clock className={`size-3.5 shrink-0 ${isCurrent ? "text-yellow-500 animate-pulse" : "text-muted-foreground"}`} />
      )}
      <span className="text-sm font-medium">
        Step {step.index + 1}: {step.name}
      </span>
      <span className="ml-auto text-xs text-muted-foreground">{step.logs.length} lines</span>
    </button>
  );
}

function LogLine({ log }: { log: BuildLog }) {
  return (
    <div className={`leading-5 ${LOG_LEVEL_COLORS[log.level]}`}>
      <span className="text-gray-600 mr-2">
        {new Date(log.created_at).toISOString().slice(11, 23)}
      </span>
      {log.level !== "info" && (
        <span className="uppercase mr-2 font-bold">[{log.level}]</span>
      )}
      <span className="whitespace-pre-wrap">{log.message}</span>
      {log.stack_trace && (
        <pre className="text-red-400 mt-1 pl-4 whitespace-pre-wrap">{log.stack_trace}</pre>
      )}
    </div>
  );
}

export function BuildLogViewer({
  buildId,
  buildRunId,
  initialStatus,
  initialLogs,
  logArchivePath: initialLogArchivePath,
}: BuildLogViewerProps) {
  const [logs, setLogs] = useState<BuildLog[]>(initialLogs);
  const [status, setStatus] = useState<BuildStatus>(initialStatus);
  const [archivePath, setArchivePath] = useState<string | null>(initialLogArchivePath);
  const [cancelling, setCancelling] = useState(false);
  const [downloading, setDownloading] = useState(false);
  const [openSteps, setOpenSteps] = useState<Set<number>>(new Set());
  const bottomRef = useRef<HTMLDivElement>(null);
  // useMemo to keep the same client instance across renders (prevents re-subscribing)
  const supabase = useMemo(() => createClient(), []);

  const isRunning = status === "in_progress" || status === "queued";
  const { steps, preamble } = groupLogsByStep(logs);

  // Auto-open the current/latest step
  useEffect(() => {
    if (steps.length > 0) {
      const lastStep = steps[steps.length - 1];
      setOpenSteps((prev) => new Set([...prev, lastStep.index]));
    }
  }, [steps.length]); // eslint-disable-line react-hooks/exhaustive-deps

  // Auto-scroll to bottom when new logs arrive
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [logs]);

  // Realtime: subscribe to new log entries
  useEffect(() => {
    if (!buildRunId) return;

    const channel = supabase
      .channel(`build-logs-${buildRunId}`)
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "build_logs",
          filter: `build_run_id=eq.${buildRunId}`,
        },
        (payload) => {
          setLogs((prev) => [...prev, payload.new as BuildLog]);
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [buildRunId, supabase]);

  // Realtime: subscribe to build status changes
  useEffect(() => {
    const channel = supabase
      .channel(`build-status-${buildId}`)
      .on(
        "postgres_changes",
        {
          event: "UPDATE",
          schema: "public",
          table: "builds",
          filter: `id=eq.${buildId}`,
        },
        (payload) => {
          setStatus(payload.new.status as BuildStatus);
          if (payload.new.log_archive_path) {
            setArchivePath(payload.new.log_archive_path as string);
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [buildId, supabase]);

  const handleCancel = async () => {
    setCancelling(true);
    await fetch(`/api/builds/${buildId}/cancel`, { method: "POST" });
    setCancelling(false);
  };

  const handleDownload = async () => {
    if (!archivePath) return;
    setDownloading(true);
    try {
      const { data, error } = await supabase.storage
        .from("build-logs")
        .createSignedUrl(archivePath, 300);
      if (!error && data?.signedUrl) {
        const a = document.createElement("a");
        a.href = data.signedUrl;
        a.download = `build-${buildId}.txt`;
        a.click();
      }
    } finally {
      setDownloading(false);
    }
  };

  const toggleStep = (index: number) => {
    setOpenSteps((prev) => {
      const next = new Set(prev);
      if (next.has(index)) {
        next.delete(index);
      } else {
        next.add(index);
      }
      return next;
    });
  };

  const hasSteps = steps.length > 0;

  return (
    <div className="flex flex-col gap-3">
      {/* Status bar */}
      <div className="flex items-center justify-between">
        <span className="text-sm text-muted-foreground">
          {logs.length} log line{logs.length !== 1 ? "s" : ""}
          {isRunning && " · streaming..."}
        </span>
        <div className="flex items-center gap-2">
          {archivePath && (
            <button
              onClick={handleDownload}
              disabled={downloading}
              className="flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground disabled:opacity-50 transition-colors"
            >
              <Download className="size-3.5" />
              {downloading ? "Downloading..." : "Download"}
            </button>
          )}
          {isRunning && (
            <button
              onClick={handleCancel}
              disabled={cancelling}
              className="text-xs text-red-600 hover:text-red-700 disabled:opacity-50"
            >
              {cancelling ? "Cancelling..." : "Cancel Build"}
            </button>
          )}
        </div>
      </div>

      {/* Step-grouped view (when step info is available) */}
      {hasSteps ? (
        <div className="flex flex-col gap-1">
          {/* Preamble logs (before any step) */}
          {preamble.length > 0 && (
            <div className="bg-black text-green-400 font-mono text-xs rounded-lg p-4">
              {preamble.map((log) => (
                <LogLine key={log.id} log={log} />
              ))}
            </div>
          )}

          {/* Step accordions */}
          {steps.map((step) => (
            <div key={step.index} className="border rounded-lg overflow-hidden">
              <div className="bg-muted/20 px-2 py-0.5">
                <StepHeader
                  step={step}
                  isRunning={isRunning}
                  isOpen={openSteps.has(step.index)}
                  onToggle={() => toggleStep(step.index)}
                />
              </div>
              {openSteps.has(step.index) && (
                <div className="bg-black text-green-400 font-mono text-xs p-4 overflow-x-auto max-h-[400px] overflow-y-auto">
                  {step.logs.map((log) => (
                    <LogLine key={log.id} log={log} />
                  ))}
                </div>
              )}
            </div>
          ))}
          <div ref={bottomRef} />
        </div>
      ) : (
        /* Flat terminal view (no step info — legacy builds or pre-step preamble only) */
        <div className="bg-black text-green-400 font-mono text-xs rounded-lg p-4 overflow-y-auto max-h-[600px] min-h-[200px]">
          {logs.length === 0 && isRunning && (
            <span className="text-gray-500 animate-pulse">Waiting for logs...</span>
          )}
          {logs.length === 0 && !isRunning && (
            <span className="text-gray-500">No logs recorded.</span>
          )}
          {logs.map((log) => (
            <LogLine key={log.id} log={log} />
          ))}
          <div ref={bottomRef} />
        </div>
      )}
    </div>
  );
}
