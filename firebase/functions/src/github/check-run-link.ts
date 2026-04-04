const DEFAULT_DASHBOARD_BASE_URL = "https://dashboard.openci.org";

export function buildDashboardRunUrl(buildJobId: string): string {
  const baseUrl = (process.env.OPENCI_DASHBOARD_BASE_URL ?? DEFAULT_DASHBOARD_BASE_URL).replace(
    /\/+$/,
    "",
  );
  return `${baseUrl}/runs/${encodeURIComponent(buildJobId)}`;
}
