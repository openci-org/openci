import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { LoginForm } from "@/components/login-form";

export default async function Home({
  searchParams,
}: {
  searchParams: Promise<{ code?: string }>;
}) {
  const { code } = await searchParams;
  const supabase = await createClient();

  // PKCE flow: Supabase sends confirmation links to site_url/?code=xxx
  if (code) {
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) {
      redirect("/protected");
    }
    redirect(`/auth/error?error=${encodeURIComponent(error.message)}`);
  }

  const { data } = await supabase.auth.getClaims();

  if (data?.claims) {
    redirect("/protected");
  }

  return (
    <div className="flex-1 flex items-center justify-center p-4">
      <LoginForm className="w-full max-w-sm" />
    </div>
  );
}
