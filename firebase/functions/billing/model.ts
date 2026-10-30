import type * as sdk from "@openci/billing-admin";

export type BillingContext = sdk.GetBillingContextData;
export type CustomerIntent = NonNullable<BillingContext["customer"]>;
export type CheckoutIntent = NonNullable<BillingContext["checkout"]>;
export type Period = NonNullable<sdk.GetBillingPeriodData["period"]>;
export type StripeState = NonNullable<sdk.GetBillingStripeStateData["billingStripeState"]>;

export class BillingError extends Error {
  constructor(
    readonly code: "invalid-argument" | "permission-denied" | "failed-precondition" | "unavailable",
    readonly reason: string,
  ) {
    super(reason);
  }
}

export class UnverifiedPurchase extends Error {}
export const pending = () => new BillingError("failed-precondition", "payment_pending");
export const terminal = (status: string) => ["canceled", "incomplete_expired"].includes(status);
export const plans = {
  light: { cents: 1000, seconds: "36000" },
  pro: { cents: 10000, seconds: "360000" },
} as const;
export type Plan = keyof typeof plans;
export function plan(value: unknown): Plan {
  if (value !== "light" && value !== "pro")
    throw new BillingError("invalid-argument", "invalid_plan");
  return value;
}
export function id(value: string | { id: string } | null | undefined): string | undefined {
  return typeof value === "string" ? value : value?.id;
}

export interface Observation {
  stripeSubscriptionId: string | null;
  subscriptionStatus: string;
  planId: string | null;
  paidPeriodId: string | null;
  cancelAtPeriodEnd: boolean;
  period?: Period;
}
export function emptyObservation(status = "none"): Observation {
  return {
    stripeSubscriptionId: null,
    subscriptionStatus: status,
    planId: null,
    paidPeriodId: null,
    cancelAtPeriodEnd: false,
  };
}
