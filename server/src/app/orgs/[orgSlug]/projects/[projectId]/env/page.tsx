import { redirect, notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getOrgBySlug, getProjectById, getProjectEnvVars } from "@/lib/supabase/queries";
import { EnvVarManager } from "@/components/env-var-manager";

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
      <div>
        <p className="text-sm text-muted-foreground">{project.name}</p>
        <h1 className="text-2xl font-bold">Environment Variables</h1>
      </div>

      <EnvVarManager
        orgSlug={orgSlug}
        projectId={projectId}
        envVars={envVars}
      />
    </div>
  );
}
