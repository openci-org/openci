import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { getOrgBySlug } from "@/lib/supabase/queries";

// DELETE /api/orgs/[orgSlug]/invitations/[invitationId] — cancel a pending invitation
export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ orgSlug: string; invitationId: string }> }
) {
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getClaims();
  if (authError || !authData?.claims) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { orgSlug, invitationId } = await params;
  const org = await getOrgBySlug(supabase, orgSlug);
  if (!org) {
    return NextResponse.json({ error: "Organization not found" }, { status: 404 });
  }

  if (org.role !== "owner" && org.role !== "admin") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { data: invitation, error: fetchError } = await supabase
    .from("org_invitations")
    .select("id, status")
    .eq("id", invitationId)
    .eq("org_id", org.id)
    .single();

  if (fetchError || !invitation) {
    return NextResponse.json({ error: "Invitation not found" }, { status: 404 });
  }

  if (invitation.status !== "pending") {
    return NextResponse.json(
      { error: "Only pending invitations can be cancelled" },
      { status: 409 }
    );
  }

  const { error } = await supabase
    .from("org_invitations")
    .update({ status: "cancelled" })
    .eq("id", invitationId);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ success: true });
}
