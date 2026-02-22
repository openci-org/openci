"use client";

import { useEffect, useRef, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import type { BuildLog, BuildStatus } from "@/lib/supabase/types";

interface BuildLogViewerProps {
  buildId: string;
  buildRunId: string | null;
  initialStatus: BuildStatus;
  initialLogs: BuildLog[];
}

const LOG_LEVEL_COLORS = {
  info: "text-foreground",
  warning: "text-yellow-500",
  error: "text-red-500",
} as const;

export function BuildLogViewer({
  buildId,
  buildRunId,
  initialStatus,
  initialLogs,
}: BuildLogViewerProps) {
  const [logs, setLogs] = useState<BuildLog[]>(initialLogs);
  const [status, setStatus] = useState<BuildStatus>(initialStatus);
  const [cancelling, setCancelling] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);
  const supabase = createClient();

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
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [buildId, supabase]);

  const isRunning = status === "in_progress" || status === "queued";

  const handleCancel = async () => {
    setCancelling(true);
    await fetch(`/api/builds/${buildId}/cancel`, { method: "POST" });
    setCancelling(false);
  };

  return (
    <div className="flex flex-col gap-3">
      {/* Status bar */}
      <div className="flex items-center justify-between">
        <span className="text-sm text-muted-foreground">
          {logs.length} log line{logs.length !== 1 ? "s" : ""}
          {isRunning && " · streaming..."}
        </span>
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

      {/* Log terminal */}
      <div className="bg-black text-green-400 font-mono text-xs rounded-lg p-4 overflow-y-auto max-h-[600px] min-h-[200px]">
        {logs.length === 0 && isRunning && (
          <span className="text-gray-500 animate-pulse">Waiting for logs...</span>
        )}
        {logs.length === 0 && !isRunning && (
          <span className="text-gray-500">No logs recorded.</span>
        )}
        {logs.map((log) => (
          <div key={log.id} className={`leading-5 ${LOG_LEVEL_COLORS[log.level]}`}>
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
        ))}
        <div ref={bottomRef} />
      </div>
    </div>
  );
}
