const codes = new Set([
  "functions/aborted",
  "functions/invalid-argument",
  "functions/invalid-credential",
  "functions/failed-precondition",
  "functions/permission-denied",
  "functions/unauthenticated",
  "functions/not-found",
  "functions/internal-error",
  "functions/unknown-error",
  "data-connect/permission-denied",
  "data-connect/query-error",
  "data-connect/invalid-argument",
  "data-connect/unavailable",
  "data-connect/internal-error",
  "app/invalid-credential",
  "app/network-error",
  "app/network-timeout",
  "ETIMEDOUT",
  "ECONNREFUSED",
  "ECONNRESET",
  "ENOTFOUND",
  "EAI_AGAIN",
]);

const messages: Record<string, string> = {
  "Unexpected mutation principal": "unexpected_principal",
  "Invalid completed webhook result": "invalid_mutation_result",
  "Invalid created build job ID": "invalid_job_id",
  "Invalid cancellation count": "invalid_cancellation_count",
  "Invalid cancellation source": "invalid_cancellation_source",
  "Invalid run count": "invalid_run_count",
  "Check publication lease lost": "check_lease_lost",
  "Check publication lease is expiring": "check_lease_expiring",
  "Invalid queued job": "invalid_queued_job",
  "GitHub connection is inactive": "github_connection_inactive",
  "GitHub App credentials missing": "github_credentials_missing",
  "Invalid GitHub configuration": "invalid_github_configuration",
  "GitHub installation mismatch": "github_installation_mismatch",
  "Repository does not belong to the connected installation": "github_repository_mismatch",
  "Check reconciliation limit exceeded": "check_reconciliation_limit",
};

const httpStatuses = new Set([400, 401, 403, 404, 408, 409, 422, 429, 500, 502, 503, 504]);

/** Keep only fixed diagnostics; SDK errors may contain credentials and payloads. */
export function buildQueueFailureReason(failure: unknown): string {
  if (failure instanceof BuildQueueEnqueueError) return failure.reason;
  if (!failure || typeof failure !== "object") return "unknown";
  if ("code" in failure && typeof failure.code === "string" && codes.has(failure.code))
    return failure.code;
  // Octokit exposes HTTP status without requiring access to its private response body.
  if ("status" in failure && typeof failure.status === "number" && httpStatuses.has(failure.status))
    return `http_${failure.status}`;
  if (failure instanceof Error) {
    if (Object.hasOwn(messages, failure.message)) return messages[failure.message];
    if (failure.name === "TimeoutError") return "request_timeout";
    if (failure.name === "AbortError") return "request_aborted";
  }
  return "unknown";
}

/** Preserve the safe reason when replacing a task SDK exception. Never retain its cause. */
export class BuildQueueEnqueueError extends Error {
  readonly reason: string;

  constructor(failure: unknown) {
    super("Build dispatch could not be queued");
    this.reason = buildQueueFailureReason(failure);
  }
}
