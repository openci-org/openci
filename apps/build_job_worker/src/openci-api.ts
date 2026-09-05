export type BuildJobStatus =
  | "WAITING"
  | "QUEUED"
  | "IN_PROGRESS"
  | "SUCCESS"
  | "FAILURE"
  | "CANCELLED"
  | "SKIPPED"
  | "TIMED_OUT";

// Only the required fields of openci_shared's BuildJob are exposed for now.
export interface BuildJob {
  readonly id: string;
  readonly status: BuildJobStatus;
  readonly owner: string;
  readonly repo: string;
  readonly workflowName: string;
  readonly workflowFileName: string;
  readonly createdAt: string;
  readonly updatedAt: string;
}

export interface GetBuildJobOptions {
  readonly serverUrl: string;
  readonly internalApiKey: string;
  readonly timeoutMs?: number;
}

export class OpenCiApiError extends Error {
  constructor(
    readonly statusCode: number,
    jobId: string,
  ) {
    super(`Failed to get build job ${jobId}: HTTP ${statusCode}`);
    this.name = "OpenCiApiError";
  }
}

export class InvalidBuildJobResponseError extends Error {
  constructor(jobId: string, detail: string) {
    super(`Invalid response for build job ${jobId}: ${detail}`);
    this.name = "InvalidBuildJobResponseError";
  }
}

// Reads a job without claiming it or changing its status. Retries belong to the caller.
export async function getBuildJob(
  jobId: string,
  { serverUrl, internalApiKey, timeoutMs = 10_000 }: GetBuildJobOptions,
): Promise<BuildJob> {
  if (jobId.trim().length === 0 || jobId === "." || jobId === "..") {
    throw new TypeError("jobId must be a non-empty path segment other than '.' or '..'");
  }
  if (internalApiKey.trim().length === 0 || /\s/.test(internalApiKey)) {
    throw new TypeError("internalApiKey must be non-empty and contain no whitespace");
  }
  if (!Number.isInteger(timeoutMs) || timeoutMs <= 0 || timeoutMs > 2_147_483_647) {
    throw new RangeError("timeoutMs must be an integer between 1 and 2147483647");
  }

  const url = buildJobUrl(serverUrl, jobId);
  const signal = AbortSignal.timeout(timeoutMs);
  const response = await fetch(url, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${internalApiKey}`,
      Accept: "application/json",
    },
    signal,
    // Do not forward the internal key to a redirected endpoint.
    redirect: "manual",
  });

  if (!response.ok) {
    // Release the body without exposing its contents or masking the HTTP error.
    await response.body?.cancel().catch(() => undefined);
    throw new OpenCiApiError(response.status, jobId);
  }

  let payload: unknown;
  try {
    payload = await response.json();
  } catch (error) {
    // Keep timeouts during body download distinct from malformed JSON.
    signal.throwIfAborted();
    if (error instanceof SyntaxError) {
      throw new InvalidBuildJobResponseError(jobId, "body is not valid JSON");
    }
    throw error;
  }

  return parseBuildJob(payload, jobId);
}

function buildJobUrl(serverUrl: string, jobId: string): URL {
  let url: URL;
  try {
    url = new URL(serverUrl);
  } catch {
    throw new TypeError("serverUrl must be an absolute HTTP(S) URL");
  }
  if (
    (url.protocol !== "http:" && url.protocol !== "https:") ||
    url.username ||
    url.password ||
    url.search ||
    url.hash
  ) {
    throw new TypeError("serverUrl must be HTTP(S) without credentials, query, or fragment");
  }

  url.pathname = `${url.pathname.replace(/\/+$/, "")}/builds/${encodeURIComponent(jobId)}`;
  return url;
}

function parseBuildJob(payload: unknown, jobId: string): BuildJob {
  if (typeof payload !== "object" || payload === null || Array.isArray(payload)) {
    throw new InvalidBuildJobResponseError(jobId, "expected an object");
  }
  const data = payload as Record<string, unknown>;
  const id = requiredString(data, "id", jobId);
  if (id !== jobId) {
    throw new InvalidBuildJobResponseError(jobId, "id does not match the requested job");
  }

  return {
    id,
    status: buildJobStatus(data.status, jobId),
    owner: requiredString(data, "owner", jobId),
    repo: requiredString(data, "repo", jobId),
    workflowName: requiredString(data, "workflowName", jobId),
    workflowFileName: requiredString(data, "workflowFileName", jobId),
    createdAt: timestampString(data, "createdAt", jobId),
    updatedAt: timestampString(data, "updatedAt", jobId),
  };
}

function requiredString(data: Record<string, unknown>, key: string, jobId: string): string {
  const value = data[key];
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new InvalidBuildJobResponseError(jobId, `${key} must be a non-empty string`);
  }
  return value;
}

function timestampString(data: Record<string, unknown>, key: string, jobId: string): string {
  const value = requiredString(data, key, jobId);
  const timestamp = Date.parse(value);
  // Dart serializes UTC ISO timestamps, optionally with microseconds. Keep that precision.
  if (
    !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?Z$/.test(value) ||
    !Number.isFinite(timestamp) ||
    new Date(timestamp).toISOString().slice(0, 19) !== value.slice(0, 19)
  ) {
    throw new InvalidBuildJobResponseError(jobId, `${key} must be a valid UTC ISO timestamp`);
  }
  return value;
}

function buildJobStatus(value: unknown, jobId: string): BuildJobStatus {
  switch (value) {
    case "WAITING":
    case "QUEUED":
    case "IN_PROGRESS":
    case "SUCCESS":
    case "FAILURE":
    case "CANCELLED":
    case "SKIPPED":
    case "TIMED_OUT":
      return value;
    default:
      throw new InvalidBuildJobResponseError(jobId, "status is not a recognized BuildJobStatus");
  }
}
