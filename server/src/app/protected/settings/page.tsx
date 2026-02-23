import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getTranslations } from "next-intl/server";

export default async function SettingsPage() {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getClaims();
  if (error || !data?.claims) redirect("/auth/login");
  const t = await getTranslations("nav");

  return (
    <div className="flex flex-col gap-6">
      <h1 className="text-2xl font-bold">{t("settings")}</h1>
    </div>
  );
}
