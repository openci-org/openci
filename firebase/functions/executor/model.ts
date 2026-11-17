import { validSecretName } from "../secrets/validation.js";
import type { MergeReadinessDiagnostics } from "./checkout_error.js";
import type { GetBuildExecutionData, GetBuildExecutorContextData } from "@openci/dispatch-admin";

export type Dispatch = NonNullable<GetBuildExecutionData["dispatch"]>;
export type Job = NonNullable<GetBuildExecutionData["job"]>;
export type Context = GetBuildExecutorContextData;
export type Outcome =
  | "success"
  | "failure"
  | "cancelled"
  | "timed_out"
  | "blocked"
  | "card_required";
export type Stream = "stdout" | "stderr";

/** Explicit retries also need a fresh Check when no BuildRun was started. */
export function queuedCheckExternalId(job: Pick<Job, "id" | "runCount" | "retryCount">): string {
  const base = `build-job:${job.id}:run:${BigInt(job.runCount ?? "0") + 1n}`;
  return job.retryCount ? `${base}:retry:${job.retryCount}` : base;
}

/** Verified event metadata and the commit actually checked out. */
export type ResolvedCheckout =
  | { event: "push"; branch: string; commitSha: string; checkoutSha: string }
  | {
      event: "pull_request";
      number: number;
      headBranch: string;
      baseBranch: string;
      headSha: string;
      baseSha: string;
      checkoutSha: string;
    };

/** Selected only after polling and a fresh source/ancestry verification. */
export type CheckoutPlan =
  | ResolvedCheckout
  | (Omit<Extract<ResolvedCheckout, { event: "pull_request" }>, "checkoutSha"> & {
      checkoutSha: null;
      fallback: MergeReadinessDiagnostics & { mergeBaseSha: string };
    });

export const localMergeConflictExitCode = 79;

// Each attempt runs in its own disposable VM.
export const prQrOutputDirectory = "/tmp/openci-pr-qr";
export const prQrOutputReady = 78;

const flutterRelease = /^\d+\.\d+\.\d+(?:-[0-9A-Za-z]+(?:[.-][0-9A-Za-z]+)*)?$/;

function validateFlutterVersion(version: string | null | undefined): void {
  if (version != null && (!flutterRelease.test(version) || version.trim() !== version)) {
    throw new Error("Invalid Flutter release");
  }
}

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
  validateFlutterVersion(job.flutterVersion);
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

export function checkoutScript(
  commitSha: string,
  cloneUrl: string,
  token: string,
  baseSha?: string,
): string {
  if (
    !/^[a-fA-F0-9]{40}(?:[a-fA-F0-9]{24})?$/.test(commitSha) ||
    (baseSha !== undefined && !/^[a-f0-9]{40}(?:[a-f0-9]{24})?$/.test(baseSha))
  )
    throw new Error("Invalid checkout commit SHA");
  const auth = Buffer.from(`x-access-token:${token}`).toString("base64");
  // A local merge needs the complete ancestry to find all merge bases.
  const fetchArgs = baseSha
    ? `origin ${shellQuote(baseSha)} ${shellQuote(commitSha)}`
    : `--depth=1 origin ${shellQuote(commitSha)}`;
  return (
    [
      "set -euo pipefail",
      "export HOME=/Users/admin GIT_TERMINAL_PROMPT=0",
      "mkdir -p /Users/admin/openci-build",
      "cd /Users/admin/openci-build",
      "git init -q",
      `git remote add origin ${shellQuote(cloneUrl)}`,
      // The token goes over stdin, never in an Orchard URL or a git remote/config.
      "for fetch_attempt in 1 2 3; do",
      `  if git -c ${shellQuote(`http.extraHeader=Authorization: Basic ${auth}`)} fetch --no-tags ${fetchArgs}; then`,
      "    break",
      "  fi",
      '  if [[ "$fetch_attempt" == 3 ]]; then exit 1; fi',
      '  printf "Git fetch failed; retrying (%s/3)\\n" "$((fetch_attempt + 1))" >&2',
      '  sleep "$((fetch_attempt * 2))"',
      "done",
      ...(baseSha
        ? [
            "printf 'GitHub test merge remained stale after retries; creating a local test merge.\\n'",
            `printf 'Base: %s\\nHead: %s\\n' ${shellQuote(baseSha)} ${shellQuote(commitSha)}`,
            "set +e",
            `merge_tree=$(git merge-tree --write-tree --no-messages ${shellQuote(baseSha)} ${shellQuote(commitSha)})`,
            "merge_status=$?",
            "set -e",
            `if [[ "$merge_status" == 1 ]]; then exit ${localMergeConflictExitCode}; fi`,
            'if [[ "$merge_status" != 0 ]]; then exit "$merge_status"; fi',
            '[[ "$merge_tree" =~ ^[a-f0-9]{40}([a-f0-9]{24})?$ ]]',
            `checkout_sha=$(git -c user.name=OpenCI -c user.email=openci@localhost -c commit.gpgSign=false commit-tree "$merge_tree" -p ${shellQuote(baseSha)} -p ${shellQuote(commitSha)} -m 'OpenCI test merge')`,
            'git -c core.hooksPath=/dev/null checkout --detach "$checkout_sha"',
          ]
        : [`git checkout --detach ${shellQuote(commitSha)}`]),
      "git rev-parse HEAD",
    ].join("\n") + "\n"
  );
}

export function workflowScript(
  job: Job,
  dispatch: Dispatch,
  runNumber: number,
  secrets: Record<string, string>,
  checkout: ResolvedCheckout,
): string {
  validateFlutterVersion(job.flutterVersion);
  if (!Number.isSafeInteger(runNumber) || runNumber <= 0) throw new Error("Invalid run number");
  const runId = identity(dispatch).runId;
  const variables = {
    ...secrets,
    OPENCI_BUILD_JOB_ID: job.id,
    OPENCI_RUN_ID: runId,
    OPENCI_RUN_NUMBER: String(runNumber),
    OPENCI_CONTEXT: JSON.stringify({
      schemaVersion: 1,
      repository: {
        owner: job.owner,
        name: job.repo,
        githubBaseUrl: job.githubBaseUrl ?? "https://github.com",
      },
      jobId: job.id,
      runId,
      runNumber,
      ...checkout,
    }),
    OPENCI_PR_QR_OUTPUT: job.pullRequestNumber ? prQrOutputDirectory : "",
    // The first preview SDK appends tester URLs to a single file.
    OPENCI_FAD_PR_OUTPUT: job.pullRequestNumber ? `${prQrOutputDirectory}/legacy` : "",
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
      // Reserve one exit status for successful workflows that produced PR output.
      ...(job.pullRequestNumber ? ["trap 'exit 1' ERR"] : []),
      'export FVM_CACHE_PATH="$HOME/fvm"',
      'export FLUTTER_ROOT="$HOME/fvm/default"',
      'export PATH="$FLUTTER_ROOT/bin:$HOME/.pub-cache/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"',
      "unset LOKI_URL LOKI_USERNAME LOKI_PASSWORD",
      // Select the SDK outside the checkout so project FVM configuration cannot
      // override the workflow pin or resolve dependencies before selection.
      ...(job.flutterVersion
        ? [
            'cd "$HOME"',
            `fvm install ${shellQuote(job.flutterVersion)} --skip-pub-get`,
            `fvm global ${shellQuote(job.flutterVersion)}`,
          ]
        : []),
      "cd /Users/admin/openci-build",
      ...Object.entries(variables).map(([key, value]) => `export ${key}=${shellQuote(value)}`),
      ...(job.pullRequestNumber ? ['mkdir -p "$OPENCI_PR_QR_OUTPUT"'] : []),
      "flutter pub get",
      `flutter pub run ${shellQuote(`openci/${job.workflowFileName}`)}`,
      ...(job.pullRequestNumber
        ? [
            'for file in "$OPENCI_PR_QR_OUTPUT"/qr-*/url "$OPENCI_FAD_PR_OUTPUT"; do',
            `  if [ -s "$file" ]; then exit ${prQrOutputReady}; fi`,
            "done",
          ]
        : []),
    ].join("\n") + "\n"
  );
}
