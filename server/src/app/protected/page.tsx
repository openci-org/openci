import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getUserOrgs } from "@/lib/supabase/queries";

// Redirect to the user's first org dashboard.
// If user has no orgs, the org creation trigger may not have run yet;
// redirect to login to re-authenticate.
export default async function ProtectedPage() {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getClaims();
  if (error || !data?.claims) redirect("/auth/login");

  const orgs = await getUserOrgs(supabase);
  if (orgs.length > 0) {
    redirect(`/orgs/${orgs[0].slug}`);
  }

  // User has no orgs — send to onboarding to create or join one
  redirect("/onboarding");
}
