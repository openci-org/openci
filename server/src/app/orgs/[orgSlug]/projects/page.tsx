import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getTranslations } from "next-intl/server";
import { getOrgBySlug, getOrgProjects } from "@/lib/supabase/queries";
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
  CheckCircle2,
  XCircle,
  Clock,
  Hammer,
  GitBranch,
  Package,
  Plus,
  ArrowRight,
  Pencil,
} from "lucide-react";
import Link from "next/link";
import type { BuildStatus } from "@/lib/supabase/types";

const FRAMEWORK_COLORS: Record<string, string> = {
  Swift: "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200",
  Kotlin: "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200",
  "React Native": "bg-sky-100 text-sky-800 dark:bg-sky-900 dark:text-sky-200",
  Flutter: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200",
};

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

export default async function ProjectsPage({
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

  const projects = await getOrgProjects(supabase, org.id);

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-muted-foreground">{org.name}</p>
          <h1 className="text-2xl font-bold">{t("projects")}</h1>
        </div>
        <Button size="sm" asChild>
          <Link href={`/orgs/${orgSlug}/projects/new`}>
            <Plus className="size-4" />
            New Project
          </Link>
        </Button>
      </div>

      {projects.length === 0 ? (
        <div className="text-center py-16 text-muted-foreground">
          <p className="text-sm">No projects yet.</p>
          <Button size="sm" className="mt-3" asChild>
            <Link href={`/orgs/${orgSlug}/projects/new`}>
              <Plus className="size-4" />
              Create your first project
            </Link>
          </Button>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {projects.map((project) => (
            <Card key={project.id} className="flex flex-col hover:shadow-md transition-shadow">
              <CardHeader className="pb-3">
                <div className="flex items-start justify-between gap-2">
                  <div className="flex-1 min-w-0">
                    <CardTitle className="text-base truncate">{project.name}</CardTitle>
                    {project.description && (
                      <CardDescription className="mt-1 text-xs line-clamp-2">
                        {project.description}
                      </CardDescription>
                    )}
                  </div>
                  <StatusBadge status={project.last_build?.status ?? null} />
                </div>
                <div className="flex flex-wrap gap-1 mt-2">
                  {project.framework && (
                    <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${FRAMEWORK_COLORS[project.framework] ?? "bg-gray-100 text-gray-800"}`}>
                      {project.framework}
                    </span>
                  )}
                  {project.platforms.map((p) => (
                    <Badge key={p} variant="secondary" className="text-xs">{p}</Badge>
                  ))}
                </div>
              </CardHeader>

              <CardContent className="flex flex-col gap-4 flex-1">
                {/* Last build */}
                <div className="flex items-center gap-2 text-sm bg-muted/50 rounded-md px-3 py-2">
                  <StatusIcon status={project.last_build?.status ?? null} />
                  {project.last_build?.branch ? (
                    <span className="text-muted-foreground truncate">{project.last_build.branch}</span>
                  ) : (
                    <span className="text-muted-foreground truncate">No builds yet</span>
                  )}
                  <span className="text-xs text-muted-foreground ml-auto shrink-0">
                    {timeAgo(project.last_build?.created_at ?? null)}
                  </span>
                </div>

                {/* Stats */}
                <div className="grid grid-cols-3 gap-2 text-center">
                  <div>
                    <div className="flex items-center justify-center gap-1 text-muted-foreground mb-0.5">
                      <Hammer className="size-3" />
                    </div>
                    <div className="text-sm font-semibold">{project.build_count}</div>
                    <div className="text-xs text-muted-foreground">{t("builds")}</div>
                  </div>
                  <div>
                    <div className="flex items-center justify-center gap-1 text-muted-foreground mb-0.5">
                      <GitBranch className="size-3" />
                    </div>
                    <div className="text-sm font-semibold">{project.workflow_count}</div>
                    <div className="text-xs text-muted-foreground">{t("workflow")}</div>
                  </div>
                  <div>
                    <div className="flex items-center justify-center gap-1 text-muted-foreground mb-0.5">
                      <Package className="size-3" />
                    </div>
                    <div className="text-sm font-semibold">—</div>
                    <div className="text-xs text-muted-foreground">{t("releases")}</div>
                  </div>
                </div>

                {/* Actions */}
                <div className="flex gap-2 mt-auto">
                  <Button variant="outline" size="sm" className="flex-1" asChild>
                    <Link href={`/orgs/${orgSlug}/projects/${project.id}/settings`}>
                      <Pencil className="size-4" />
                      Edit
                    </Link>
                  </Button>
                  <Button size="sm" className="flex-1" asChild>
                    <Link href={`/orgs/${orgSlug}/projects/${project.id}`}>
                      Open
                      <ArrowRight className="size-4" />
                    </Link>
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
