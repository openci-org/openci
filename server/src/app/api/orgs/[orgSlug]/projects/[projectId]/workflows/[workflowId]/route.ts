import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { getOrgBySlug, getProjectById, getWorkflowById } from "@/lib/supabase/queries";
import type { TriggerType } from "@/lib/supabase/types";

type Params = { params: Promise<{ orgSlug: string; projectId: string; workflowId: string }> };

async function resolveContext(orgSlug: string, projectId: string, workflowId: string) {
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getClaims();
  if (authError || !authData?.claims) return { error: "Unauthorized", status: 401 } as const;

  const org = await getOrgBySlug(supabase, orgSlug);
  if (!org) return { error: "Organization not found", status: 404 } as const;

  const project = await getProjectById(supabase, projectId, org.id);
  if (!project) return { error: "Project not found", status: 404 } as const;

  const workflow = await getWorkflowById(supabase, workflowId);
  if (!workflow || workflow.project_id !== projectId) {
    return { error: "Workflow not found", status: 404 } as const;
  }

  return { supabase, workflow } as const;
}

// GET /api/orgs/[orgSlug]/projects/[projectId]/workflows/[workflowId]
export async function GET(
  _request: Request,
  { params }: Params
) {
  const { orgSlug, projectId, workflowId } = await params;
  const ctx = await resolveContext(orgSlug, projectId, workflowId);
  if ("error" in ctx) {
    return NextResponse.json({ error: ctx.error }, { status: ctx.status });
  }
  return NextResponse.json({ workflow: ctx.workflow });
}

// PATCH /api/orgs/[orgSlug]/projects/[projectId]/workflows/[workflowId]
export async function PATCH(
  request: Request,
  { params }: Params
) {
  const { orgSlug, projectId, workflowId } = await params;
  const ctx = await resolveContext(orgSlug, projectId, workflowId);
  if ("error" in ctx) {
    return NextResponse.json({ error: ctx.error }, { status: ctx.status });
  }
  const { supabase } = ctx;

  let body: {
    name?: string;
    yaml_definition?: string;
    is_active?: boolean;
    triggers?: Array<{
      trigger_type: TriggerType;
      github_repo: string;
      branch_pattern?: string | null;
    }>;
  };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const updates: Record<string, unknown> = { updated_at: new Date().toISOString() };
  if (body.name !== undefined) {
    const name = body.name.trim();
    if (!name) return NextResponse.json({ error: "name cannot be empty" }, { status: 400 });
    updates.name = name;
  }
  if (body.yaml_definition !== undefined) updates.yaml_definition = body.yaml_definition;
  if (body.is_active !== undefined) updates.is_active = body.is_active;

  const { error: updateError } = await supabase
    .from("workflows")
    .update(updates)
    .eq("id", workflowId);

  if (updateError) {
    return NextResponse.json({ error: updateError.message }, { status: 500 });
  }

  // Replace triggers if provided
  if (body.triggers !== undefined) {
    const { error: deleteError } = await supabase
      .from("workflow_triggers")
      .delete()
      .eq("workflow_id", workflowId);

    if (deleteError) {
      return NextResponse.json({ error: deleteError.message }, { status: 500 });
    }

    if (body.triggers.length > 0) {
      const triggerRows = body.triggers.map((t) => ({
        workflow_id: workflowId,
        trigger_type: t.trigger_type,
        github_repo: t.github_repo,
        branch_pattern: t.branch_pattern ?? null,
      }));
      const { error: insertError } = await supabase.from("workflow_triggers").insert(triggerRows);
      if (insertError) {
        return NextResponse.json({ error: insertError.message }, { status: 500 });
      }
    }
  }

  const updated = await getWorkflowById(supabase, workflowId);
  return NextResponse.json({ workflow: updated });
}

// DELETE /api/orgs/[orgSlug]/projects/[projectId]/workflows/[workflowId]
export async function DELETE(
  _request: Request,
  { params }: Params
) {
  const { orgSlug, projectId, workflowId } = await params;
  const ctx = await resolveContext(orgSlug, projectId, workflowId);
  if ("error" in ctx) {
    return NextResponse.json({ error: ctx.error }, { status: ctx.status });
  }
  const { supabase } = ctx;

  const { error } = await supabase.from("workflows").delete().eq("id", workflowId);
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return new NextResponse(null, { status: 204 });
}
