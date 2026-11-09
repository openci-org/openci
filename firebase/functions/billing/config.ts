import { selfHostedMode } from "../deployment_mode.js";

export interface BillingConfig {
  enabled: boolean;
  selfHosted: boolean;
  livemode: boolean;
  origin: string;
  portalId: string;
  complimentary: Set<string>;
}

export function billingConfig(env: NodeJS.ProcessEnv): BillingConfig {
  const enabled = env.BILLING_ENABLED ?? "false";
  if (enabled !== "true" && enabled !== "false") throw new Error("Invalid BILLING_ENABLED");
  const result: BillingConfig = {
    enabled: enabled === "true",
    selfHosted: selfHostedMode(env),
    livemode: env.STRIPE_LIVEMODE === "true",
    origin: env.BILLING_DASHBOARD_ORIGIN?.trim() ?? "",
    portalId: env.STRIPE_PORTAL_CONFIGURATION_ID?.trim() ?? "",
    complimentary: new Set(
      (env.BILLING_COMPLIMENTARY_PRO_TEAM_IDS ?? "")
        .split(",")
        .map((s) => s.trim())
        .filter(Boolean),
    ),
  };
  if (!result.enabled) return result;
  if (env.STRIPE_LIVEMODE !== "true" && env.STRIPE_LIVEMODE !== "false")
    throw new Error("Invalid Stripe mode");
  const url = new URL(result.origin);
  if (
    url.username ||
    url.password ||
    url.pathname !== "/" ||
    url.search ||
    url.hash ||
    (url.protocol !== "https:" &&
      !(url.protocol === "http:" && ["localhost", "127.0.0.1", "[::1]"].includes(url.hostname)))
  )
    throw new Error("Invalid billing origin");
  result.origin = url.origin;
  if (!result.portalId) throw new Error("Missing billing portal configuration");
  const key = env.STRIPE_SECRET_KEY ?? "";
  if (!new RegExp(`^(sk|rk)_${result.livemode ? "live" : "test"}_.+`).test(key))
    throw new Error("Stripe key mode mismatch");
  return result;
}

export function returnUrl(config: BillingConfig, teamId: string, result: string): string {
  const url = new URL("/billing", config.origin);
  url.search = new URLSearchParams({ teamId, result }).toString();
  return url.href;
}
