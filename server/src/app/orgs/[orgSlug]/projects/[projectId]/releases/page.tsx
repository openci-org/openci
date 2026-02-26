import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { getOrgBySlug } from "@/lib/supabase/queries";
import { createClient } from "@/lib/supabase/server";
import { Package } from "lucide-react";
import { redirect } from "next/navigation";

export default async function ReleasesPage({
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

  // Releases are created by tag-triggered builds.
  const { data: releaseBuilds } = await supabase
    .from("builds")
    .select("id, tag_name, status, commit_sha, created_at")
    .eq("org_id", org.id)
    .eq("github_event", "create")
    .not("tag_name", "is", null)
    .order("created_at", { ascending: false })
    .limit(20);

  return (
    <div className="flex flex-col gap-6">
      <div>
        <p className="text-sm text-muted-foreground">{org.name}</p>
        <h1 className="text-2xl font-bold">Releases</h1>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Package className="size-4" />
            Tag Releases
          </CardTitle>
        </CardHeader>
        <CardContent>
          {!releaseBuilds || releaseBuilds.length === 0 ? (
            <p className="text-sm text-muted-foreground py-6 text-center">
              No releases yet. Releases are created when a tag-triggered workflow succeeds.
            </p>
          ) : (
            <div className="divide-y">
              {releaseBuilds.map((build) => (
                <div key={build.id} className="flex items-center gap-3 py-3 text-sm">
                  <Package className="size-4 text-muted-foreground shrink-0" />
                  <div className="flex-1 min-w-0">
                    <div className="font-medium">{build.tag_name}</div>
                    <div className="text-xs text-muted-foreground mt-0.5">
                      {build.commit_sha?.slice(0, 7) ?? "—"} ·{" "}
                      {new Date(build.created_at).toLocaleDateString()}
                    </div>
                  </div>
                  <span
                    className={`text-xs font-medium ${build.status === "success" ? "text-green-600" : "text-muted-foreground"}`}
                  >
                    {build.status}
                  </span>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
