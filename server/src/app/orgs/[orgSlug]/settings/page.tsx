import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getOrgBySlug } from "@/lib/supabase/queries";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { OrgNameForm } from "@/components/org-name-form";

export default async function OrgSettingsPage({
  params,
}: {
  params: Promise<{ orgSlug: string }>;
}) {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getClaims();
  if (error || !data?.claims) redirect("/auth/login");

  const { orgSlug } = await params;
  const org = await getOrgBySlug(supabase, orgSlug);
  if (!org) redirect("/auth/login");

  const isOwner = org.role === "owner";

  return (
    <div className="flex flex-col gap-6">
      <div>
        <p className="text-sm text-muted-foreground">{org.name}</p>
        <h1 className="text-2xl font-bold">Settings</h1>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Organization Details</CardTitle>
          <CardDescription>
            {isOwner
              ? "Update your organization name."
              : "Organization information."}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {isOwner ? (
            <OrgNameForm orgSlug={orgSlug} currentName={org.name} />
          ) : (
            <div className="space-y-3 text-sm">
              <div>
                <span className="text-muted-foreground">Name: </span>
                <span className="font-medium">{org.name}</span>
              </div>
            </div>
          )}
          <div className="space-y-3 text-sm pt-2">
            <div>
              <span className="text-muted-foreground">Slug: </span>
              <span className="font-mono text-xs bg-muted px-1.5 py-0.5 rounded">{org.slug}</span>
            </div>
            <div>
              <span className="text-muted-foreground">Your role: </span>
              <span className="font-medium">{org.role}</span>
            </div>
            <div>
              <span className="text-muted-foreground">Billing: </span>
              <span className="font-medium">{org.billing_enabled ? "Enabled" : "Free tier"}</span>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
