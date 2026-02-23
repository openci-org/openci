import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getOrgBySlug, getOrgMembers } from "@/lib/supabase/queries";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { CircleUserRound, Shield, Star, Users } from "lucide-react";
import Link from "next/link";
import type { OrgRole } from "@/lib/supabase/types";

const ROLE_CONFIG: Record<
  OrgRole,
  { label: string; description: string; icon: React.ReactNode; color: string }
> = {
  owner: {
    label: "Owners",
    description: "Full control over the organization including billing and deletion.",
    icon: <Star className="size-4" />,
    color: "text-purple-600 dark:text-purple-400",
  },
  admin: {
    label: "Admins",
    description: "Can manage members, projects, and integrations.",
    icon: <Shield className="size-4" />,
    color: "text-blue-600 dark:text-blue-400",
  },
  member: {
    label: "Members",
    description: "Can view and work with projects they have access to.",
    icon: <Users className="size-4" />,
    color: "text-gray-600 dark:text-gray-400",
  },
};

export default async function TeamsPage({
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

  const members = await getOrgMembers(supabase, org.id);

  const grouped = {
    owner: members.filter((m) => m.role === "owner"),
    admin: members.filter((m) => m.role === "admin"),
    member: members.filter((m) => m.role === "member"),
  } satisfies Record<OrgRole, typeof members>;

  const canManage = org.role === "owner" || org.role === "admin";

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-muted-foreground">{org.name}</p>
          <h1 className="text-2xl font-bold">Teams</h1>
        </div>
        {canManage && (
          <Link
            href={`/orgs/${orgSlug}/members`}
            className="text-sm text-muted-foreground underline-offset-4 hover:underline"
          >
            Manage members →
          </Link>
        )}
      </div>

      <div className="grid gap-4">
        {(["owner", "admin", "member"] as const).map((role) => {
          const config = ROLE_CONFIG[role];
          const roleMembers = grouped[role];

          return (
            <Card key={role}>
              <CardHeader className="pb-3">
                <CardTitle className={`text-base flex items-center gap-2 ${config.color}`}>
                  {config.icon}
                  {config.label}
                  <span className="ml-auto text-xs font-normal text-muted-foreground">
                    {roleMembers.length} {roleMembers.length === 1 ? "person" : "people"}
                  </span>
                </CardTitle>
                <CardDescription>{config.description}</CardDescription>
              </CardHeader>
              <CardContent>
                {roleMembers.length === 0 ? (
                  <p className="text-sm text-muted-foreground">No {config.label.toLowerCase()}.</p>
                ) : (
                  <div className="flex flex-wrap gap-3">
                    {roleMembers.map((member) => (
                      <div
                        key={member.id}
                        className="flex items-center gap-2 rounded-lg border px-3 py-2 text-sm"
                      >
                        <div className="flex size-6 items-center justify-center rounded-full bg-muted">
                          <CircleUserRound className="size-3.5 text-muted-foreground" />
                        </div>
                        <span className="font-medium">
                          {member.profile?.full_name ?? member.user_id.slice(0, 8)}
                        </span>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          );
        })}
      </div>
    </div>
  );
}
