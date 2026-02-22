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

  return (
    <div className="flex flex-col gap-6">
      <div>
        <p className="text-sm text-muted-foreground">{org.name}</p>
        <h1 className="text-2xl font-bold">Settings</h1>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Organization Details</CardTitle>
          <CardDescription>Manage your organization name and slug.</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-3 text-sm">
            <div>
              <span className="text-muted-foreground">Name: </span>
              <span className="font-medium">{org.name}</span>
            </div>
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
