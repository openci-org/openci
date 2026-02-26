import { ProjectNavMobile } from "@/components/project-nav-mobile";
import { ProjectSidebar } from "@/components/project-sidebar";
import { getOrgBySlug } from "@/lib/supabase/queries";
import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";

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

  const { orgSlug } = await params;

  const org = await getOrgBySlug(supabase, orgSlug);
  if (!org) redirect("/auth/login");

  return (
    <div className="flex flex-1 -m-6">
      <div className="hidden md:flex">
        <ProjectSidebar orgSlug={orgSlug} projectId={org.id} projectName={org.name} />
      </div>
      <div className="flex flex-1 flex-col gap-4 p-6 overflow-auto">
        <div className="md:hidden">
          <ProjectNavMobile orgSlug={orgSlug} projectId={org.id} projectName={org.name} />
        </div>
        {children}
      </div>
    </div>
  );
}
