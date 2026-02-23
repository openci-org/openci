"use client";

import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { useRouter } from "next/navigation";
import { useTranslations } from "next-intl";

export function LogoutButton({ className }: { className?: string }) {
  const router = useRouter();
  const t = useTranslations("auth");

  const logout = async () => {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/auth/login");
  };

  return <Button className={className} onClick={logout}>{t("logout")}</Button>;
}
