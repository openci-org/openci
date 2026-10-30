import { GoogleAuth } from "google-auth-library";
import type { Dispatch } from "./model.js";

export interface GoogleRequest {
  (options: {
    url: string;
    method: "GET" | "POST";
    data?: unknown;
    timeout: number;
    retry: false;
    maxRedirects: number;
    signal?: AbortSignal;
  }): Promise<{ data: unknown }>;
}
const auth = new GoogleAuth({ scopes: ["https://www.googleapis.com/auth/cloud-platform"] });
export const googleRequest: GoogleRequest = (options) => auth.request(options);

export function secretUrl(path: string, project: string): string {
  const match =
    /^projects\/([a-z0-9-]+)\/(?:locations\/([a-z0-9-]+)\/)?secrets\/([A-Za-z0-9_-]+)\/versions\/([1-9][0-9]*)$/.exec(
      path,
    );
  if (!match || match[1] !== project) throw new Error("Invalid team secret reference");
  const host = match[2]
    ? `secretmanager.${match[2]}.rep.googleapis.com`
    : "secretmanager.googleapis.com";
  return `https://${host}/v1/${path}:access`;
}

export async function loadSecrets(
  references: { name: string; secretVersionPath: string }[],
  project: string,
  request = googleRequest,
  signal?: AbortSignal,
): Promise<Record<string, string>> {
  if (references.length > 100) throw new Error("Too many team secrets");
  const secrets: Record<string, string> = Object.create(null);
  let total = 0;
  for (const reference of references) {
    signal?.throwIfAborted();
    if (Object.hasOwn(secrets, reference.name)) throw new Error("Duplicate secret name");
    const { data } = await request({
      url: secretUrl(reference.secretVersionPath, project),
      method: "GET",
      timeout: 10000,
      retry: false,
      maxRedirects: 0,
      signal,
    });
    const encoded = (data as { payload?: { data?: unknown } })?.payload?.data;
    if (
      typeof encoded !== "string" ||
      encoded.length > 90000 ||
      !/^[A-Za-z0-9+/]*={0,2}$/.test(encoded)
    )
      throw new Error("Invalid secret value");
    const value = new TextDecoder("utf-8", { fatal: true, ignoreBOM: true }).decode(
      Buffer.from(encoded, "base64"),
    );
    total += Buffer.byteLength(value);
    if (total > 512 * 1024 || value.includes("\0")) throw new Error("Invalid secret value");
    secrets[reference.name] = value;
  }
  return secrets;
}

function notFound(error: unknown): boolean {
  return (
    !!error &&
    typeof error === "object" &&
    "response" in error &&
    (error.response as { status?: number })?.status === 404
  );
}

/** Do not reclaim a VM until the previous Cloud Run execution cannot resume. */
export async function stopCloudRunExecution(
  dispatch: Dispatch,
  expectedJob: string,
  request = googleRequest,
): Promise<void> {
  if (
    dispatch.cloudRunJob !== expectedJob ||
    !/^projects\/[a-z0-9-]+\/locations\/[a-z0-9-]+\/jobs\/[a-z][a-z0-9-]*$/.test(expectedJob) ||
    !dispatch.executionName?.startsWith(`${expectedJob}/executions/`) ||
    !/^[a-z][a-z0-9-]*$/.test(dispatch.executionName.slice(`${expectedJob}/executions/`.length))
  )
    throw new Error("Invalid Cloud Run execution identity");
  const url = `https://run.googleapis.com/v2/${dispatch.executionName}`;
  const read = async (): Promise<boolean> => {
    try {
      const { data } = await request({
        url,
        method: "GET",
        timeout: 10000,
        retry: false,
        maxRedirects: 0,
      });
      return (
        !!data &&
        typeof data === "object" &&
        "completionTime" in data &&
        typeof data.completionTime === "string" &&
        Number.isFinite(Date.parse(data.completionTime))
      );
    } catch (error) {
      if (notFound(error)) return true;
      throw new Error("Cloud Run execution lookup failed");
    }
  };
  if (await read()) return;
  await request({
    url: `${url}:cancel`,
    method: "POST",
    data: {},
    timeout: 10000,
    retry: false,
    maxRedirects: 0,
  });
  if (!(await read())) throw new Error("Cloud Run cancellation pending");
}
