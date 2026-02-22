"use client";

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
import { cn } from "@/lib/utils";

interface ProjectNavMobileProps {
  projectId: string;
  projectName: string;
}

export function ProjectNavMobile({ projectId, projectName }: ProjectNavMobileProps) {
  const pathname = usePathname();
  const t = useTranslations("nav");

  const base = `/protected/projects/${projectId}`;

  const navItems = [
    { href: base, label: t("overview"), icon: LayoutGrid },
    { href: `${base}/builds`, label: t("builds"), icon: Hammer },
    { href: `${base}/workflow`, label: t("workflow"), icon: GitBranch },
    { href: `${base}/releases`, label: t("releases"), icon: Package },
    { href: `${base}/env`, label: t("environment"), icon: KeyRound },
    { href: `${base}/settings`, label: t("settings"), icon: Settings },
  ];

  return (
    <div className="flex flex-col gap-1">
      <p className="text-xs font-medium text-muted-foreground px-1 mb-1">{projectName}</p>
      <div className="flex gap-1 overflow-x-auto pb-1">
        {navItems.map(({ href, label, icon: Icon }) => {
          const active = pathname === href;
          return (
            <Link
              key={href}
              href={href}
              className={cn(
                "flex items-center gap-1.5 shrink-0 rounded-md px-3 py-1.5 text-xs font-medium transition-colors",
                active
                  ? "bg-primary text-primary-foreground"
                  : "bg-muted text-muted-foreground hover:bg-muted/80 hover:text-foreground"
              )}
            >
              <Icon className="size-3.5" />
              {label}
            </Link>
          );
        })}
      </div>
    </div>
  );
}
