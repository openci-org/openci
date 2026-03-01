import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getTranslations } from "next-intl/server";
import { MOCK_PROJECTS } from "@/lib/mock-data";
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

const MOCK_PROJECT_STATS = [
  { label: "Total Builds", value: "128", icon: Hammer, trend: "+12 this week" },
  { label: "Success Rate", value: "91%", icon: TrendingUp, trend: "-3% vs last week" },
  { label: "Active Workflows", value: "3", icon: GitBranch, trend: "Across branches" },
  { label: "Releases", value: "8", icon: Package, trend: "Last: v2.4.1" },
];

const MOCK_RECENT_BUILDS = [
  { id: "build-1", branch: "main", platform: "iOS", status: "success" as const, duration: "4m 32s", ago: "2 hours ago", commit: "fix: login crash" },
  { id: "build-2", branch: "main", platform: "Android", status: "success" as const, duration: "3m 18s", ago: "2 hours ago", commit: "fix: login crash" },
  { id: "build-3", branch: "feature/auth", platform: "iOS", status: "failed" as const, duration: "1m 52s", ago: "5 hours ago", commit: "feat: OAuth flow" },
  { id: "build-4", branch: "develop", platform: "Android", status: "running" as const, duration: "—", ago: "Just now", commit: "chore: deps update" },
  { id: "build-5", branch: "develop", platform: "iOS", status: "success" as const, duration: "4m 01s", ago: "1 day ago", commit: "refactor: network layer" },
];

const MOCK_WORKFLOWS = [
  { id: "wf-1", name: "CI — Pull Request", trigger: "On PR", lastRun: "2 hours ago", status: "success" as const },
  { id: "wf-2", name: "CD — Production", trigger: "On main push", lastRun: "2 hours ago", status: "success" as const },
  { id: "wf-3", name: "Nightly Build", trigger: "Scheduled 02:00", lastRun: "6 hours ago", status: "failed" as const },
];

function StatusIcon({ status }: { status: "success" | "failed" | "running" }) {
  if (status === "success") return <CheckCircle2 className="size-4 text-green-500 shrink-0" />;
  if (status === "failed") return <XCircle className="size-4 text-red-500 shrink-0" />;
  return <Clock className="size-4 text-yellow-500 animate-pulse shrink-0" />;
}

function StatusBadge({ status }: { status: "success" | "failed" | "running" }) {
  const variants = {
    success: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200",
    failed: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200",
    running: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200",
  };
  return (
    <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${variants[status]}`}>
      {status}
    </span>
  );
}

export default async function ProjectOverviewPage({
  params,
}: {
  params: Promise<{ projectId: string }>;
}) {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getClaims();
  if (error || !data?.claims) redirect("/auth/login");

  const { projectId } = await params;
  const t = await getTranslations("nav");

  const project = MOCK_PROJECTS.find((p) => p.id === projectId) ?? {
    id: projectId,
    name: projectId,
    orgId: "",
  };

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex items-center gap-2 mb-2">
        <FolderOpen className="size-5" />
        <h1 className="text-2xl font-bold">{project.name}</h1>
        <span className="text-muted-foreground text-sm">/ {t("overview")}</span>
      </div>

      {/* Project Stats */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        {MOCK_PROJECT_STATS.map(({ label, value, icon: Icon, trend }) => (
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
            <div className="divide-y">
              {MOCK_RECENT_BUILDS.map((build) => (
                <div key={build.id} className="flex items-center gap-3 py-3 text-sm">
                  <StatusIcon status={build.status} />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-medium truncate">{build.branch}</span>
                      <Badge variant="outline" className="text-xs shrink-0">{build.platform}</Badge>
                    </div>
                    <div className="text-xs text-muted-foreground mt-0.5 truncate">
                      {build.commit} · {build.ago} · {build.duration}
                    </div>
                  </div>
                  <StatusBadge status={build.status} />
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Workflows */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Workflows</CardTitle>
            <CardDescription>Defined workflows and last run status</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="divide-y">
              {MOCK_WORKFLOWS.map((wf) => (
                <div key={wf.id} className="flex items-center gap-3 py-3 text-sm">
                  <StatusIcon status={wf.status} />
                  <div className="flex-1 min-w-0">
                    <div className="font-medium">{wf.name}</div>
                    <div className="text-xs text-muted-foreground mt-0.5">
                      {wf.trigger} · Last run: {wf.lastRun}
                    </div>
                  </div>
                  <StatusBadge status={wf.status} />
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
