import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { getTeamBySlug } from "@/lib/supabase/queries";
import type { OrgRole } from "@/lib/supabase/types";

// DELETE /api/orgs/[teamSlug]/members/[memberId] — remove a member
export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ teamSlug: string; memberId: string }> }
) {
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getClaims();
  if (authError || !authData?.claims) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { teamSlug, memberId } = await params;
  const org = await getTeamBySlug(supabase, teamSlug);
  if (!org) {
    return NextResponse.json({ error: "Team not found" }, { status: 404 });
  }

  const userId = authData.claims.sub as string;

  // Fetch the target member to check they belong to this org
  const { data: member, error: fetchError } = await supabase
    .from("team_members")
    .select("id, user_id, role")
    .eq("id", memberId)
    .eq("team_id", org.id)
    .single();

  if (fetchError || !member) {
    return NextResponse.json({ error: "Member not found" }, { status: 404 });
  }

  // Only owners/admins can remove others; anyone can remove themselves
  const isSelf = member.user_id === userId;
  const canManage = org.role === "owner" || org.role === "admin";

  if (!isSelf && !canManage) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  // Cannot remove the last owner
  if (member.role === "owner") {
    const { count } = await supabase
      .from("team_members")
      .select("id", { count: "exact", head: true })
      .eq("team_id", org.id)
      .eq("role", "owner");

    if ((count ?? 0) <= 1) {
      return NextResponse.json(
        { error: "Cannot remove the last owner" },
        { status: 409 }
      );
    }
  }

  const { error } = await supabase
    .from("team_members")
    .delete()
    .eq("id", memberId);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ success: true });
}

// PATCH /api/orgs/[teamSlug]/members/[memberId] — change member role
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ teamSlug: string; memberId: string }> }
) {
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getClaims();
  if (authError || !authData?.claims) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { teamSlug, memberId } = await params;
  const org = await getTeamBySlug(supabase, teamSlug);
  if (!org) {
    return NextResponse.json({ error: "Team not found" }, { status: 404 });
  }

  // Only owners can change roles
  if (org.role !== "owner") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  let body: { role?: OrgRole };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const role = body.role;
  if (!role || !["owner", "admin", "member"].includes(role)) {
    return NextResponse.json({ error: "Valid role is required" }, { status: 400 });
  }

  // Fetch the target member
  const { data: member, error: fetchError } = await supabase
    .from("team_members")
    .select("id, role")
    .eq("id", memberId)
    .eq("team_id", org.id)
    .single();

  if (fetchError || !member) {
    return NextResponse.json({ error: "Member not found" }, { status: 404 });
  }

  // Prevent demoting the last owner
  if (member.role === "owner" && role !== "owner") {
    const { count } = await supabase
      .from("team_members")
      .select("id", { count: "exact", head: true })
      .eq("team_id", org.id)
      .eq("role", "owner");

    if ((count ?? 0) <= 1) {
      return NextResponse.json(
        { error: "Cannot demote the last owner" },
        { status: 409 }
      );
    }
  }

  const { data: updated, error } = await supabase
    .from("team_members")
    .update({ role })
    .eq("id", memberId)
    .select("id, role")
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ member: updated });
}
