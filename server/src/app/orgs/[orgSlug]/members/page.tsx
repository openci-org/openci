import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getOrgBySlug, getOrgMembers, getOrgInvitations } from "@/lib/supabase/queries";
import { MembersClient } from "./MembersClient";

export default async function MembersPage({
  params,
}: {
  params: Promise<{ orgSlug: string }>;
}) {
  const supabase = await createClient();
  const { data: authData, error } = await supabase.auth.getClaims();
  if (error || !authData?.claims) redirect("/auth/login");

  const { orgSlug } = await params;
  const org = await getOrgBySlug(supabase, orgSlug);
  if (!org) redirect("/auth/login");

  const [members, invitations] = await Promise.all([
    getOrgMembers(supabase, org.id),
    getOrgInvitations(supabase, org.id),
  ]);

  const currentUserId = authData.claims.sub as string;

  return (
    <div className="flex flex-col gap-6">
      <div>
        <p className="text-sm text-muted-foreground">{org.name}</p>
        <h1 className="text-2xl font-bold">Members</h1>
      </div>

      <MembersClient
        orgSlug={orgSlug}
        currentUserId={currentUserId}
        orgRole={org.role}
        members={members}
        invitations={invitations}
      />
    </div>
  );
}
