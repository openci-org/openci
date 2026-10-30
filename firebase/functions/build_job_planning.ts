import { GoogleAuth } from "google-auth-library";

const auth = new GoogleAuth();

export function requestedWebhookTaskId(payload: {
  data: unknown;
  errors?: unknown[];
}): string | null {
  if (payload.errors?.length) return null;
  const data = payload.data;
  if (!data || typeof data !== "object" || Array.isArray(data))
    throw new Error("Invalid mutation result");
  if (!("task" in data) || data.task == null) return null;
  const task = data.task;
  if (typeof task !== "object" || !("id" in task) || typeof task.id !== "string" || !task.id) {
    throw new Error("Invalid mutation task ID");
  }
  return task.id;
}

/** The Dart Function owns the entire planning transaction; Node only dispatches. */
export async function invokeProcessWebhookTask(functionUrl: string, taskId: string): Promise<void> {
  const url = new URL(functionUrl);
  const local =
    process.env.FUNCTIONS_EMULATOR === "true" &&
    url.protocol === "http:" &&
    ["127.0.0.1", "localhost"].includes(url.hostname);
  if (!local && url.protocol !== "https:") throw new Error("Dart Function requires HTTPS");
  const headers = new Headers({ "content-type": "application/json" });
  if (!local) {
    const client = await auth.getIdTokenClient(functionUrl);
    const authorization = (await client.getRequestHeaders(functionUrl)).get("authorization");
    if (!authorization) throw new Error("Missing Dart Function identity token");
    headers.set("authorization", authorization);
  }
  const response = await fetch(functionUrl, {
    method: "POST",
    headers,
    body: JSON.stringify({ taskId }),
    redirect: "error",
    signal: AbortSignal.timeout(500000),
  });
  if (!response.ok) throw new Error("Dart Function request failed");
  const body: unknown = await response.json();
  if (
    !body ||
    typeof body !== "object" ||
    !("result" in body) ||
    !["created", "duplicate", "failed"].includes(String(body.result))
  ) {
    throw new Error("Invalid Dart Function response");
  }
}
