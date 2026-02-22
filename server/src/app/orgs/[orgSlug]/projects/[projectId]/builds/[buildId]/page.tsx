import { redirect, notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import {
  getOrgBySlug,
  getProjectById,
  getBuildById,
  getBuildRunLogs,
} from "@/lib/supabase/queries";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { CheckCircle2, XCircle, Clock, AlertCircle, GitBranch, Tag } from "lucide-react";
import { BuildLogViewer } from "./build-log-viewer";
import type { BuildStatus } from "@/lib/supabase/types";

function StatusIcon({ status }: { status: BuildStatus }) {
  if (status === "success") return <CheckCircle2 className="size-5 text-green-500" />;
  if (status === "failure") return <XCircle className="size-5 text-red-500" />;
  if (status === "in_progress") return <Clock className="size-5 text-yellow-500 animate-pulse" />;
  if (status === "cancelled") return <AlertCircle className="size-5 text-gray-400" />;
  return <Clock className="size-5 text-muted-foreground" />;
}

export default async function BuildDetailPage({
  params,
}: {
  params: Promise<{ orgSlug: string; projectId: string; buildId: string }>;
}) {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getClaims();
  if (error || !data?.claims) redirect("/auth/login");

  const { orgSlug, projectId, buildId } = await params;
  const [org, project, build] = await Promise.all([
    getOrgBySlug(supabase, orgSlug),
    getProjectById(supabase, projectId),
    getBuildById(supabase, buildId),
  ]);

  if (!org) redirect("/auth/login");
  if (!project || !build || build.project_id !== project.id) notFound();

  // Get logs for the latest run (SSR initial data)
  const initialLogs = build.latest_run_id
    ? await getBuildRunLogs(supabase, build.latest_run_id)
    : [];

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <StatusIcon status={build.status} />
        <div>
          <p className="text-sm text-muted-foreground">{project.name}</p>
          <h1 className="text-xl font-bold flex items-center gap-2">
            {build.branch
              ? (
              <>
                <GitBranch className="size-4" />
                {build.branch}
              </>
            ) : (build.tag_name ? (
              <>
                <Tag className="size-4" />
                {build.tag_name}
              </>
            ) : (
              `Build #${build.run_count}`
            ))}
          </h1>
        </div>
        <Badge variant="outline" className="ml-auto capitalize">
          {build.status}
        </Badge>
      </div>

      {/* Build metadata */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Details</CardTitle>
        </CardHeader>
        <CardContent>
          <dl className="grid grid-cols-2 gap-3 text-sm sm:grid-cols-3">
            <div>
              <dt className="text-muted-foreground text-xs">Repository</dt>
              <dd className="font-medium">{build.github_owner}/{build.github_repo}</dd>
            </div>
            {build.commit_sha && (
              <div>
                <dt className="text-muted-foreground text-xs">Commit</dt>
                <dd className="font-mono text-xs">{build.commit_sha.slice(0, 7)}</dd>
              </div>
            )}
            {build.github_event && (
              <div>
                <dt className="text-muted-foreground text-xs">Event</dt>
                <dd>{build.github_event}{build.github_action ? ` · ${build.github_action}` : ""}</dd>
              </div>
            )}
            {build.github_sender && (
              <div>
                <dt className="text-muted-foreground text-xs">Triggered by</dt>
                <dd>{build.github_sender}</dd>
              </div>
            )}
            <div>
              <dt className="text-muted-foreground text-xs">Started</dt>
              <dd>{new Date(build.created_at).toLocaleString()}</dd>
            </div>
            {build.run_count > 0 && (
              <div>
                <dt className="text-muted-foreground text-xs">Attempt</dt>
                <dd>#{build.run_count}</dd>
              </div>
            )}
          </dl>
        </CardContent>
      </Card>

      {/* Live logs */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Build Logs</CardTitle>
        </CardHeader>
        <CardContent>
          <BuildLogViewer
            buildId={build.id}
            buildRunId={build.latest_run_id ?? null}
            initialStatus={build.status}
            initialLogs={initialLogs}
          />
        </CardContent>
      </Card>
    </div>
  );
}
