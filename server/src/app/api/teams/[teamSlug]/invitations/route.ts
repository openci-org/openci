import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { getTeamBySlug } from "@/lib/supabase/queries";
import { sendEmail } from "@/lib/email/resend";
import { buildInvitationEmail } from "@/lib/email/templates/invitation";
import type { OrgRole } from "@/lib/supabase/types";

// POST /api/orgs/[teamSlug]/invitations — invite a member by email
export async function POST(
  request: Request,
  { params }: { params: Promise<{ teamSlug: string }> }
) {
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

  const userId = authData.claims.sub as string;

  const { data: invitation, error } = await supabase
    .from("team_invitations")
    .insert({
      team_id: org.id,
      invited_by: userId,
      email,
      role,
    })
    .select("id, email, role, expires_at, token")
    .single();

  if (error) {
    if (error.message.includes("duplicate") || error.message.includes("unique")) {
      return NextResponse.json({ error: "already_invited" }, { status: 409 });
    }
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  const appUrl = process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000";
  const inviteLink = `${appUrl}/auth/accept-invite?token=${invitation.token}`;

  const { subject, html } = buildInvitationEmail({
    orgName: org.name,
    role,
    inviteLink,
  });

  try {
    await sendEmail({ to: email, subject, html });
  } catch (emailError) {
    console.error("Failed to send invitation email:", emailError);
  }

  const { token: _token, ...invitationWithoutToken } = invitation;
  return NextResponse.json({ invitation: invitationWithoutToken, inviteLink }, { status: 201 });
}
