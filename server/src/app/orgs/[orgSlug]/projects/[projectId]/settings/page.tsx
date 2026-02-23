import { redirect, notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getOrgBySlug, getProjectById } from "@/lib/supabase/queries";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

export default async function ProjectSettingsPage({
  params,
}: {
  params: Promise<{ orgSlug: string; projectId: string }>;
}) {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getClaims();
  if (error || !data?.claims) redirect("/auth/login");

  const { orgSlug, projectId } = await params;
  const [org, project] = await Promise.all([
    getOrgBySlug(supabase, orgSlug),
    getProjectById(supabase, projectId),
  ]);

  if (!org) redirect("/auth/login");
  if (!project) notFound();

  return (
    <div className="flex flex-col gap-6">
      <div>
        <p className="text-sm text-muted-foreground">{project.name}</p>
        <h1 className="text-2xl font-bold">Project Settings</h1>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Project Details</CardTitle>
          <CardDescription>Manage your project configuration.</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-3 text-sm">
            <div>
              <span className="text-muted-foreground">Name: </span>
              <span className="font-medium">{project.name}</span>
            </div>
            <div>
              <span className="text-muted-foreground">Slug: </span>
              <span className="font-mono text-xs bg-muted px-1.5 py-0.5 rounded">{project.slug}</span>
            </div>
            {project.description && (
              <div>
                <span className="text-muted-foreground">Description: </span>
                <span>{project.description}</span>
              </div>
            )}
            {project.framework && (
              <div>
                <span className="text-muted-foreground">Framework: </span>
                <span className="font-medium">{project.framework}</span>
              </div>
            )}
            {project.platforms.length > 0 && (
              <div className="flex items-center gap-2">
                <span className="text-muted-foreground">Platforms: </span>
                {(project.platforms as string[]).map((p: string) => (
                  <Badge key={p} variant="secondary" className="text-xs">{p}</Badge>
                ))}
              </div>
            )}
            <div>
              <span className="text-muted-foreground">Created: </span>
              <span>{new Date(project.created_at).toLocaleDateString()}</span>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
