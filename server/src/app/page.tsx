import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { LoginForm } from "@/components/login-form";

export default async function Home() {
  const supabase = await createClient();
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
