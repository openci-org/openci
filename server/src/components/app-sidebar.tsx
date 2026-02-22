"use client";

import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarRail,
  SidebarSeparator,
} from "@/components/ui/sidebar";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  LayoutDashboard,
  FolderOpen,
  Settings,
  Users,
  UserCog,
  Plug,
  CreditCard,
  ChevronsUpDown,
  Building2,
  LogOut,
  CircleUserRound,
  Sun,
  Moon,
  Laptop,
  Languages,
  Check,
  Plus,
} from "lucide-react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useTranslations } from "next-intl";
import { useTheme } from "next-themes";
import { useEffect, useState, useTransition } from "react";
import { createClient } from "@/lib/supabase/client";
import { routing } from "@/i18n/routing";
import type { OrganizationWithRole } from "@/lib/supabase/types";

interface AppSidebarProps {
  email: string;
  locale: string;
  currentOrg: OrganizationWithRole;
  userOrgs: OrganizationWithRole[];
}

export function AppSidebar({
  email,
  locale,
  currentOrg,
  userOrgs,
}: AppSidebarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const t = useTranslations("nav");
  const tAuth = useTranslations("auth");
  const tLocale = useTranslations("locale");
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [, startTransition] = useTransition();

  useEffect(() => {
    setMounted(true);
  }, []);

  const orgBase = `/orgs/${currentOrg.slug}`;
  const isActive = (href: string) => pathname === href;
  const isActivePrefix = (prefix: string) => pathname.startsWith(prefix);

  const handleLogout = async () => {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/auth/login");
  };

  const setLocale = (next: string) => {
    document.cookie = `NEXT_LOCALE=${next};path=/;max-age=31536000;SameSite=Lax`;
    startTransition(() => {
      router.refresh();
    });
  };

  const ThemeIcon =
    !mounted
      ? Laptop
      : theme === "light"
        ? Sun
        : theme === "dark"
          ? Moon
          : Laptop;

  return (
    <Sidebar collapsible="icon">
      {/* Organization Switcher */}
      <SidebarHeader>
        <SidebarMenu>
          <SidebarMenuItem>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <SidebarMenuButton
                  size="lg"
                  className="data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground"
                >
                  <div className="flex aspect-square size-8 items-center justify-center rounded-lg bg-sidebar-primary text-sidebar-primary-foreground shrink-0">
                    <Building2 className="size-4" />
                  </div>
                  <div className="grid flex-1 text-left text-sm leading-tight">
                    <span className="truncate font-semibold">
                      {currentOrg.name}
                    </span>
                    <span className="truncate text-xs text-muted-foreground">
                      {t("organization")}
                    </span>
                  </div>
                  <ChevronsUpDown className="ml-auto size-4" />
                </SidebarMenuButton>
              </DropdownMenuTrigger>
              <DropdownMenuContent
                className="w-[--radix-dropdown-menu-trigger-width] min-w-56 rounded-lg"
                align="start"
                side="bottom"
                sideOffset={4}
              >
                <DropdownMenuLabel className="text-xs text-muted-foreground">
                  Organizations
                </DropdownMenuLabel>
                {userOrgs.map((org) => (
                  <DropdownMenuItem
                    key={org.id}
                    className="gap-2 p-2"
                    onClick={() => router.push(`/orgs/${org.slug}`)}
                  >
                    <div className="flex size-6 items-center justify-center rounded-sm border">
                      <Building2 className="size-4 shrink-0" />
                    </div>
                    <span className="flex-1 truncate">{org.name}</span>
                    {org.id === currentOrg.id && (
                      <Check className="size-4 text-muted-foreground" />
                    )}
                  </DropdownMenuItem>
                ))}
                <DropdownMenuSeparator />
                <DropdownMenuItem
                  className="gap-2 p-2"
                  onClick={() => router.push(`/onboarding?from=${encodeURIComponent(pathname)}`)}
                >
                  <div className="flex size-6 items-center justify-center rounded-sm border border-dashed">
                    <Plus className="size-4 shrink-0" />
                  </div>
                  <span className="text-muted-foreground">New Organization</span>
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>

      <SidebarContent>
        {/* Main nav */}
        <SidebarGroup>
          <SidebarGroupContent>
            <SidebarMenu>
              <SidebarMenuItem>
                <SidebarMenuButton
                  asChild
                  isActive={isActive(orgBase)}
                  tooltip={t("dashboard")}
                >
                  <Link href={orgBase}>
                    <LayoutDashboard />
                    <span>{t("dashboard")}</span>
                  </Link>
                </SidebarMenuButton>
              </SidebarMenuItem>
              <SidebarMenuItem>
                <SidebarMenuButton
                  asChild
                  isActive={isActivePrefix(`${orgBase}/projects`)}
                  tooltip={t("projects")}
                >
                  <Link href={`${orgBase}/projects`}>
                    <FolderOpen />
                    <span>{t("projects")}</span>
                  </Link>
                </SidebarMenuButton>
              </SidebarMenuItem>
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>

        <SidebarSeparator />

        {/* Organization management */}
        <SidebarGroup>
          <SidebarGroupLabel>{t("organization")}</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              <SidebarMenuItem>
                <SidebarMenuButton
                  asChild
                  isActive={isActivePrefix(`${orgBase}/teams`)}
                  tooltip={t("teams")}
                >
                  <Link href={`${orgBase}/teams`}>
                    <Users />
                    <span>{t("teams")}</span>
                  </Link>
                </SidebarMenuButton>
              </SidebarMenuItem>
              <SidebarMenuItem>
                <SidebarMenuButton
                  asChild
                  isActive={isActivePrefix(`${orgBase}/members`)}
                  tooltip={t("members")}
                >
                  <Link href={`${orgBase}/members`}>
                    <UserCog />
                    <span>{t("members")}</span>
                  </Link>
                </SidebarMenuButton>
              </SidebarMenuItem>
              <SidebarMenuItem>
                <SidebarMenuButton
                  asChild
                  isActive={isActivePrefix(`${orgBase}/integrations`)}
                  tooltip={t("integrations")}
                >
                  <Link href={`${orgBase}/integrations`}>
                    <Plug />
                    <span>{t("integrations")}</span>
                  </Link>
                </SidebarMenuButton>
              </SidebarMenuItem>
              {currentOrg.billing_enabled && (
                <SidebarMenuItem>
                  <SidebarMenuButton
                    asChild
                    isActive={isActivePrefix(`${orgBase}/billing`)}
                    tooltip={t("billing")}
                  >
                    <Link href={`${orgBase}/billing`}>
                      <CreditCard />
                      <span>{t("billing")}</span>
                    </Link>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              )}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>

      <SidebarFooter>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton
              asChild
              isActive={isActivePrefix(`${orgBase}/settings`)}
              tooltip={t("settings")}
            >
              <Link href={`${orgBase}/settings`}>
                <Settings />
                <span>{t("settings")}</span>
              </Link>
            </SidebarMenuButton>
          </SidebarMenuItem>

          {/* User menu */}
          <SidebarMenuItem>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <SidebarMenuButton
                  size="lg"
                  tooltip={email}
                  className="data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground"
                >
                  <div className="flex aspect-square size-8 items-center justify-center rounded-lg bg-muted shrink-0">
                    <CircleUserRound className="size-4" />
                  </div>
                  <div className="grid flex-1 text-left text-sm leading-tight">
                    <span className="truncate font-medium">{email}</span>
                  </div>
                  <ChevronsUpDown className="ml-auto size-4" />
                </SidebarMenuButton>
              </DropdownMenuTrigger>
              <DropdownMenuContent
                className="w-[--radix-dropdown-menu-trigger-width] min-w-56 rounded-lg"
                align="end"
                side="top"
                sideOffset={4}
              >
                <div className="px-2 py-1.5 text-xs text-muted-foreground truncate">
                  {email}
                </div>
                <DropdownMenuSeparator />

                {/* Language */}
                <DropdownMenuLabel className="flex items-center gap-2 text-xs font-normal text-muted-foreground">
                  <Languages className="size-3.5" />
                  {tLocale("switch")}
                </DropdownMenuLabel>
                <DropdownMenuRadioGroup value={locale} onValueChange={setLocale}>
                  {routing.locales.map((l) => (
                    <DropdownMenuRadioItem key={l} value={l} className="pl-6">
                      {tLocale(l as "en" | "ja")}
                    </DropdownMenuRadioItem>
                  ))}
                </DropdownMenuRadioGroup>

                <DropdownMenuSeparator />

                {/* Theme */}
                <DropdownMenuLabel className="flex items-center gap-2 text-xs font-normal text-muted-foreground">
                  <ThemeIcon className="size-3.5" />
                  Theme
                </DropdownMenuLabel>
                <DropdownMenuRadioGroup
                  value={mounted ? (theme ?? "system") : "system"}
                  onValueChange={setTheme}
                >
                  <DropdownMenuRadioItem value="light" className="pl-6">
                    <Sun className="size-3.5 mr-1.5" /> Light
                  </DropdownMenuRadioItem>
                  <DropdownMenuRadioItem value="dark" className="pl-6">
                    <Moon className="size-3.5 mr-1.5" /> Dark
                  </DropdownMenuRadioItem>
                  <DropdownMenuRadioItem value="system" className="pl-6">
                    <Laptop className="size-3.5 mr-1.5" /> System
                  </DropdownMenuRadioItem>
                </DropdownMenuRadioGroup>

                <DropdownMenuSeparator />
                <DropdownMenuItem
                  className="gap-2 text-destructive focus:text-destructive"
                  onClick={handleLogout}
                >
                  <LogOut className="size-4" />
                  {tAuth("logout")}
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>

      <SidebarRail />
    </Sidebar>
  );
}
