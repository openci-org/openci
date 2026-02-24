import { createClient as createServerClient } from "@supabase/supabase-js";
import { NextResponse } from "next/server";
import crypto from "node:crypto";
import { App } from "octokit";

const GITHUB_WEBHOOK_SECRET = process.env.GITHUB_WEBHOOK_SECRET ?? "";
const GITHUB_APP_ID = process.env.GITHUB_APP_ID ?? "";
const GITHUB_PRIVATE_KEY = process.env.GITHUB_PRIVATE_KEY ?? "";
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY ?? "";

function getServiceClient() {
  return createServerClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });
}

function getGitHubApp(): App {
  return new App({
    appId: GITHUB_APP_ID,
    privateKey: GITHUB_PRIVATE_KEY,
    webhooks: { secret: GITHUB_WEBHOOK_SECRET },
  });
}

function verifySignature(body: string, signature: string): boolean {
  if (!GITHUB_WEBHOOK_SECRET) return true;
  const expected = `sha256=${crypto.createHmac("sha256", GITHUB_WEBHOOK_SECRET).update(body).digest("hex")}`;
  try {
    return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected));
  } catch {
    return false;
  }
}

export async function POST(request: Request) {
  const body = await request.text();
  const signature = request.headers.get("x-hub-signature-256") ?? "";
  const event = request.headers.get("x-github-event") ?? "";

  if (!verifySignature(body, signature)) {
    return NextResponse.json({ error: "Invalid signature" }, { status: 401 });
  }

  let payload: Record<string, unknown>;
  try {
    payload = JSON.parse(body) as Record<string, unknown>;
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const repo = payload.repository as Record<string, unknown> | undefined;
  const fullName = repo?.full_name as string | undefined;
  if (!fullName) {
    return NextResponse.json({ error: "No repository" }, { status: 400 });
  }

  const [owner, repoName] = fullName.split("/");
  const action = payload.action as string | undefined;
  const sender = (payload.sender as Record<string, unknown>)?.login as string | undefined;
  const installationId = (payload.installation as Record<string, unknown>)?.id as
    | number
    | undefined;

  let shouldProcess = false;
  if (event === "push" && !(payload.ref as string)?.startsWith("refs/tags/")) {
    shouldProcess = true;
  } else if (event === "pull_request" && (action === "opened" || action === "synchronize")) {
    shouldProcess = true;
  } else if (event === "create" && (payload.ref_type as string) === "tag") {
    shouldProcess = true;
  } else if (event === "release" && action === "published") {
    shouldProcess = true;
  }

  if (!shouldProcess) {
    return NextResponse.json({ received: true, processed: false });
  }

  let commitSha: string | null = null;
  let branch: string | null = null;
  let tagName: string | null = null;
  let pullRequestNumber: number | null = null;

  if (event === "push") {
    commitSha =
      (payload.after as string) ??
      ((payload.head_commit as Record<string, unknown>)?.id as string) ??
      null;
    const ref = payload.ref as string | undefined;
    branch = ref?.startsWith("refs/heads/") ? ref.replace("refs/heads/", "") : null;
  } else if (event === "pull_request") {
    const pr = payload.pull_request as Record<string, unknown>;
    pullRequestNumber = pr?.number as number;
    branch = ((pr?.head as Record<string, unknown>)?.ref as string) ?? null;
    commitSha = ((pr?.head as Record<string, unknown>)?.sha as string) ?? null;
  } else if (event === "create") {
    tagName = (payload.ref as string) ?? null;
  } else if (event === "release") {
    tagName = ((payload.release as Record<string, unknown>)?.tag_name as string) ?? null;
  }

  let installationToken: string | null = null;
  let tokenExpiresAt: string | null = null;

  if (installationId && GITHUB_APP_ID && GITHUB_PRIVATE_KEY) {
    try {
      const app = getGitHubApp();
      const octokit = await app.getInstallationOctokit(installationId);
      const { data } = await octokit.request(
        "POST /app/installations/{installation_id}/access_tokens",
        { installation_id: installationId },
      );
      installationToken = data.token;
      tokenExpiresAt = data.expires_at;

      if ((event === "create" || event === "release") && tagName && !commitSha) {
        const { data: commit } = await octokit.request("GET /repos/{owner}/{repo}/commits/{ref}", {
          owner,
          repo: repoName,
          ref: tagName,
        });
        commitSha = commit.sha;
      }
    } catch (error) {
      console.error("Failed to get installation token:", error);
    }
  }

  const supabase = getServiceClient();

  const { data: project } = await supabase
    .from("projects")
    .select("id")
    .eq("github_owner", owner)
    .eq("github_repo", repoName)
    .single();

  if (!project) {
    console.log(`No project found for ${fullName}`);
    return NextResponse.json({ received: true, processed: false, reason: "no matching project" });
  }

  let yamlDefinition: string | null = null;

  if (installationId && commitSha && GITHUB_APP_ID && GITHUB_PRIVATE_KEY) {
    try {
      const app = getGitHubApp();
      const octokit = await app.getInstallationOctokit(installationId);

      const { data: files } = await octokit.request("GET /repos/{owner}/{repo}/contents/{path}", {
        owner,
        repo: repoName,
        path: ".openci",
        ref: commitSha,
      });

      if (Array.isArray(files)) {
        const yamlFile = files.find(
          (f: Record<string, unknown>) =>
            (f.name as string).endsWith(".yaml") || (f.name as string).endsWith(".yml"),
        );
        if (yamlFile) {
          const { data: fileContent } = await octokit.request(
            "GET /repos/{owner}/{repo}/contents/{path}",
            {
              owner,
              repo: repoName,
              path: yamlFile.path as string,
              ref: commitSha,
            },
          );
          if (typeof fileContent === "object" && "content" in fileContent) {
            yamlDefinition = Buffer.from(fileContent.content as string, "base64").toString("utf-8");
          }
        }
      }
    } catch (error) {
      console.error("Failed to fetch workflow YAML:", error);
    }
  }

  if (!yamlDefinition) {
    console.log(`No workflow YAML found for ${fullName}`);
    return NextResponse.json({ received: true, processed: false, reason: "no workflow yaml" });
  }

  let checkRunId: number | null = null;

  if (installationId && commitSha && GITHUB_APP_ID && GITHUB_PRIVATE_KEY) {
    try {
      const app = getGitHubApp();
      const octokit = await app.getInstallationOctokit(installationId);
      const { data: checkRun } = await octokit.request("POST /repos/{owner}/{repo}/check-runs", {
        owner,
        repo: repoName,
        name: "OpenCI",
        head_sha: commitSha,
        status: "queued",
        started_at: new Date().toISOString(),
      });
      checkRunId = checkRun.id;
    } catch (error) {
      console.error("Failed to create check run:", error);
    }
  }

  const { data: createdBuild, error: insertError } = await supabase
    .from("builds")
    .insert({
      project_id: project.id,
      status: "queued",
      runner_os: "macos",
      github_owner: owner,
      github_repo: repoName,
      commit_sha: commitSha,
      branch,
      tag_name: tagName,
      pull_request_number: pullRequestNumber,
      github_event: event,
      github_action: action ?? null,
      github_sender: sender ?? null,
      installation_id: installationId,
      installation_token: installationToken,
      token_expires_at: tokenExpiresAt,
      check_run_id: checkRunId,
      yaml_definition: yamlDefinition,
    })
    .select("id")
    .single();

  if (insertError) {
    console.error("Failed to insert build:", insertError);
    return NextResponse.json({ error: "Failed to create build" }, { status: 500 });
  }

  console.log(`Build created for ${fullName} (${event}): ${createdBuild?.id}`);

  return NextResponse.json({
    received: true,
    processed: true,
    build_id: createdBuild?.id,
  });
}
