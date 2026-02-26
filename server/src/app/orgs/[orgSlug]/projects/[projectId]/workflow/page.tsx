import { redirect, notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getOrgBySlug, getOrgWorkflows } from "@/lib/supabase/queries";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { GitBranch, CheckCircle2, XCircle, Clock } from "lucide-react";
import Link from "next/link";
import type { BuildStatus } from "@/lib/supabase/types";
import { CreateWorkflowDialog } from "@/components/create-workflow-dialog";

function StatusIcon({ status }: { status: BuildStatus | null }) {
  if (status === "success") return <CheckCircle2 className="size-4 text-green-500 shrink-0" />;
  if (status === "failure") return <XCircle className="size-4 text-red-500 shrink-0" />;
  if (status === "in_progress") return <Clock className="size-4 text-yellow-500 animate-pulse shrink-0" />;
  return <Clock className="size-4 text-muted-foreground shrink-0" />;
}

function timeAgo(dateStr: string | null): string {
  if (!dateStr) return "Never";
  const diff = Date.now() - new Date(dateStr).getTime();
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return "Just now";
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
}

export default async function WorkflowPage({
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

  const workflows = await getOrgWorkflows(supabase, org.id);

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-muted-foreground">{org.name}</p>
          <h1 className="text-2xl font-bold">Workflows</h1>
        </div>
        <CreateWorkflowDialog orgSlug={orgSlug} projectId={projectId} />
      </div>

      {workflows.length === 0 ? (
        <Card>
          <CardContent className="text-center py-12">
            <GitBranch className="size-8 text-muted-foreground mx-auto mb-3" />
            <p className="text-sm text-muted-foreground mb-3">
              No workflows defined yet. Create a workflow to automate your builds.
            </p>
            <CreateWorkflowDialog orgSlug={orgSlug} projectId={projectId} label="Create Workflow" />
          </CardContent>
        </Card>
      ) : (
        <div className="flex flex-col gap-4">
          {workflows.map((workflow) => (
            <Card key={workflow.id}>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <StatusIcon status={workflow.last_build?.status ?? null} />
                    <CardTitle className="text-base">{workflow.name}</CardTitle>
                    {!workflow.is_active && (
                      <span className="text-xs bg-muted px-1.5 py-0.5 rounded text-muted-foreground">
                        Disabled
                      </span>
                    )}
                  </div>
                  <Button variant="outline" size="sm" asChild>
                    <Link href={`/orgs/${orgSlug}/projects/${projectId}/workflow/${workflow.id}`}>
                      Edit YAML
                    </Link>
                  </Button>
                </div>
                <CardDescription>
                  Last run: {timeAgo(workflow.last_build?.created_at ?? null)}
                </CardDescription>
              </CardHeader>
              <CardContent>
                {/* Trigger summary */}
                <div className="flex flex-wrap gap-2 mb-3">
                  {workflow.workflow_triggers.map((trigger) => (
                    <span
                      key={trigger.id}
                      className="inline-flex items-center gap-1 rounded-full bg-muted px-2.5 py-0.5 text-xs"
                    >
                      <GitBranch className="size-3" />
                      {trigger.trigger_type}
                      {trigger.branch_pattern && `:${trigger.branch_pattern}`}
                    </span>
                  ))}
                  {workflow.workflow_triggers.length === 0 && (
                    <span className="text-xs text-muted-foreground">No triggers configured</span>
                  )}
                </div>
                {/* YAML preview */}
                {workflow.yaml_definition && (
                  <pre className="text-xs bg-muted rounded p-3 overflow-x-auto max-h-32 text-muted-foreground">
                    {workflow.yaml_definition.slice(0, 300)}
                    {workflow.yaml_definition.length > 300 && "..."}
                  </pre>
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
