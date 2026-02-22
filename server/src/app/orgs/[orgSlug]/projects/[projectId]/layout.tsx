import { redirect, notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getOrgBySlug, getProjectById } from "@/lib/supabase/queries";
import { ProjectSidebar } from "@/components/project-sidebar";
import { ProjectNavMobile } from "@/components/project-nav-mobile";

export default async function ProjectLayout({
  children,
  params,
}: {
  children: React.ReactNode;
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
    <div className="flex flex-1 -m-6">
      <div className="hidden md:flex">
        <ProjectSidebar
          orgSlug={orgSlug}
          projectId={project.id}
          projectName={project.name}
        />
      </div>
      <div className="flex flex-1 flex-col gap-4 p-6 overflow-auto">
        <div className="md:hidden">
          <ProjectNavMobile
            orgSlug={orgSlug}
            projectId={project.id}
            projectName={project.name}
          />
        </div>
        {children}
      </div>
    </div>
  );
}
