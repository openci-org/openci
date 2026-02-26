import { createClient as createServerClient } from "@supabase/supabase-js";
import { NextResponse } from "next/server";
import crypto from "node:crypto";
import { App } from "octokit";
import { parse as parseYaml } from "yaml";

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

interface WebhookContext {
  event: string;
  action: string | undefined;
  owner: string;
  repoName: string;
  fullName: string;
  sender: string | undefined;
  installationId: number | undefined;
  commitSha: string | null;
  branch: string | null;
  baseBranch: string | null;
  tagName: string | null;
  pullRequestNumber: number | null;
}

function matchesTrigger(workflow: Record<string, unknown>, ctx: WebhookContext): boolean {
  const on = workflow.on as Record<string, unknown> | string | string[] | undefined;
  if (!on) return false;

  if (typeof on === "string") {
    return on === ctx.event;
  }

  if (Array.isArray(on)) {
    return on.includes(ctx.event);
  }

  const triggerConfig = on[ctx.event];
  if (triggerConfig === undefined) return false;
  if (triggerConfig === null) return true;

  if (typeof triggerConfig !== "object") return true;

  const config = triggerConfig as Record<string, unknown>;
  const branches = config.branches as string[] | undefined;

  if (!branches || branches.length === 0) return true;

  const targetBranch = ctx.event === "pull_request" ? ctx.baseBranch : ctx.branch;
  if (!targetBranch) return false;

  return branches.some((pattern) => branchMatches(targetBranch, pattern));
}

function branchMatches(branch: string, pattern: string): boolean {
  if (pattern === "*" || pattern === "**") return true;
  if (!pattern.includes("*")) return branch === pattern;
  const regex = new RegExp(`^${pattern.split("*").map(escapeRegex).join(".*")}$`);
  return regex.test(branch);
}

function escapeRegex(str: string): string {
  return str.replace(/[.+?^${}()|[\]\\]/g, "\\$&");
}

export async function POST(request: Request) {
  console.log("Webhook received", {
    SUPABASE_URL: Boolean(SUPABASE_URL),
    SUPABASE_SERVICE_ROLE_KEY: Boolean(SUPABASE_SERVICE_ROLE_KEY),
    GITHUB_APP_ID: Boolean(GITHUB_APP_ID),
    GITHUB_PRIVATE_KEY: Boolean(GITHUB_PRIVATE_KEY),
    GITHUB_WEBHOOK_SECRET: Boolean(GITHUB_WEBHOOK_SECRET),
  });
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
  let baseBranch: string | null = null;
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
    baseBranch = ((pr?.base as Record<string, unknown>)?.ref as string) ?? null;
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

  // Find the org that has this GitHub integration
  const { data: integration, error: integrationError } = await supabase
    .from("integrations")
    .select("org_id")
    .eq("github_account", owner)
    .limit(1)
    .maybeSingle();

  if (!integration) {
    console.log(`No integration found for ${fullName}`, {
      owner,
      repoName,
      error: integrationError,
    });
    return NextResponse.json({
      received: true,
      processed: false,
      reason: "no matching integration",
    });
  }

  const orgId = integration.org_id;

  const ctx: WebhookContext = {
    event,
    action,
    owner,
    repoName,
    fullName,
    sender,
    installationId,
    commitSha,
    branch,
    baseBranch,
    tagName,
    pullRequestNumber,
  };

  const matchedWorkflows = await fetchMatchingWorkflows(ctx);

  if (matchedWorkflows.length === 0) {
    console.log(`No matching workflows for ${fullName} (${event} → ${branch ?? tagName})`);
    return NextResponse.json({ received: true, processed: false, reason: "no matching workflows" });
  }

  console.log(
    `${matchedWorkflows.length} workflow(s) matched for ${fullName} (${event} → ${branch ?? tagName})`,
  );

  const buildIds: string[] = [];

  for (const { name, yamlDefinition } of matchedWorkflows) {
    let checkRunId: number | null = null;

    if (installationId && commitSha && GITHUB_APP_ID && GITHUB_PRIVATE_KEY) {
      try {
        const app = getGitHubApp();
        const octokit = await app.getInstallationOctokit(installationId);
        const { data: checkRun } = await octokit.request("POST /repos/{owner}/{repo}/check-runs", {
          owner,
          repo: repoName,
          name: name ?? "OpenCI",
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
        org_id: orgId,
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
      console.error(`Failed to insert build for ${name}:`, insertError);
      continue;
    }

    if (createdBuild) {
      buildIds.push(createdBuild.id);
      console.log(`Build created: ${name} → ${createdBuild.id}`);
    }
  }

  return NextResponse.json({
    received: true,
    processed: true,
    builds_created: buildIds.length,
    build_ids: buildIds,
  });
}

interface MatchedWorkflow {
  name: string;
  yamlDefinition: string;
}

async function fetchMatchingWorkflows(ctx: WebhookContext): Promise<MatchedWorkflow[]> {
  if (!ctx.installationId || !ctx.commitSha || !GITHUB_APP_ID || !GITHUB_PRIVATE_KEY) {
    return [];
  }

  const matched: MatchedWorkflow[] = [];

  try {
    const app = getGitHubApp();
    const octokit = await app.getInstallationOctokit(ctx.installationId);

    const { data: files } = await octokit.request("GET /repos/{owner}/{repo}/contents/{path}", {
      owner: ctx.owner,
      repo: ctx.repoName,
      path: ".openci",
      ref: ctx.commitSha ?? undefined,
    });

    if (!Array.isArray(files)) return [];

    const yamlFiles = files.filter(
      (f: Record<string, unknown>) =>
        (f.name as string).endsWith(".yaml") || (f.name as string).endsWith(".yml"),
    );

    const results = await Promise.all(
      yamlFiles.map(async (yamlFile) => {
        try {
          const { data: fileContent } = await octokit.request(
            "GET /repos/{owner}/{repo}/contents/{path}",
            {
              owner: ctx.owner,
              repo: ctx.repoName,
              path: yamlFile.path as string,
              ref: ctx.commitSha ?? undefined,
            },
          );

          if (typeof fileContent !== "object" || !("content" in fileContent)) return null;

          const raw = Buffer.from(fileContent.content as string, "base64").toString("utf-8");
          const parsed = parseYaml(raw) as Record<string, unknown>;

          if (!matchesTrigger(parsed, ctx)) {
            console.log(`Skipped ${yamlFile.name}: trigger does not match`);
            return null;
          }

          return {
            name: (parsed.name as string) ?? (yamlFile.name as string),
            yamlDefinition: raw,
          };
        } catch (error) {
          console.error(`Failed to process ${yamlFile.name}:`, error);
          return null;
        }
      }),
    );

    matched.push(...results.filter((r): r is MatchedWorkflow => r !== null));
  } catch (error) {
    console.error("Failed to fetch .openci/ directory:", error);
  }

  return matched;
}
