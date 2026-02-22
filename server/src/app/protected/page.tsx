import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getTranslations } from "next-intl/server";
import { CURRENT_ORG, MOCK_PROJECTS } from "@/lib/mock-data";
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
  Package,
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

const MOCK_ORG_STATS = [
  { label: "Total Builds", value: "342", icon: Hammer, trend: "+28 this week" },
  { label: "Active Workflows", value: "7", icon: GitBranch, trend: "Across all projects" },
  { label: "Releases", value: "24", icon: Package, trend: "Last: Project A v2.4.1" },
  { label: "Success Rate", value: "94%", icon: TrendingUp, trend: "+2% vs last week" },
];

const MOCK_PROJECT_STATUS = [
  {
    id: "project-a",
    name: "Project A",
    lastBuild: { status: "success" as const, branch: "main", ago: "2 hours ago", platform: "iOS" },
    builds: 128,
    workflows: 3,
  },
  {
    id: "project-b",
    name: "Project B",
    lastBuild: { status: "running" as const, branch: "develop", ago: "Just now", platform: "Android" },
    builds: 214,
    workflows: 4,
  },
];

const MOCK_RECENT_ACTIVITY = [
  { id: "1", project: "Project A", event: "Build succeeded", branch: "main", platform: "iOS", ago: "2 hours ago", status: "success" as const },
  { id: "2", project: "Project A", event: "Build succeeded", branch: "main", platform: "Android", ago: "2 hours ago", status: "success" as const },
  { id: "3", project: "Project B", event: "Build started", branch: "develop", platform: "Android", ago: "Just now", status: "running" as const },
  { id: "4", project: "Project A", event: "Build failed", branch: "feature/auth", platform: "iOS", ago: "5 hours ago", status: "failed" as const },
  { id: "5", project: "Project B", event: "Release published", branch: "main", platform: "iOS", ago: "1 day ago", status: "success" as const },
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

export default async function ProtectedPage() {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getClaims();
  if (error || !data?.claims) redirect("/auth/login");

  const t = await getTranslations("nav");

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <div className="flex items-center gap-2 text-sm text-muted-foreground mb-1">
            <Building2 className="size-4" />
            <span>{CURRENT_ORG.name}</span>
          </div>
          <h1 className="text-2xl font-bold">{t("dashboard")}</h1>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" asChild>
            <Link href="/protected/teams">
              <UserPlus className="size-4" />
              Invite Member
            </Link>
          </Button>
          <Button size="sm">
            <Plus className="size-4" />
            New Project
          </Button>
        </div>
      </div>

      {/* Org Stats */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        {MOCK_ORG_STATS.map(({ label, value, icon: Icon, trend }) => (
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
        {/* Projects Overview */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Projects</CardTitle>
            <CardDescription>Status of all projects in {CURRENT_ORG.name}</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="divide-y">
              {MOCK_PROJECT_STATUS.map((project) => (
                <div key={project.id} className="flex items-center gap-3 py-3">
                  <StatusIcon status={project.lastBuild.status} />
                  <div className="flex-1 min-w-0">
                    <Link
                      href={`/protected/projects/${project.id}`}
                      className="font-medium text-sm hover:underline"
                    >
                      {project.name}
                    </Link>
                    <div className="flex items-center gap-2 mt-0.5">
                      <span className="text-xs text-muted-foreground">{project.lastBuild.branch}</span>
                      <Badge variant="outline" className="text-xs">{project.lastBuild.platform}</Badge>
                      <span className="text-xs text-muted-foreground">{project.lastBuild.ago}</span>
                    </div>
                  </div>
                  <div className="flex items-center gap-3 text-xs text-muted-foreground shrink-0">
                    <span className="flex items-center gap-1">
                      <Hammer className="size-3" />{project.builds}
                    </span>
                    <span className="flex items-center gap-1">
                      <GitBranch className="size-3" />{project.workflows}
                    </span>
                    <StatusBadge status={project.lastBuild.status} />
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Recent Activity */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <Activity className="size-4" />
              <CardTitle className="text-base">Recent Activity</CardTitle>
            </div>
            <CardDescription>Latest events across all projects</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="divide-y">
              {MOCK_RECENT_ACTIVITY.map((item) => (
                <div key={item.id} className="flex items-center gap-3 py-3 text-sm">
                  <StatusIcon status={item.status} />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-1.5">
                      <span className="font-medium">{item.project}</span>
                      <span className="text-muted-foreground">·</span>
                      <span className="text-muted-foreground truncate">{item.event}</span>
                    </div>
                    <div className="flex items-center gap-2 mt-0.5">
                      <span className="text-xs text-muted-foreground">{item.branch}</span>
                      <Badge variant="outline" className="text-xs">{item.platform}</Badge>
                    </div>
                  </div>
                  <span className="text-xs text-muted-foreground shrink-0">{item.ago}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
