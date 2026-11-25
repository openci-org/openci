import { selfHostedMode } from "./deployment_mode.js";

export function dashboardOrigin(environment: NodeJS.ProcessEnv): string | undefined {
  return (
    environment.OPENCI_DASHBOARD_ORIGIN ||
    environment.BILLING_DASHBOARD_ORIGIN ||
    (selfHostedMode(environment) ? undefined : "https://dashboard.openci.org")
  );
}

export function urlSegment(value: string): string {
  return encodeURIComponent(value).replaceAll("(", "%28").replaceAll(")", "%29");
}

export function dashboardRunUrl(origin: string | undefined, jobId: string): string | undefined {
  const url = origin && URL.canParse(origin) ? new URL(origin) : null;
  if (url?.protocol !== "https:" || url.username || url.password) return;
  return `${url.origin}/runs/${urlSegment(jobId)}`;
}
