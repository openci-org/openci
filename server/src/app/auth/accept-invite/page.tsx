import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { createClient as createAdminClient } from "@supabase/supabase-js";

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY ?? "";

export default async function AcceptInvitePage({
  searchParams,
}: {
  searchParams: Promise<{ token?: string }>;
}) {
  const { token } = await searchParams;

  if (!token) {
    redirect("/auth/error?error=Missing+invitation+token");
  }

  const supabase = await createClient();
  const { data: authData } = await supabase.auth.getClaims();

  if (!authData?.claims) {
    // Not logged in — redirect to login with the invite URL preserved
    redirect(`/auth/login?next=/auth/accept-invite?token=${token}`);
  }

  const userId = authData.claims.sub as string;
  const userEmail = authData.claims.email as string | undefined;

  // Look up the invitation by token using admin client (bypasses RLS for token lookup)
  const admin = createAdminClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  const { data: invitation, error: invError } = await admin
    .from("org_invitations")
    .select("id, org_id, email, role, status, expires_at")
    .eq("token", token)
    .single();

  if (invError || !invitation) {
    redirect("/auth/error?error=Invalid+or+expired+invitation");
  }

  if (invitation.status !== "pending") {
    redirect("/auth/error?error=Invitation+already+used+or+cancelled");
  }

  if (new Date(invitation.expires_at) < new Date()) {
    await admin
      .from("org_invitations")
      .update({ status: "expired" })
      .eq("id", invitation.id);
    redirect("/auth/error?error=Invitation+has+expired");
  }

  // Verify email matches (case-insensitive)
  if (userEmail && invitation.email !== userEmail.toLowerCase()) {
    redirect("/auth/error?error=Invitation+was+sent+to+a+different+email+address");
  }

  // Check if already a member
  const { data: existingMember } = await admin
    .from("org_members")
    .select("id")
    .eq("org_id", invitation.org_id)
    .eq("user_id", userId)
    .maybeSingle();

  if (!existingMember) {
    const { error: memberError } = await admin.from("org_members").insert({
      org_id: invitation.org_id,
      user_id: userId,
      role: invitation.role,
    });

    if (memberError) {
      redirect("/auth/error?error=Failed+to+join+organization");
    }
  }

  // Mark invitation as accepted
  await admin
    .from("org_invitations")
    .update({ status: "accepted" })
    .eq("id", invitation.id);

  // Look up the org slug to redirect there
  const { data: org } = await admin
    .from("organizations")
    .select("slug")
    .eq("id", invitation.org_id)
    .single();

  if (org?.slug) {
    redirect(`/orgs/${org.slug}`);
  }

  redirect("/");
}
