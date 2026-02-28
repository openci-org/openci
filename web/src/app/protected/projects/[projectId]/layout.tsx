import { MOCK_PROJECTS } from "@/lib/mock-data";
import { ProjectSidebar } from "@/components/project-sidebar";
import { ProjectNavMobile } from "@/components/project-nav-mobile";

export default async function ProjectLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ projectId: string }>;
}) {
  const { projectId } = await params;
  const project = MOCK_PROJECTS.find((p) => p.id === projectId) ?? {
    id: projectId,
    name: projectId,
    orgId: "",
  };

  return (
    <div className="flex flex-1 -m-6">
      <div className="hidden md:flex">
        <ProjectSidebar orgSlug="" projectId={project.id} projectName={project.name} />
      </div>
      <div className="flex flex-1 flex-col gap-4 p-6 overflow-auto">
        <div className="md:hidden">
          <ProjectNavMobile orgSlug="" projectId={project.id} projectName={project.name} />
        </div>
        {children}
      </div>
    </div>
  );
}
