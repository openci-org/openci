import { GoogleAuth } from "google-auth-library";
import type { BuildDispatch } from "./build_dispatch.js";

interface JsonRequest {
  (options: {
    url: string;
    method: "POST";
    data: unknown;
    timeout: number;
    retry: false;
    maxRedirects: number;
  }): Promise<{ data: unknown }>;
}
const auth = new GoogleAuth({ scopes: ["https://www.googleapis.com/auth/cloud-platform"] });

export async function launchCloudRunJob(
  dispatch: BuildDispatch,
  request?: JsonRequest,
): Promise<string> {
  const job = dispatch.cloudRunJob;
  if (!/^projects\/[a-z0-9-]+\/locations\/[a-z0-9-]+\/jobs\/[a-z][a-z0-9-]*$/.test(job)) {
    throw new Error("Invalid Cloud Run job name");
  }
  const send = request ?? ((options) => auth.request(options));
  const { data } = await send({
    url: `https://run.googleapis.com/v2/${job}:run`,
    method: "POST",
    data: {
      overrides: {
        taskCount: 1,
        containerOverrides: [
          {
            env: [
              { name: "BUILD_JOB_ID", value: dispatch.jobId },
              { name: "BUILD_DISPATCH_ID", value: dispatch.id },
            ],
          },
        ],
      },
    },
    timeout: 20000,
    retry: false,
    maxRedirects: 0,
  });
  // The API may canonicalize a project ID to its numeric project number.
  // This is an operation identifier, never a caller-controlled request URL.
  if (
    !data ||
    typeof data !== "object" ||
    ("error" in data && data.error != null) ||
    !("name" in data) ||
    typeof data.name !== "string" ||
    !/^projects\/[a-z0-9-]+\/locations\/[a-z0-9-]+\/operations\/[a-zA-Z0-9_-]+$/.test(data.name)
  ) {
    throw new Error("Invalid Cloud Run operation response");
  }
  return data.name;
}
