import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getOrgBySlug } from "@/lib/supabase/queries";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { CreditCard, CheckCircle2 } from "lucide-react";

export default async function BillingPage({
  params,
}: {
  params: Promise<{ orgSlug: string }>;
}) {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getClaims();
  if (error || !data?.claims) redirect("/auth/login");

  const { orgSlug } = await params;
  const org = await getOrgBySlug(supabase, orgSlug);
  if (!org) redirect("/auth/login");

  // Only owners can access billing
  if (org.role !== "owner") redirect(`/orgs/${orgSlug}`);

  return (
    <div className="flex flex-col gap-6">
      <div>
        <p className="text-sm text-muted-foreground">{org.name}</p>
        <h1 className="text-2xl font-bold">Billing</h1>
      </div>

      {org.billing_enabled ? (
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <CheckCircle2 className="size-4 text-green-500" />
              Active Subscription
            </CardTitle>
            <CardDescription>
              Your organization has an active paid subscription.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Button variant="outline" size="sm">
              <CreditCard className="size-4" />
              Manage Subscription
            </Button>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <CreditCard className="size-4" />
              Free Tier
            </CardTitle>
            <CardDescription>
              Upgrade to unlock unlimited builds, priority queuing, and advanced features.
            </CardDescription>
          </CardHeader>
          <CardContent className="flex flex-col gap-4">
            <ul className="text-sm space-y-2 text-muted-foreground">
              <li>✓ Unlimited builds</li>
              <li>✓ Priority build queue</li>
              <li>✓ Advanced workflow features</li>
              <li>✓ Team management</li>
            </ul>
            {/* Stripe Checkout link will be added when Stripe is integrated */}
            <Button size="sm" disabled>
              Upgrade to Pro (Coming Soon)
            </Button>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
