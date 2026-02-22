import { NextResponse } from "next/server";
import { createClient as createServerClient } from "@supabase/supabase-js";
import crypto from "node:crypto";

// GitHub Webhook handler
// Replaces firebase/functions/src/github-app.ts
//
// Receives GitHub webhook events, matches them against workflow_triggers,
// and creates builds rows for matching workflows.

const GITHUB_WEBHOOK_SECRET = process.env.GITHUB_WEBHOOK_SECRET ?? "";
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY ?? "";

// Create a service-role client that bypasses RLS
function getServiceClient() {
  return createServerClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });
}

// Verify HMAC signature from GitHub
function verifySignature(body: string, signature: string): boolean {
  if (!GITHUB_WEBHOOK_SECRET) return true; // Skip verification in dev
  const expected = `sha256=${crypto.createHmac("sha256", GITHUB_WEBHOOK_SECRET).update(body).digest("hex")}`;
  try {
    return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected));
  } catch {
    return false;
  }
}

// Map GitHub event + action to our trigger_type enum
function mapTriggerType(event: string, action?: string): string | null {
  if (event === "push") return "push";
  if (event === "pull_request") return "pull_request";
  if (event === "create") return "tag";
  if (event === "release" && action === "published") return "release";
  return null;
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

  const action = payload.action as string | undefined;
  const triggerType = mapTriggerType(event, action);
  if (!triggerType) {
    // Unhandled event type — acknowledge but don't create a build
    return NextResponse.json({ received: true, processed: false });
  }

  // Extract context from payload
  const sender = (payload.sender as Record<string, unknown>)?.login as string | undefined;
  const installation = (payload.installation as Record<string, unknown>)?.id as number | undefined;
  let commitSha: string | undefined;
  let branch: string | undefined;
  let tagName: string | undefined;
  let pullRequestNumber: number | undefined;

  if (event === "push") {
    commitSha = payload.after as string | undefined;
    const ref = payload.ref as string | undefined;
    if (ref?.startsWith("refs/heads/")) {
      branch = ref.replace("refs/heads/", "");
    }
  } else if (event === "pull_request") {
    const pr = payload.pull_request as Record<string, unknown> | undefined;
    pullRequestNumber = pr?.number as number | undefined;
    branch = (pr?.head as Record<string, unknown>)?.ref as string | undefined;
    commitSha = (pr?.head as Record<string, unknown>)?.sha as string | undefined;
  } else if (event === "create" && (payload.ref_type as string) === "tag") {
    tagName = payload.ref as string | undefined;
  } else if (event === "release") {
    const rel = payload.release as Record<string, unknown> | undefined;
    tagName = rel?.tag_name as string | undefined;
  }

  const supabase = getServiceClient();

  // Find matching workflow_triggers by repo + trigger type
  const { data: triggers, error: triggerError } = await supabase
    .from("workflow_triggers")
    .select(
      `
      id, workflow_id, branch_pattern,
      workflows (
        id, project_id, is_active,
        projects (
          id, org_id,
          integrations (installation_id)
        )
      )
    `
    )
    .eq("github_repo", fullName)
    .eq("trigger_type", triggerType);

  if (triggerError) {
    return NextResponse.json({ error: "DB error" }, { status: 500 });
  }

  if (!triggers || triggers.length === 0) {
    return NextResponse.json({ received: true, processed: false, reason: "no matching triggers" });
  }

  // Collect matching triggers into build insert payloads (no await in loop)
  const buildInserts = triggers
    .filter((trigger) => {
      const workflow = trigger.workflows as unknown as Record<string, unknown> | null;
      if (!workflow || !workflow.is_active) return false;
      if (trigger.branch_pattern && branch && !branchMatches(branch, trigger.branch_pattern)) return false;
      const project = workflow.projects as Record<string, unknown> | null;
      return project !== null;
    })
    .map((trigger) => {
      const workflow = trigger.workflows as unknown as Record<string, unknown>;
      return {
        project_id: workflow.project_id as string,
        workflow_id: workflow.id as string,
        status: "queued",
        github_owner: fullName.split("/")[0],
        github_repo: fullName,
        commit_sha: commitSha,
        branch,
        tag_name: tagName,
        pull_request_number: pullRequestNumber,
        github_event: event,
        github_action: action,
        github_sender: sender,
        installation_id: installation,
        // installation_token: fetched by worker via GitHub App before cloning
      };
    });

  if (buildInserts.length === 0) {
    return NextResponse.json({ received: true, processed: false, reason: "no active matching triggers" });
  }

  const { data: createdBuilds } = await supabase
    .from("builds")
    .insert(buildInserts)
    .select("id");

  const buildsCreated = createdBuilds?.map((b) => b.id) ?? [];

  return NextResponse.json({
    received: true,
    processed: true,
    builds_created: buildsCreated.length,
    build_ids: buildsCreated,
  });
}

// Simple glob-style branch pattern matching
// Supports "*" as wildcard (e.g. "feature/*")
function branchMatches(branch: string, pattern: string): boolean {
  if (pattern === "*") return true;
  if (!pattern.includes("*")) return branch === pattern;
  const regex = new RegExp(`^${pattern.split("*").map(escapeRegex).join(".*")}$`);
  return regex.test(branch);
}

function escapeRegex(str: string): string {
  return str.replace(/[.+?^${}()|[\]\\]/g, "\\$&");
}
