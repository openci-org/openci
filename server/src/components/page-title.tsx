"use client";

import { usePathname } from "next/navigation";
import { useTranslations } from "next-intl";

export function PageTitle() {
  const pathname = usePathname();
  const t = useTranslations("nav");

  const getTitle = (): string => {
    if (pathname === "/protected") return t("dashboard");
    if (pathname.startsWith("/protected/projects")) {
      const segments = pathname
        .replace("/protected/projects/", "")
        .split("/");
      // /protected/projects
      if (segments[0] === "" || pathname === "/protected/projects")
        return t("projects");
      // sub-pages: builds, workflow, releases, env, settings
      const sub = segments[1];
      if (sub === "builds") return t("builds");
      if (sub === "workflow") return t("workflow");
      if (sub === "releases") return t("releases");
      if (sub === "env") return t("environment");
      if (sub === "settings") return t("settings");
      // /protected/projects/[projectId]
      return t("overview");
    }
    if (pathname.startsWith("/protected/teams")) return t("teams");
    if (pathname.startsWith("/protected/members")) return t("members");
    if (pathname.startsWith("/protected/billing")) return t("billing");
    if (pathname.startsWith("/protected/integrations")) return t("integrations");
    if (pathname.startsWith("/protected/settings")) return t("settings");
    return "";
  };

  const title = getTitle();
  if (!title) return null;

  return <span className="text-sm font-medium">{title}</span>;
}
