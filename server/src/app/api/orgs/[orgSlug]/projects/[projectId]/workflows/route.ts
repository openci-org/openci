import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { getOrgBySlug, getProjectById } from "@/lib/supabase/queries";

// POST /api/orgs/[orgSlug]/projects/[projectId]/workflows — create a new workflow
export async function POST(
  request: Request,
  { params }: { params: Promise<{ orgSlug: string; projectId: string }> }
) {
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getClaims();
  if (authError || !authData?.claims) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { orgSlug, projectId } = await params;
  const org = await getOrgBySlug(supabase, orgSlug);
  if (!org) {
    return NextResponse.json({ error: "Organization not found" }, { status: 404 });
  }

  const project = await getProjectById(supabase, projectId, org.id);
  if (!project) {
    return NextResponse.json({ error: "Project not found" }, { status: 404 });
  }

  let body: { name?: string };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const name = body.name?.trim();
  if (!name) {
    return NextResponse.json({ error: "name is required" }, { status: 400 });
  }

  const { data: workflow, error } = await supabase
    .from("workflows")
    .insert({ project_id: projectId, name, yaml_definition: "" })
    .select("id, name, project_id, is_active, yaml_definition, created_at, updated_at")
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ workflow }, { status: 201 });
}
