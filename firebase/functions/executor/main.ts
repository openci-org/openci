import { executeBuild } from "./execute.js";
import { runtime } from "./runtime.js";
import { validJobId } from "../build_dispatch.js";

async function main(): Promise<void> {
  const dispatchId = process.env.BUILD_DISPATCH_ID;
  const jobId = process.env.BUILD_JOB_ID;
  const execution = process.env.CLOUD_RUN_EXECUTION;
  if (
    !validJobId(jobId) ||
    !dispatchId ||
    !/^[a-f0-9-]{36}$/.test(dispatchId) ||
    !execution ||
    !/^[a-z][a-z0-9-]*$/.test(execution)
  )
    throw new Error("Invalid executor input");
  const dependencies = runtime(process.env, (reason, id) =>
    process.stdout.write(
      JSON.stringify({ severity: "WARNING", message: reason, dispatchId: id }) + "\n",
    ),
  );
  if (
    process.env.CLOUD_RUN_JOB !== dependencies.configuration.cloudRunJob.split("/").at(-1) ||
    !execution.startsWith(`${process.env.CLOUD_RUN_JOB}-`)
  )
    throw new Error("Cloud Run job identity mismatch");
  const shutdown = new AbortController();
  const stop = () => shutdown.abort();
  process.once("SIGTERM", stop);
  process.once("SIGINT", stop);
  try {
    await executeBuild(
      {
        dispatchId,
        jobId,
        executionName: `${dependencies.configuration.cloudRunJob}/executions/${execution}`,
      },
      dependencies,
      shutdown.signal,
    );
  } finally {
    process.removeListener("SIGTERM", stop);
    process.removeListener("SIGINT", stop);
  }
}

void main().catch(() => {
  // Never serialize SDK errors, request variables, tokens, scripts, or logs.
  process.stderr.write(
    '{"severity":"ERROR","message":"Build executor failed; recovery required"}\n',
  );
  process.exitCode = 1;
});
