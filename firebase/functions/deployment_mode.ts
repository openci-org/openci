/** Operator configuration only; never read this flag from a webhook or job. */
export function selfHostedMode(environment: NodeJS.ProcessEnv = process.env): boolean {
  const value = environment.OPENCI_SELF_HOSTED ?? "false";
  if (value !== "true" && value !== "false") throw new Error("Invalid OPENCI_SELF_HOSTED");
  if (value === "true" && environment.BILLING_ENABLED === "true") {
    throw new Error("Self-hosted deployments cannot enable Stripe billing");
  }
  return value === "true";
}
