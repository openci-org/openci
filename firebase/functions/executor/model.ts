import { validSecretName } from "../secrets/validation.js";
import type { GetBuildExecutionData, GetBuildExecutorContextData } from "@openci/dispatch-admin";

export type Dispatch = NonNullable<GetBuildExecutionData["dispatch"]>;
export type Job = NonNullable<GetBuildExecutionData["job"]>;
export type Context = GetBuildExecutorContextData;
export type Outcome = "success" | "failure" | "cancelled" | "timed_out" | "blocked";
export type Stream = "stdout" | "stderr";

export class ExecutionStopped extends Error {
  constructor(readonly outcome: Outcome) {
    super("Build execution stopped");
  }
}

export function identity(dispatch: Dispatch) {
  if (!dispatch.teamId || dispatch.runId !== `run-${dispatch.id}`) {
    throw new Error("Invalid execution identity");
  }
  return {
    teamId: dispatch.teamId,
    jobId: dispatch.jobId,
    runId: dispatch.runId,
    workerHost: `cloud-run-${dispatch.id}`,
    admissionId: `admission-${dispatch.id}`,
  };
}

export function validateJob(job: Job, dispatch: Dispatch): void {
  if (
    job.id !== dispatch.jobId ||
    !job.teamId ||
    job.teamId !== dispatch.teamId ||
    !/^[A-Za-z0-9_.-]+$/.test(job.owner ?? "") ||
    !/^[A-Za-z0-9_.-]+$/.test(job.repo ?? "") ||
    !/^[a-fA-F0-9]{40}(?:[a-fA-F0-9]{24})?$/.test(job.commitSha ?? "") ||
    !/^(?:[A-Za-z0-9_-]+\/)*[A-Za-z0-9_.-]+\.dart$/.test(job.workflowFileName ?? "") ||
    !job.installationId ||
    !job.workflowName
  ) {
    throw new Error("Invalid persisted build job");
  }
}

export function shellQuote(value: string): string {
  if (value.includes("\0")) throw new Error("Invalid command value");
  return `'${value.replaceAll("'", "'\\''")}'`;
}

export function checkoutScript(job: Job, cloneUrl: string, token: string): string {
  const auth = Buffer.from(`x-access-token:${token}`).toString("base64");
  return (
    [
      "set -euo pipefail",
      "export HOME=/Users/admin GIT_TERMINAL_PROMPT=0",
      "mkdir -p /Users/admin/openci-build",
      "cd /Users/admin/openci-build",
      "git init -q",
      `git remote add origin ${shellQuote(cloneUrl)}`,
      // The token goes over stdin, never in an Orchard URL or a git remote/config.
      `git -c ${shellQuote(`http.extraHeader=Authorization: Basic ${auth}`)} fetch --no-tags --depth=1 origin ${shellQuote(job.commitSha!)}`,
      `git checkout --detach ${shellQuote(job.commitSha!)}`,
    ].join("\n") + "\n"
  );
}

export function workflowScript(
  job: Job,
  dispatch: Dispatch,
  runNumber: number,
  secrets: Record<string, string>,
): string {
  const variables = {
    ...secrets,
    OPENCI_BUILD_JOB_ID: job.id,
    OPENCI_RUN_ID: identity(dispatch).runId,
    OPENCI_RUN_NUMBER: String(runNumber),
  };
  for (const name of Object.keys(secrets)) {
    if (!validSecretName(name)) {
      throw new Error("Reserved or invalid secret name");
    }
  }
  return (
    [
      "set -euo pipefail",
      "export HOME=/Users/admin",
      'export FLUTTER_ROOT="$HOME/fvm/default"',
      'export PATH="$FLUTTER_ROOT/bin:$HOME/.pub-cache/bin:/opt/homebrew/bin:$PATH"',
      "unset LOKI_URL LOKI_USERNAME LOKI_PASSWORD",
      "cd /Users/admin/openci-build",
      ...Object.entries(variables).map(([key, value]) => `export ${key}=${shellQuote(value)}`),
      "flutter pub get",
      `flutter pub run ${shellQuote(`openci/${job.workflowFileName}`)}`,
    ].join("\n") + "\n"
  );
}
