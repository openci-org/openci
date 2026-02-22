import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getTranslations } from "next-intl/server";
import { MOCK_PROJECTS, CURRENT_ORG } from "@/lib/mock-data";
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

type Framework = "Swift" | "Kotlin" | "React Native" | "Flutter";

const FRAMEWORK_COLORS: Record<Framework, string> = {
  Swift: "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200",
  Kotlin: "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200",
  "React Native": "bg-sky-100 text-sky-800 dark:bg-sky-900 dark:text-sky-200",
  Flutter: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200",
};

const MOCK_PROJECT_DETAILS = [
  {
    id: "project-a",
    name: "Project A",
    description: "Native iOS app built with Swift. Targets iPhone and iPad.",
    lastBuild: { status: "success" as const, branch: "main", platform: "iOS", ago: "2 hours ago" },
    stats: { builds: 128, workflows: 3, releases: 8 },
    platforms: ["iOS"],
    framework: "Swift" as Framework,
  },
  {
    id: "project-b",
    name: "Project B",
    description: "Native Android app built with Kotlin. Targets phones and tablets.",
    lastBuild: { status: "running" as const, branch: "develop", platform: "Android", ago: "Just now" },
    stats: { builds: 214, workflows: 4, releases: 16 },
    platforms: ["Android"],
    framework: "Kotlin" as Framework,
  },
  {
    id: "project-c",
    name: "Project C",
    description: "Cross-platform app using React Native for iOS and Android.",
    lastBuild: { status: "failed" as const, branch: "feature/auth", platform: "iOS", ago: "5 hours ago" },
    stats: { builds: 76, workflows: 2, releases: 4 },
    platforms: ["iOS", "Android"],
    framework: "React Native" as Framework,
  },
  {
    id: "project-d",
    name: "Project D",
    description: "Cross-platform app using Flutter targeting iOS and Android.",
    lastBuild: { status: "success" as const, branch: "main", platform: "Android", ago: "1 day ago" },
    stats: { builds: 53, workflows: 2, releases: 3 },
    platforms: ["iOS", "Android"],
    framework: "Flutter" as Framework,
  },
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

export default async function ProjectsPage() {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getClaims();
  if (error || !data?.claims) redirect("/auth/login");
  const t = await getTranslations("nav");

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-muted-foreground">{CURRENT_ORG.name}</p>
          <h1 className="text-2xl font-bold">{t("projects")}</h1>
        </div>
        <Button size="sm">
          <Plus className="size-4" />
          New Project
        </Button>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {MOCK_PROJECT_DETAILS.map((project) => (
          <Card key={project.id} className="flex flex-col hover:shadow-md transition-shadow">
            <CardHeader className="pb-3">
              <div className="flex items-start justify-between gap-2">
                <div className="flex-1 min-w-0">
                  <CardTitle className="text-base truncate">{project.name}</CardTitle>
                  <CardDescription className="mt-1 text-xs line-clamp-2">
                    {project.description}
                  </CardDescription>
                </div>
                <StatusBadge status={project.lastBuild.status} />
              </div>
              <div className="flex flex-wrap gap-1 mt-2">
                <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${FRAMEWORK_COLORS[project.framework]}`}>
                  {project.framework}
                </span>
                {project.platforms.map((p) => (
                  <Badge key={p} variant="secondary" className="text-xs">{p}</Badge>
                ))}
              </div>
            </CardHeader>

            <CardContent className="flex flex-col gap-4 flex-1">
              {/* Last build */}
              <div className="flex items-center gap-2 text-sm bg-muted/50 rounded-md px-3 py-2">
                <StatusIcon status={project.lastBuild.status} />
                <span className="text-muted-foreground truncate">
                  {project.lastBuild.branch}
                </span>
                <Badge variant="outline" className="text-xs shrink-0">
                  {project.lastBuild.platform}
                </Badge>
                <span className="text-xs text-muted-foreground ml-auto shrink-0">
                  {project.lastBuild.ago}
                </span>
              </div>

              {/* Stats */}
              <div className="grid grid-cols-3 gap-2 text-center">
                <div>
                  <div className="flex items-center justify-center gap-1 text-muted-foreground mb-0.5">
                    <Hammer className="size-3" />
                  </div>
                  <div className="text-sm font-semibold">{project.stats.builds}</div>
                  <div className="text-xs text-muted-foreground">{t("builds")}</div>
                </div>
                <div>
                  <div className="flex items-center justify-center gap-1 text-muted-foreground mb-0.5">
                    <GitBranch className="size-3" />
                  </div>
                  <div className="text-sm font-semibold">{project.stats.workflows}</div>
                  <div className="text-xs text-muted-foreground">{t("workflow")}</div>
                </div>
                <div>
                  <div className="flex items-center justify-center gap-1 text-muted-foreground mb-0.5">
                    <Package className="size-3" />
                  </div>
                  <div className="text-sm font-semibold">{project.stats.releases}</div>
                  <div className="text-xs text-muted-foreground">{t("releases")}</div>
                </div>
              </div>

              {/* Actions */}
              <div className="flex gap-2 mt-auto">
                <Button variant="outline" size="sm" className="flex-1" asChild>
                  <Link href={`/protected/projects/${project.id}/settings`}>
                    <Pencil className="size-4" />
                    Edit
                  </Link>
                </Button>
                <Button size="sm" className="flex-1" asChild>
                  <Link href={`/protected/projects/${project.id}`}>
                    Open
                    <ArrowRight className="size-4" />
                  </Link>
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
