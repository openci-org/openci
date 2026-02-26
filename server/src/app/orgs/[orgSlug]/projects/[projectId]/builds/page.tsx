import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { getOrgBuilds, getOrgBySlug } from "@/lib/supabase/queries";
import { createClient } from "@/lib/supabase/server";
import type { BuildStatus } from "@/lib/supabase/types";
import { AlertCircle, CheckCircle2, Clock, XCircle } from "lucide-react";
import Link from "next/link";
import { redirect } from "next/navigation";

function StatusIcon({ status }: { status: BuildStatus }) {
  if (status === "success") return <CheckCircle2 className="size-4 text-green-500 shrink-0" />;
  if (status === "failure") return <XCircle className="size-4 text-red-500 shrink-0" />;
  if (status === "in_progress")
    return <Clock className="size-4 text-yellow-500 animate-pulse shrink-0" />;
  if (status === "cancelled") return <AlertCircle className="size-4 text-gray-400 shrink-0" />;
  return <Clock className="size-4 text-muted-foreground shrink-0" />;
}

function StatusBadge({ status }: { status: BuildStatus }) {
  const variants: Record<BuildStatus, string> = {
    success: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200",
    failure: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200",
    in_progress: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200",
    queued: "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200",
    cancelled: "bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400",
  };
  return (
    <span
      className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${variants[status]}`}
    >
      {status}
    </span>
  );
}

function timeAgo(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime();
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return "Just now";
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
}

export default async function BuildsPage({
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

  const builds = await getOrgBuilds(supabase, org.id, 50);

  return (
    <div className="flex flex-col gap-6">
      <div>
        <p className="text-sm text-muted-foreground">{org.name}</p>
        <h1 className="text-2xl font-bold">Builds</h1>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Build History</CardTitle>
        </CardHeader>
        <CardContent>
          {builds.length === 0 ? (
            <p className="text-sm text-muted-foreground py-8 text-center">
              No builds yet. Builds are triggered by GitHub webhooks.
            </p>
          ) : (
            <div className="divide-y">
              {builds.map((build) => (
                <Link
                  key={build.id}
                  href={`/orgs/${orgSlug}/projects/${projectId}/builds/${build.id}`}
                  className="flex items-center gap-3 py-3 text-sm hover:bg-muted/30 -mx-3 px-3 rounded transition-colors"
                >
                  <StatusIcon status={build.status} />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-medium truncate">
                        {build.branch ?? build.tag_name ?? build.commit_sha?.slice(0, 7) ?? "—"}
                      </span>
                      {build.github_event && (
                        <Badge variant="outline" className="text-xs shrink-0">
                          {build.github_event}
                        </Badge>
                      )}
                    </div>
                    <div className="text-xs text-muted-foreground mt-0.5">
                      {build.github_owner}/{build.github_repo}
                      {build.commit_sha && ` · ${build.commit_sha.slice(0, 7)}`}
                      {build.github_sender && ` · by ${build.github_sender}`}
                    </div>
                  </div>
                  <div className="flex items-center gap-2 shrink-0">
                    <span className="text-xs text-muted-foreground">
                      {timeAgo(build.created_at)}
                    </span>
                    <StatusBadge status={build.status} />
                  </div>
                </Link>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
