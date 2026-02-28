import { NextResponse } from "next/server";
import { createClient as createServerClient } from "@supabase/supabase-js";

// Stripe Webhook handler (stub — activates when Stripe is integrated)
//
// When a customer subscribes or their subscription is cancelled,
// this handler updates organizations.billing_enabled accordingly.
//
// To activate:
// 1. Install stripe package: pnpm add stripe
// 2. Add STRIPE_SECRET_KEY and STRIPE_WEBHOOK_SECRET to .env.local
// 3. Uncomment the verification and event handling code below
// 4. Create a Stripe webhook endpoint pointing to /api/webhooks/stripe

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY ?? "";

function getServiceClient() {
  return createServerClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });
}

export async function POST(request: Request) {
  // TODO: Uncomment when Stripe is integrated
  // const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);
  // const body = await request.text();
  // const sig = request.headers.get('stripe-signature')!;
  // let event: Stripe.Event;
  // try {
  //   event = stripe.webhooks.constructEvent(body, sig, process.env.STRIPE_WEBHOOK_SECRET!);
  // } catch (err) {
  //   return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  // }

  const body = await request.json() as { type?: string; data?: { object?: Record<string, unknown> } };
  const eventType = body.type;
  const supabase = getServiceClient();

  // Handle Stripe events to update billing_enabled flag
  switch (eventType) {
    case "customer.subscription.created":
    case "customer.subscription.updated": {
      const subscription = body.data?.object;
      const customerId = subscription?.customer as string | undefined;
      const status = subscription?.status as string | undefined;
      const subscriptionId = subscription?.id as string | undefined;

      if (customerId && subscriptionId) {
        await supabase
          .from("teams")
          .update({
            stripe_subscription_id: subscriptionId,
            billing_enabled: status === "active" || status === "trialing",
          })
          .eq("stripe_customer_id", customerId);
      }
      break;
    }

    case "customer.subscription.deleted": {
      const subscription = body.data?.object;
      const customerId = subscription?.customer as string | undefined;

      if (customerId) {
        await supabase
          .from("teams")
          .update({
            stripe_subscription_id: null,
            billing_enabled: false,
          })
          .eq("stripe_customer_id", customerId);
      }
      break;
    }

    default:
      // Unhandled event type — acknowledge without action
      break;
  }

  return NextResponse.json({ received: true });
}
