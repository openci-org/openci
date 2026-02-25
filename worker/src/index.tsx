import { config } from "dotenv";
import { Box, render, Text } from "ink";
import Spinner from "ink-spinner";
import meow from "meow";
import os from "node:os";
import { useEffect, useState } from "react";
import { cleanupOrphanedVms, executeBuild } from "./executor.js";
import { SupabaseWorkerClient } from "./supabase.js";
import type { Build } from "./types.js";

function getMachineInfo() {
  const cpus = os.cpus();
  const totalMemoryGB = (os.totalmem() / 1024 / 1024 / 1024).toFixed(1);
  const freeMemoryGB = (os.freemem() / 1024 / 1024 / 1024).toFixed(1);
  return {
    hostname: os.hostname(),
    platform: os.platform(),
    arch: os.arch(),
    cpuModel: cpus[0]?.model?.trim() ?? "unknown",
    cpuCores: cpus.length,
    totalMemoryGB,
    freeMemoryGB,
  };
}

const machineInfo = getMachineInfo();

const envArg = process.argv.includes("--prod") ? ".env.production.local" : ".env.local";
config({ path: envArg });

const VERSION = "0.2.0";
const POLLING_INTERVAL_MS = 10_000;

const cli = meow(
  `
  Usage
    $ openci-worker [options]

  Options
    --supabase-url   Supabase project URL       (or SUPABASE_URL env)
    --supabase-key   Supabase service role key   (or SUPABASE_KEY env)
    --worker-id      Unique worker identifier    (or WORKER_ID env)
    --version        Show version
`,
  {
    importMeta: import.meta,
    flags: {
      supabaseUrl: { type: "string" },
      supabaseKey: { type: "string" },
      workerId: { type: "string" },
    },
  },
);

const supabaseUrl = cli.flags.supabaseUrl || process.env.SUPABASE_URL;
const supabaseKey = cli.flags.supabaseKey || process.env.SUPABASE_KEY;
const workerId = cli.flags.workerId || process.env.WORKER_ID;

if (!supabaseUrl || !supabaseKey || !workerId) {
  cli.showHelp();
  process.exit(1);
}

const supabase = new SupabaseWorkerClient(supabaseUrl, supabaseKey);

type WorkerStatus = "init" | "polling" | "claiming" | "running" | "done";

function App() {
  const [status, setStatus] = useState<WorkerStatus>("init");
  const [currentBuild, setCurrentBuild] = useState<Build | null>(null);
  const [queuedCount, setQueuedCount] = useState(0);
  const [pollCount, setPollCount] = useState(0);
  const [lastPollAt, setLastPollAt] = useState<string>("-");
  const [buildLogs, setBuildLogs] = useState<string[]>([]);
  const [lastResult, setLastResult] = useState<string | null>(null);
  const [completedCount, setCompletedCount] = useState(0);

  useEffect(() => {
    let active = true;

    const addLog = (msg: string) => {
      setBuildLogs((prev) => [...prev.slice(-20), msg]);
    };

    const loop = async () => {
      setStatus("init");
      addLog("Cleaning up orphaned VMs...");
      const cleaned = await cleanupOrphanedVms(workerId as string);
      if (cleaned.length > 0) {
        addLog(`Cleaned ${cleaned.length} orphaned VM(s)`);
      }

      while (active) {
        setStatus("polling");
        setCurrentBuild(null);
        setBuildLogs([]);
        const now = new Date().toLocaleTimeString();
        setLastPollAt(now);
        setPollCount((c) => c + 1);

        const queued = await supabase.fetchQueuedBuilds();
        setQueuedCount(queued.length);

        if (queued.length > 0) {
          setStatus("claiming");
          const build = await supabase.claimNextBuild(workerId as string);

          if (build) {
            setCurrentBuild(build);
            setStatus("running");
            addLog(`Build claimed: ${build.github_owner}/${build.github_repo}`);

            const result = await executeBuild({
              vmName: "",
              build,
              workerId: workerId as string,
              supabase,
              onLog: addLog,
            });

            setLastResult(result);
            setCompletedCount((c) => c + 1);
            setStatus("done");
            addLog(`Build finished: ${result}`);

            await new Promise((r) => setTimeout(r, 3000));
            continue;
          }
        }

        await new Promise((r) => setTimeout(r, POLLING_INTERVAL_MS));
      }
    };

    loop();
    return () => {
      active = false;
    };
  }, []);

  return (
    <Box flexDirection="column" padding={1}>
      <Box flexDirection="column" marginBottom={1}>
        <Text bold color="cyan">
          ◆ OpenCI Worker <Text dimColor>v{VERSION}</Text>
        </Text>
        <Text>
          Worker: <Text bold>{workerId}</Text>
        </Text>
        <Text>
          Host: <Text bold>{machineInfo.hostname}</Text>
          <Text dimColor>
            {" "}
            ({machineInfo.platform}/{machineInfo.arch})
          </Text>
        </Text>
        <Text dimColor>
          CPU: {machineInfo.cpuModel} ({machineInfo.cpuCores} cores) · RAM:{" "}
          {machineInfo.freeMemoryGB}/{machineInfo.totalMemoryGB} GB
        </Text>
        <Text dimColor>
          Polls: {pollCount} · Last: {lastPollAt} · Queued: {queuedCount} · Completed:{" "}
          {completedCount}
        </Text>
      </Box>

      <Box flexDirection="column" marginBottom={1}>
        <StatusLine status={status} lastResult={lastResult} />
      </Box>

      {currentBuild && (
        <Box
          flexDirection="column"
          borderStyle="round"
          borderColor="green"
          paddingX={1}
          marginBottom={1}
        >
          <Text bold color="green">
            Current Build
          </Text>
          <Text>
            ID: <Text bold>{currentBuild.id.slice(0, 8)}</Text>
          </Text>
          <Text>
            Repo:{" "}
            <Text bold>
              {currentBuild.github_owner}/{currentBuild.github_repo}
            </Text>
          </Text>
          {currentBuild.branch && (
            <Text>
              Branch: <Text bold>{currentBuild.branch}</Text>
            </Text>
          )}
          {currentBuild.commit_sha && (
            <Text>
              Commit: <Text bold>{currentBuild.commit_sha.slice(0, 7)}</Text>
            </Text>
          )}
        </Box>
      )}

      {buildLogs.length > 0 && (
        <Box flexDirection="column" borderStyle="round" borderColor="gray" paddingX={1}>
          <Text bold dimColor>
            Logs
          </Text>
          {buildLogs.map((log, i) => (
            <Text key={i} dimColor>
              {log}
            </Text>
          ))}
        </Box>
      )}
    </Box>
  );
}

function StatusLine({ status, lastResult }: { status: WorkerStatus; lastResult: string | null }) {
  switch (status) {
    case "init":
      return (
        <Text>
          <Text color="cyan">
            <Spinner type="dots" />
          </Text>{" "}
          Initializing...
        </Text>
      );
    case "polling":
      return (
        <Text>
          <Text color="yellow">
            <Spinner type="dots" />
          </Text>{" "}
          Polling for jobs...
        </Text>
      );
    case "claiming":
      return (
        <Text>
          <Text color="cyan">
            <Spinner type="dots" />
          </Text>{" "}
          Claiming build...
        </Text>
      );
    case "running":
      return (
        <Text>
          <Text color="magenta">
            <Spinner type="dots" />
          </Text>{" "}
          Running build...
        </Text>
      );
    case "done":
      if (lastResult === "success") {
        return <Text color="green">✓ Build succeeded — polling next...</Text>;
      }
      return <Text color="red">✗ Build failed — polling next...</Text>;
  }
}

render(<App />, { patchConsole: false });
