import { redirect } from "next/navigation";

export default async function ProjectsPage({ params }: { params: Promise<{ orgSlug: string }> }) {
  const { orgSlug } = await params;
  redirect(`/orgs/${orgSlug}`);
}
