import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getLocale } from "next-intl/server";
import { getOrgBySlug, getUserOrgs } from "@/lib/supabase/queries";
import { SidebarInset, SidebarProvider, SidebarTrigger } from "@/components/ui/sidebar";
import { AppSidebar } from "@/components/app-sidebar";
import { PageTitle } from "@/components/page-title";
import { Separator } from "@/components/ui/separator";
import type { OrganizationWithRole } from "@/lib/supabase/types";

export default async function OrgLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ orgSlug: string }>;
}) {
  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();
  const claims = data?.claims;

  if (!claims) {
    redirect("/auth/login");
  }

  const { orgSlug } = await params;
  const [org, userOrgs] = await Promise.all([
    getOrgBySlug(supabase, orgSlug),
    getUserOrgs(supabase),
  ]);

  if (!org) {
    // User is not a member of this org or it doesn't exist
    if (userOrgs.length > 0) {
      redirect(`/orgs/${userOrgs[0].slug}`);
    }
    redirect("/auth/login");
  }

  const email = claims?.user_metadata?.full_name ?? claims?.email ?? "";
  const locale = await getLocale();

  return (
    <SidebarProvider>
      <AppSidebar
        email={email}
        locale={locale}
        currentOrg={org}
        userOrgs={userOrgs as OrganizationWithRole[]}
      />
      <SidebarInset>
        <header className="flex h-12 shrink-0 items-center gap-2 border-b px-4">
          <SidebarTrigger className="-ml-1" />
          <Separator orientation="vertical" className="mr-2 h-4" />
          <PageTitle />
        </header>
        <div className="flex flex-1 flex-col gap-4 p-6">{children}</div>
      </SidebarInset>
    </SidebarProvider>
  );
}
