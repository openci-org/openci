import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { getOrgBySlug } from "@/lib/supabase/queries";
import type { OrgRole } from "@/lib/supabase/types";

// POST /api/orgs/[orgSlug]/invitations — invite a member by email
export async function POST(
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

  if (org.role !== "owner" && org.role !== "admin") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  let body: { email?: string; role?: OrgRole };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const email = body.email?.trim().toLowerCase();
  const role: OrgRole = body.role ?? "member";

  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return NextResponse.json({ error: "Valid email is required" }, { status: 400 });
  }

  if (!["owner", "admin", "member"].includes(role)) {
    return NextResponse.json({ error: "Invalid role" }, { status: 400 });
  }

  // Get the current user's ID for invited_by
  const userId = authData.claims.sub as string;

  const { data: invitation, error } = await supabase
    .from("org_invitations")
    .insert({
      org_id: org.id,
      invited_by: userId,
      email,
      role,
    })
    .select("id, email, role, expires_at")
    .single();

  if (error) {
    if (error.message.includes("duplicate") || error.message.includes("unique")) {
      return NextResponse.json({ error: "already_invited" }, { status: 409 });
    }
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  // TODO: send invitation email via Supabase Auth inviteUserByEmail or email service
  // For now, return the invitation token so it can be shared manually

  return NextResponse.json({ invitation }, { status: 201 });
}
