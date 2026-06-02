"use client";

import { useEffect, useState, useRef } from "react";
import { Loader2 } from "lucide-react";

function JobChip({
  label,
  status,
  duration,
}: {
  label: string;
  status: "queued" | "inProgress" | "success" | "skipped";
  duration?: string;
}) {
  const styles = {
    queued: {
      bg: "bg-[#F4F7FF]",
      border: "border-[#D8E2FF]",
      text: "text-[#4E5BA6]",
      icon: (
        <svg
          className="w-3 h-3 shrink-0"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          strokeWidth={2.5}
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
          />
        </svg>
      ),
    },
    inProgress: {
      bg: "bg-[#EAF2FF]",
      border: "border-[#C7DBFF]",
      text: "text-[#2563EB]",
      icon: <Loader2 className="w-3 h-3 animate-spin text-current shrink-0" />,
    },
    success: {
      bg: "bg-[#EAF7EF]",
      border: "border-[#CBEAD8]",
      text: "text-[#16865A]",
      icon: (
        <svg
          className="w-3 h-3 shrink-0"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          strokeWidth={3}
        >
          <path strokeLinecap="round" strokeLinejoin="round" d="m4.5 12.75 6 6 9-13.5" />
        </svg>
      ),
    },
    skipped: {
      bg: "bg-[#F2F4F7]",
      border: "border-[#D0D5DD]",
      text: "text-[#667085]",
      icon: (
        <svg
          className="w-3 h-3 shrink-0"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          strokeWidth={2.5}
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="m11.25 4.5 7.5 7.5-7.5 7.5M4.5 4.5l7.5 7.5-7.5 7.5"
          />
        </svg>
      ),
    },
  }[status];

  return (
    <div
      className={`inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-[11px] font-semibold ${styles.bg} ${styles.border} ${styles.text} transition-all duration-200 shrink-0 h-7`}
    >
      <span className="flex items-center justify-center w-3 h-3 shrink-0">{styles.icon}</span>
      <span className="leading-none">{label}</span>
      {duration && (
        <span className="ml-1 opacity-70 tabular-nums font-mono text-[9px] leading-none">
          {duration}
        </span>
      )}
    </div>
  );
}

export function BuildJobCardDemo({ lang = "ja" }: { lang?: "en" | "ja" }) {
  const [ms, setMs] = useState(0);
  const [isFinished, setIsFinished] = useState(false);
  const [isCanceled, setIsCanceled] = useState(false);
  const intervalRef = useRef<NodeJS.Timeout | null>(null);

  const startSimulation = () => {
    setMs(0);
    setIsFinished(false);
    setIsCanceled(false);
  };

  const cancelSimulation = () => {
    setIsFinished(true);
    setIsCanceled(true);
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
    }
  };

  useEffect(() => {
    if (!isFinished) {
      intervalRef.current = setInterval(() => {
        setMs((prev) => {
          const next = prev + 100;
          if (next >= 9500) {
            setIsFinished(true);
            if (intervalRef.current) clearInterval(intervalRef.current);
            return 9500;
          }
          return next;
        });
      }, 100);
    }
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [isFinished]);

  const formatDuration = (milliseconds: number) => {
    const totalSeconds = Math.floor(milliseconds / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes}:${seconds.toString().padStart(2, "0")}`;
  };

  const getJobStatus = (id: string): "queued" | "inProgress" | "success" | "skipped" => {
    let normalStatus: "queued" | "inProgress" | "success" | "skipped" = "queued";
    if (id === "setup") {
      if (ms < 1500) normalStatus = "inProgress";
      else normalStatus = "success";
    } else if (id === "test") {
      if (ms < 1500) normalStatus = "queued";
      else if (ms < 3500) normalStatus = "inProgress";
      else normalStatus = "success";
    } else if (id === "build-android") {
      if (ms < 3500) normalStatus = "queued";
      else if (ms < 6000) normalStatus = "inProgress";
      else normalStatus = "success";
    } else if (id === "build-ios") {
      if (ms < 3500) normalStatus = "queued";
      else if (ms < 7500) normalStatus = "inProgress";
      else normalStatus = "success";
    } else if (id === "deploy-android") {
      if (ms < 6000) normalStatus = "queued";
      else if (ms < 8500) normalStatus = "inProgress";
      else normalStatus = "success";
    } else if (id === "deploy-ios") {
      if (ms < 7500) normalStatus = "queued";
      else if (ms < 9500) normalStatus = "inProgress";
      else normalStatus = "success";
    }

    if (isCanceled && normalStatus !== "success") {
      return "skipped";
    }
    return normalStatus;
  };

  const getJobDuration = (id: string): string | undefined => {
    const status = getJobStatus(id);
    if (status === "queued" || status === "skipped") return undefined;
    if (status === "inProgress") {
      if (id === "setup") return formatDuration(ms);
      if (id === "test") return formatDuration(ms - 1500);
      if (id === "build-android") return formatDuration(ms - 3500);
      if (id === "build-ios") return formatDuration(ms - 3500);
      if (id === "deploy-android") return formatDuration(ms - 6000);
      if (id === "deploy-ios") return formatDuration(ms - 7500);
    }
    if (id === "setup") return "0:01";
    if (id === "test") return "0:02";
    if (id === "build-android") return "0:02";
    if (id === "build-ios") return "0:04";
    if (id === "deploy-android") return "0:02";
    if (id === "deploy-ios") return "0:02";
    return undefined;
  };

  const isOverallInProgress = !isFinished;

  return (
    <div className="w-full bg-white rounded-2xl border border-neutral-950/8 p-6 text-left shadow-sm">
      {/* Card Header */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between border-b border-neutral-950/6 pb-4">
        <div>
          <div className="flex items-center gap-2">
            <h3 className="text-base font-bold text-neutral-950">release.yml</h3>
            {/* Overall Status Pill */}
            {isCanceled ? (
              <div className="inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-semibold bg-[#FFF0F0] border border-[#FFD0D0] text-[#D93838]">
                <svg
                  className="w-3 h-3 shrink-0"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth={3}
                >
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6 18 18 6M6 6l12 12" />
                </svg>
                <span>{lang === "ja" ? "キャンセル" : "Canceled"}</span>
              </div>
            ) : isOverallInProgress ? (
              <div className="inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-semibold bg-[#EAF2FF] border border-[#C7DBFF] text-[#2563EB]">
                <Loader2 className="w-3 h-3 animate-spin text-current shrink-0" />
                <span>{lang === "ja" ? "実行中" : "Running"}</span>
              </div>
            ) : (
              <div className="inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-semibold bg-[#EAF7EF] border border-[#CBEAD8] text-[#16865A]">
                <svg
                  className="w-3.5 h-3.5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth={3}
                >
                  <path strokeLinecap="round" strokeLinejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                </svg>
                <span>{lang === "ja" ? "成功" : "Success"}</span>
              </div>
            )}
          </div>
          <div className="mt-1.5 flex flex-wrap gap-x-4 gap-y-1 text-xs text-neutral-500 font-medium">
            <span className="flex items-center gap-1.5">
              <svg
                className="w-3.5 h-3.5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth={2}
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M7.217 10.907a2.25 2.25 0 1 0 0 2.186m0-2.186c.18.324.283.696.283 1.093s-.103.77-.283 1.093m0-2.186 9.566-5.314m-9.566 7.5 9.566 5.314m0 0a2.25 2.25 0 1 0 3.935 2.186 2.25 2.25 0 0 0-3.935-2.186Zm0-12.814a2.25 2.25 0 1 0 3.933-2.185 2.25 2.25 0 0 0-3.933 2.185Z"
                />
              </svg>
              push · main · 8f9a2d4
            </span>
            <span className="flex items-center gap-1.5">
              <svg
                className="w-3.5 h-3.5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth={2}
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
                />
              </svg>
              1 min ago
            </span>
          </div>
        </div>

        <div className="flex items-center gap-3 sm:text-right">
          <div className="text-sm font-semibold text-neutral-900 tabular-nums">
            {formatDuration(ms)}
          </div>
        </div>
      </div>

      {/* Card Body - Matrix jobs */}
      <div className="mt-5">
        <div className="text-[10px] font-bold text-neutral-400 uppercase tracking-wider mb-4 select-none">
          Jobs
        </div>

        {/* Dependency Flow - Responsive pipeline (vertical on mobile/tablet, horizontal on desktop) */}
        <div className="flex flex-col lg:flex-row items-center gap-4 lg:gap-3 pt-2 lg:pt-1 justify-center lg:justify-start">
          <JobChip
            label="setup"
            status={getJobStatus("setup")}
            duration={getJobDuration("setup")}
          />

          <svg
            className="w-3.5 h-3.5 text-neutral-300 shrink-0 rotate-90 lg:rotate-0 self-center"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2.5}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"
            />
          </svg>

          <JobChip label="test" status={getJobStatus("test")} duration={getJobDuration("test")} />

          <svg
            className="w-3.5 h-3.5 text-neutral-300 shrink-0 rotate-90 lg:rotate-0 self-center"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2.5}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"
            />
          </svg>

          {/* Matrix build group */}
          <div className="relative border border-neutral-950/6 bg-neutral-50/50 px-3 py-3.5 rounded-xl flex gap-2 items-center shrink-0">
            <div className="absolute -top-2 left-3 bg-[#fdfdfd] px-1.5 text-[9px] font-bold text-neutral-400 uppercase select-none leading-none">
              build
            </div>
            <div className="flex flex-col sm:flex-row lg:flex-col gap-2 justify-center">
              <JobChip
                label="build-android"
                status={getJobStatus("build-android")}
                duration={getJobDuration("build-android")}
              />
              <JobChip
                label="build-ios"
                status={getJobStatus("build-ios")}
                duration={getJobDuration("build-ios")}
              />
            </div>
          </div>

          <svg
            className="w-3.5 h-3.5 text-neutral-300 shrink-0 rotate-90 lg:rotate-0 self-center"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2.5}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"
            />
          </svg>

          {/* Matrix deploy group */}
          <div className="relative border border-neutral-950/6 bg-neutral-50/50 px-3 py-3.5 rounded-xl flex gap-2 items-center shrink-0">
            <div className="absolute -top-2 left-3 bg-[#fdfdfd] px-1.5 text-[9px] font-bold text-neutral-400 uppercase select-none leading-none">
              deploy
            </div>
            <div className="flex flex-col sm:flex-row lg:flex-col gap-2 justify-center">
              <JobChip
                label="deploy-android"
                status={getJobStatus("deploy-android")}
                duration={getJobDuration("deploy-android")}
              />
              <JobChip
                label="deploy-ios"
                status={getJobStatus("deploy-ios")}
                duration={getJobDuration("deploy-ios")}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Button Footer */}
      <div className="mt-6 pt-4 border-t border-neutral-950/6 flex justify-end">
        {isFinished ? (
          <button
            onClick={startSimulation}
            className="inline-flex items-center gap-1.5 rounded-lg bg-neutral-950 hover:bg-neutral-800 text-white px-3.5 py-2 text-xs font-semibold tracking-wide transition-all active:scale-95 cursor-pointer"
          >
            <svg
              className="w-3.5 h-3.5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2.5}
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99"
              />
            </svg>
            {lang === "ja" ? "再実行" : "Re-run workflow"}
          </button>
        ) : (
          <button
            onClick={cancelSimulation}
            className="inline-flex items-center gap-1.5 rounded-lg bg-white hover:bg-red-50/50 text-red-600 border border-red-200 px-3.5 py-2 text-xs font-semibold tracking-wide transition-all active:scale-95 cursor-pointer"
          >
            <svg
              className="w-3.5 h-3.5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2.5}
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18 18 6M6 6l12 12" />
            </svg>
            {lang === "ja" ? "キャンセル" : "Cancel workflow"}
          </button>
        )}
      </div>
    </div>
  );
}
