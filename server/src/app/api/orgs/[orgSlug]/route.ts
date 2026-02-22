import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { getOrgBySlug } from "@/lib/supabase/queries";

// PATCH /api/orgs/[orgSlug] — update organization name (owners only)
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ orgSlug: string }> }
) {
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getClaims();
  if (authError || !authData?.claims) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { orgSlug } = await params;
  const org = await getOrgBySlug(supabase, orgSlug);
  if (!org) {
    return NextResponse.json({ error: "Organization not found" }, { status: 404 });
  }

  // Only owners can update organization details
  if (org.role !== "owner") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
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

  const { data: updated, error } = await supabase
    .from("organizations")
    .update({ name })
    .eq("id", org.id)
    .select("id, name, slug")
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ org: updated });
}
