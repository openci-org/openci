import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getTranslations } from "next-intl/server";
import { getOrgBySlug, getOrgProjects, getOrgStats } from "@/lib/supabase/queries";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Hammer,
  GitBranch,
  CheckCircle2,
  XCircle,
  Clock,
  Building2,
  Plus,
  UserPlus,
  TrendingUp,
  Activity,
} from "lucide-react";
import Link from "next/link";
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

export default async function OrgDashboardPage({
  params,
}: {
  params: Promise<{ orgSlug: string }>;
}) {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getClaims();
  if (error || !data?.claims) redirect("/auth/login");

  const { orgSlug } = await params;
  const t = await getTranslations("nav");

  const org = await getOrgBySlug(supabase, orgSlug);
  if (!org) redirect("/auth/login");

  const [projects, stats] = await Promise.all([
    getOrgProjects(supabase, org.id),
    getOrgStats(supabase, org.id),
  ]);

  const successRate =
    stats.totalBuilds > 0
      ? Math.round((stats.successBuilds / stats.totalBuilds) * 100)
      : 0;

  const orgStats = [
    { label: "Total Builds", value: String(stats.totalBuilds), icon: Hammer, trend: "All time" },
    { label: "Active Workflows", value: String(stats.activeWorkflows), icon: GitBranch, trend: "Across all projects" },
    { label: "Projects", value: String(projects.length), icon: Building2, trend: "In this organization" },
    { label: "Success Rate", value: `${successRate}%`, icon: TrendingUp, trend: "All time" },
  ];

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <div className="flex items-center gap-2 text-sm text-muted-foreground mb-1">
            <Building2 className="size-4" />
            <span>{org.name}</span>
          </div>
          <h1 className="text-2xl font-bold">{t("dashboard")}</h1>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" asChild>
            <Link href={`/orgs/${orgSlug}/members`}>
              <UserPlus className="size-4" />
              Invite Member
            </Link>
          </Button>
          <Button size="sm" asChild>
            <Link href={`/orgs/${orgSlug}/projects/new`}>
              <Plus className="size-4" />
              New Project
            </Link>
          </Button>
        </div>
      </div>

      {/* Org Stats */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        {orgStats.map(({ label, value, icon: Icon, trend }) => (
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

      {/* Projects Overview */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Activity className="size-4" />
            <CardTitle className="text-base">Projects</CardTitle>
          </div>
          <CardDescription>Status of all projects in {org.name}</CardDescription>
        </CardHeader>
        <CardContent>
          {projects.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              <p className="text-sm">No projects yet.</p>
              <Button size="sm" className="mt-3" asChild>
                <Link href={`/orgs/${orgSlug}/projects/new`}>
                  <Plus className="size-4" />
                  Create your first project
                </Link>
              </Button>
            </div>
          ) : (
            <div className="divide-y">
              {projects.map((project) => (
                <div key={project.id} className="flex items-center gap-3 py-3">
                  <StatusIcon status={project.last_build?.status ?? null} />
                  <div className="flex-1 min-w-0">
                    <Link
                      href={`/orgs/${orgSlug}/projects/${project.id}`}
                      className="font-medium text-sm hover:underline"
                    >
                      {project.name}
                    </Link>
                    <div className="flex items-center gap-2 mt-0.5">
                      {project.last_build?.branch && (
                        <span className="text-xs text-muted-foreground">{project.last_build.branch}</span>
                      )}
                      {project.framework && (
                        <Badge variant="outline" className="text-xs">{project.framework}</Badge>
                      )}
                      <span className="text-xs text-muted-foreground">
                        {timeAgo(project.last_build?.created_at ?? null)}
                      </span>
                    </div>
                  </div>
                  <div className="flex items-center gap-3 text-xs text-muted-foreground shrink-0">
                    <span className="flex items-center gap-1">
                      <Hammer className="size-3" />{project.build_count}
                    </span>
                    <span className="flex items-center gap-1">
                      <GitBranch className="size-3" />{project.workflow_count}
                    </span>
                    <StatusBadge status={project.last_build?.status ?? null} />
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
