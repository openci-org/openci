import { getTeamBySlug } from "@/lib/supabase/queries";
import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

// POST /api/orgs/[teamSlug]/workflows — create a new workflow
export async function POST(request: Request, { params }: { params: Promise<{ teamSlug: string }> }) {
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getClaims();
  if (authError || !authData?.claims) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { teamSlug } = await params;
  const org = await getTeamBySlug(supabase, teamSlug);
  if (!org) {
    return NextResponse.json({ error: "Team not found" }, { status: 404 });
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
    .insert({ team_id: org.id, name, yaml_definition: "" })
    .select("id, name, team_id, is_active, yaml_definition, created_at, updated_at")
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ workflow }, { status: 201 });
}
