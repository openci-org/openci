import { redirect, notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getTranslations } from "next-intl/server";
import {
  getOrgBySlug,
  getProjectById,
  getProjectBuilds,
  getProjectWorkflows,
} from "@/lib/supabase/queries";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  Hammer,
  GitBranch,
  Package,
  CheckCircle2,
  XCircle,
  Clock,
  TrendingUp,
  FolderOpen,
} from "lucide-react";
import type { BuildStatus } from "@/lib/supabase/types";

function StatusIcon({ status }: { status: BuildStatus | null }) {
  if (status === "success") return <CheckCircle2 className="size-4 text-green-500 shrink-0" />;
  if (status === "failure") return <XCircle className="size-4 text-red-500 shrink-0" />;
  if (status === "in_progress") return <Clock className="size-4 text-yellow-500 animate-pulse shrink-0" />;
  return <Clock className="size-4 text-muted-foreground shrink-0" />;
}

function StatusBadge({ status }: { status: BuildStatus | null }) {
  const variants: Record<string, string> = {
    success: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200",
    failure: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200",
    in_progress: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200",
    queued: "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200",
    cancelled: "bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400",
  };
  const label = status ?? "—";
  return (
    <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${variants[status ?? ""] ?? ""}`}>
      {label}
    </span>
  );
}

function timeAgo(dateStr: string | null): string {
  if (!dateStr) return "—";
  const diff = Date.now() - new Date(dateStr).getTime();
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return "Just now";
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
}

export default async function ProjectOverviewPage({
  params,
}: {
  params: Promise<{ orgSlug: string; projectId: string }>;
}) {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getClaims();
  if (error || !data?.claims) redirect("/auth/login");

  const { orgSlug, projectId } = await params;
  const navT = await getTranslations("nav");

  const [org, project] = await Promise.all([
    getOrgBySlug(supabase, orgSlug),
    getProjectById(supabase, projectId),
  ]);

  if (!org) redirect("/auth/login");
  if (!project) notFound();

  const [builds, workflows] = await Promise.all([
    getProjectBuilds(supabase, projectId, 5),
    getProjectWorkflows(supabase, projectId),
  ]);

  const successBuilds = builds.filter((b) => b.status === "success").length;
  const successRate =
    builds.length > 0 ? Math.round((successBuilds / builds.length) * 100) : 0;

  const projectStats = [
    { label: "Total Builds", value: String(builds.length), icon: Hammer, trend: "All time" },
    { label: "Success Rate", value: `${successRate}%`, icon: TrendingUp, trend: "Recent builds" },
    { label: "Active Workflows", value: String(workflows.filter((w) => w.is_active).length), icon: GitBranch, trend: "Across branches" },
    { label: "Releases", value: "—", icon: Package, trend: "Coming soon" },
  ];

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex items-center gap-2 mb-2">
        <FolderOpen className="size-5" />
        <h1 className="text-2xl font-bold">{project.name}</h1>
        <span className="text-muted-foreground text-sm">/ {navT("overview")}</span>
      </div>

      {/* Project Stats */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        {projectStats.map(({ label, value, icon: Icon, trend }) => (
          <Card key={label}>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">{label}</CardTitle>
              <Icon className="size-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{value}</div>
              <p className="text-xs text-muted-foreground mt-1">{trend}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Recent Builds */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Recent Builds</CardTitle>
            <CardDescription>Latest builds for {project.name}</CardDescription>
          </CardHeader>
          <CardContent>
            {builds.length === 0 ? (
              <p className="text-sm text-muted-foreground py-4 text-center">No builds yet.</p>
            ) : (
              <div className="divide-y">
                {builds.map((build) => (
                  <div key={build.id} className="flex items-center gap-3 py-3 text-sm">
                    <StatusIcon status={build.status} />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="font-medium truncate">
                          {build.branch ?? build.tag_name ?? build.commit_sha?.slice(0, 7) ?? "—"}
                        </span>
                        {build.github_repo && (
                          <Badge variant="outline" className="text-xs shrink-0">
                            {build.github_repo.split("/")[1]}
                          </Badge>
                        )}
                      </div>
                      <div className="text-xs text-muted-foreground mt-0.5">
                        {build.commit_sha?.slice(0, 7) ?? "—"} · {timeAgo(build.created_at)}
                      </div>
                    </div>
                    <StatusBadge status={build.status} />
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Workflows */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Workflows</CardTitle>
            <CardDescription>Defined workflows and last run status</CardDescription>
          </CardHeader>
          <CardContent>
            {workflows.length === 0 ? (
              <p className="text-sm text-muted-foreground py-4 text-center">No workflows defined yet.</p>
            ) : (
              <div className="divide-y">
                {workflows.map((wf) => (
                  <div key={wf.id} className="flex items-center gap-3 py-3 text-sm">
                    <StatusIcon status={wf.last_build?.status ?? null} />
                    <div className="flex-1 min-w-0">
                      <div className="font-medium">{wf.name}</div>
                      <div className="text-xs text-muted-foreground mt-0.5">
                        {wf.workflow_triggers.length > 0
                          ? wf.workflow_triggers.map((trigger) => `${trigger.trigger_type}${trigger.branch_pattern ? `:${trigger.branch_pattern}` : ""}`).join(", ")
                          : "No triggers"
                        } · Last run: {timeAgo(wf.last_build?.created_at ?? null)}
                      </div>
                    </div>
                    <StatusBadge status={wf.last_build?.status ?? null} />
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
