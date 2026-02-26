import { redirect, notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getOrgBySlug, getOrgEnvVars } from "@/lib/supabase/queries";
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
  const org = await getOrgBySlug(supabase, orgSlug);

  if (!org) redirect("/auth/login");

  const envVars = await getOrgEnvVars(supabase, org.id);

  return (
    <div className="flex flex-col gap-6">
      <div>
        <p className="text-sm text-muted-foreground">{org.name}</p>
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
