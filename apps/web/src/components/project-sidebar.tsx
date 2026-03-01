"use client";

import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarRail,
} from "@/components/ui/sidebar";
import {
  LayoutGrid,
  Hammer,
  GitBranch,
  Package,
  KeyRound,
  Settings,
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useTranslations } from "next-intl";

interface ProjectSidebarProps {
  orgSlug: string;
  projectId: string;
  projectName: string;
}

export function ProjectSidebar({ orgSlug, projectId, projectName }: ProjectSidebarProps) {
  const pathname = usePathname();
  const t = useTranslations("nav");

  const base = `/orgs/${orgSlug}/projects/${projectId}`;
  const isActive = (href: string) => pathname === href;

  const navItems = [
    { href: base, label: t("overview"), icon: LayoutGrid, key: "overview" },
    { href: `${base}/builds`, label: t("builds"), icon: Hammer, key: "builds" },
    { href: `${base}/workflow`, label: t("workflow"), icon: GitBranch, key: "workflow" },
    { href: `${base}/releases`, label: t("releases"), icon: Package, key: "releases" },
    { href: `${base}/env`, label: t("environment"), icon: KeyRound, key: "env" },
    { href: `${base}/settings`, label: t("settings"), icon: Settings, key: "settings" },
  ];

  return (
    <Sidebar collapsible="none" className="w-48 border-r shrink-0">
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>{projectName}</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {navItems.map(({ href, label, icon: Icon, key }) => (
                <SidebarMenuItem key={key}>
                  <SidebarMenuButton asChild isActive={isActive(href)}>
                    <Link href={href}>
                      <Icon />
                      <span>{label}</span>
                    </Link>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
      <SidebarRail />
    </Sidebar>
  );
}
