"use client";

import { useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import { ArrowLeft, Building2, Users } from "lucide-react";
import { useTranslations } from "next-intl";

function slugify(value: string): string {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export default function OnboardingPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const backTo = searchParams.get("from");
  const t = useTranslations("onboarding");

  const [orgName, setOrgName] = useState("");
  const [orgSlug, setOrgSlug] = useState("");
  const [slugManuallyEdited, setSlugManuallyEdited] = useState(false);
  const [isCreating, setIsCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleNameChange = (value: string) => {
    setOrgName(value);
    if (!slugManuallyEdited) {
      setOrgSlug(slugify(value));
    }
  };

  const handleSlugChange = (value: string) => {
    setOrgSlug(value.toLowerCase().replace(/[^a-z0-9-]/g, ""));
    setSlugManuallyEdited(true);
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsCreating(true);
    setError(null);

    const res = await fetch("/api/orgs", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: orgName, slug: orgSlug }),
    });

    if (!res.ok) {
      const data = (await res.json()) as { error?: string };
      if (data.error === "slug_taken") {
        setError(t("slugTaken"));
      } else {
        setError(data.error ?? t("error"));
      }
      setIsCreating(false);
      return;
    }

    router.refresh();
    router.push(`/orgs/${orgSlug}`);
  };

  const handleLogout = async () => {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/auth/login");
  };

  return (
    <div className="min-h-svh flex items-center justify-center p-6">
      <div className="w-full max-w-lg flex flex-col gap-6">
        {backTo && (
          <div>
            <Button variant="ghost" size="sm" onClick={() => router.push(backTo)}>
              <ArrowLeft className="size-4" />
              Back
            </Button>
          </div>
        )}
        <div className="text-center">
          <h1 className="text-2xl font-bold">{t("newOrgTitle")}</h1>
          <p className="text-muted-foreground mt-1">{t("newOrgDescription")}</p>
        </div>

        {/* Create org */}
        <Card>
          <CardHeader className="flex flex-row items-center gap-3 pb-3">
            <Building2 className="size-5 text-primary" />
            <div>
              <CardTitle className="text-base">{t("createOrg")}</CardTitle>
              <CardDescription className="text-sm">{t("createOrgDescription")}</CardDescription>
            </div>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleCreate} className="flex flex-col gap-4">
              <div className="grid gap-2">
                <Label htmlFor="org-name">{t("orgName")}</Label>
                <Input
                  id="org-name"
                  placeholder={t("orgNamePlaceholder")}
                  value={orgName}
                  onChange={(e) => handleNameChange(e.target.value)}
                  required
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="org-slug">{t("orgSlug")}</Label>
                <Input
                  id="org-slug"
                  placeholder={t("orgSlugPlaceholder")}
                  value={orgSlug}
                  onChange={(e) => handleSlugChange(e.target.value)}
                  pattern="[a-z0-9-]{2,40}"
                  required
                />
                <p className="text-xs text-muted-foreground">{t("orgSlugHint", { slug: orgSlug })}</p>
              </div>
              {error && <p className="text-sm text-destructive">{error}</p>}
              <Button type="submit" disabled={isCreating || !orgName || !orgSlug}>
                {isCreating ? t("creating") : t("createOrgButton")}
              </Button>
            </form>
          </CardContent>
        </Card>

        <div className="flex items-center gap-3">
          <Separator className="flex-1" />
          <span className="text-xs text-muted-foreground">{t("or")}</span>
          <Separator className="flex-1" />
        </div>

        {/* Join org */}
        <Card>
          <CardHeader className="flex flex-row items-center gap-3">
            <Users className="size-5 text-muted-foreground" />
            <div>
              <CardTitle className="text-base">{t("joinOrg")}</CardTitle>
              <CardDescription className="text-sm">{t("joinOrgDescription")}</CardDescription>
            </div>
          </CardHeader>
        </Card>

        {!backTo && (
          <div className="text-center">
            <Button variant="ghost" size="sm" onClick={handleLogout}>
              {t("logout")}
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}
