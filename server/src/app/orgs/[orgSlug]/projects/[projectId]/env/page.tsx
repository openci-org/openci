import { redirect, notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getOrgBySlug, getProjectById, getProjectEnvVars } from "@/lib/supabase/queries";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Key, Lock, RefreshCw, Plus } from "lucide-react";

export default async function EnvVarsPage({
  params,
}: {
  params: Promise<{ orgSlug: string; projectId: string }>;
}) {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getClaims();
  if (error || !data?.claims) redirect("/auth/login");

  const { orgSlug, projectId } = await params;
  const [org, project] = await Promise.all([
    getOrgBySlug(supabase, orgSlug),
    getProjectById(supabase, projectId),
  ]);

  if (!org) redirect("/auth/login");
  if (!project) notFound();

  const envVars = await getProjectEnvVars(supabase, projectId);

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-muted-foreground">{project.name}</p>
          <h1 className="text-2xl font-bold">Environment Variables</h1>
        </div>
        <Button size="sm">
          <Plus className="size-4" />
          Add Variable
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Variables</CardTitle>
          <CardDescription>
            Environment variables are injected into each build. Secrets are stored in GCP Secret Manager.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {envVars.length === 0 ? (
            <p className="text-sm text-muted-foreground py-6 text-center">
              No environment variables defined yet.
            </p>
          ) : (
            <div className="divide-y">
              {envVars.map((ev) => (
                <div key={ev.id} className="flex items-center gap-3 py-3">
                  <div className="flex size-7 items-center justify-center rounded bg-muted shrink-0">
                    {ev.is_secret ? (
                      <Lock className="size-3.5 text-muted-foreground" />
                    ) : (
                      <Key className="size-3.5 text-muted-foreground" />
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="text-sm font-mono font-medium">{ev.key}</div>
                    <div className="text-xs text-muted-foreground flex items-center gap-2 mt-0.5">
                      {ev.is_secret && <span>Secret</span>}
                      {ev.auto_increment && (
                        <span className="flex items-center gap-1">
                          <RefreshCw className="size-3" />
                          Auto-increment
                        </span>
                      )}
                      <span>Updated {new Date(ev.updated_at).toLocaleDateString()}</span>
                    </div>
                  </div>
                  <div className="flex items-center gap-2 shrink-0">
                    {ev.is_secret ? (
                      <span className="text-xs font-mono text-muted-foreground">••••••••</span>
                    ) : (
                      <span className="text-xs font-mono text-muted-foreground truncate max-w-32">
                        {ev.value ?? "—"}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
