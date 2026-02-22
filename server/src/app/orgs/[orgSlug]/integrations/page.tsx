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
import { Button } from "@/components/ui/button";
import { Github, Plug } from "lucide-react";

export default async function IntegrationsPage({
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

  const { data: integrations } = await supabase
    .from("integrations")
    .select("*")
    .eq("org_id", org.id);

  return (
    <div className="flex flex-col gap-6">
      <div>
        <p className="text-sm text-muted-foreground">{org.name}</p>
        <h1 className="text-2xl font-bold">Integrations</h1>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Github className="size-4" />
            GitHub App
          </CardTitle>
          <CardDescription>
            Connect your GitHub repositories to trigger workflows via webhooks.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {integrations && integrations.length > 0 ? (
            <div className="space-y-3">
              {integrations.map((integration) => (
                <div key={integration.id} className="flex items-center gap-3 p-3 border rounded-md">
                  <Github className="size-5 text-muted-foreground" />
                  <div className="flex-1 min-w-0">
                    <div className="text-sm font-medium">{integration.github_account ?? `Installation #${integration.installation_id}`}</div>
                    <div className="text-xs text-muted-foreground">GitHub App · ID {integration.installation_id}</div>
                  </div>
                  <div className="text-xs text-green-600 font-medium">Connected</div>
                </div>
              ))}
              <Button variant="outline" size="sm" className="w-full">
                <Plug className="size-4" />
                Add Another Account
              </Button>
            </div>
          ) : (
            <div className="text-center py-6">
              <p className="text-sm text-muted-foreground mb-3">
                No GitHub App installed yet. Install the OpenCI GitHub App to start triggering workflows.
              </p>
              <Button size="sm">
                <Github className="size-4" />
                Install GitHub App
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
