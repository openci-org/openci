import { WorkflowEditor } from "@/components/workflow-editor";
import { getOrgBySlug, getWorkflowById } from "@/lib/supabase/queries";
import { createClient } from "@/lib/supabase/server";
import { ChevronLeft } from "lucide-react";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";

export default async function WorkflowDetailPage({
  params,
}: {
  params: Promise<{ orgSlug: string; projectId: string; workflowId: string }>;
}) {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getClaims();
  if (error || !data?.claims) redirect("/auth/login");

  const { orgSlug, projectId, workflowId } = await params;
  const org = await getOrgBySlug(supabase, orgSlug);

  if (!org) redirect("/auth/login");

  const workflow = await getWorkflowById(supabase, workflowId);
  if (!workflow || workflow.org_id !== org.id) notFound();

  return (
    <div className="flex flex-col gap-6">
      <div>
        <Link
          href={`/orgs/${orgSlug}/projects/${projectId}/workflow`}
          className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-2"
        >
          <ChevronLeft className="size-3.5" />
          Workflows
        </Link>
        <p className="text-sm text-muted-foreground">{org.name}</p>
        <h1 className="text-2xl font-bold">{workflow.name}</h1>
      </div>

      <WorkflowEditor orgSlug={orgSlug} projectId={projectId} workflow={workflow} />
    </div>
  );
}
