import { findIssueKeyFromBranchName } from "./dashboardIssueKey.js";

export interface DashboardPullRequestWebhookPayload {
  action?: unknown;
  repository?: {
    full_name?: unknown;
  };
  pull_request?: {
    head?: {
      ref?: unknown;
    };
  };
}

export interface DashboardIssueStatusSyncTarget {
  repoFullName: string;
  issueKey: string;
}

function asString(value: unknown, fallback = ""): string {
  return typeof value === "string" && value.length > 0 ? value : fallback;
}

export function findDashboardIssueStatusSyncTarget(
  payload: DashboardPullRequestWebhookPayload,
): DashboardIssueStatusSyncTarget | null {
  const action = asString(payload.action);
  if (action !== "opened") {
    return null;
  }

  const repoFullName = payload.repository?.full_name;
  if (typeof repoFullName !== "string" || repoFullName.length === 0) {
    return null;
  }

  const branch = payload.pull_request?.head?.ref;
  if (typeof branch !== "string" || branch.length === 0) {
    return null;
  }

  const issueKey = findIssueKeyFromBranchName(branch);
  if (issueKey === null) {
    return null;
  }

  return { repoFullName, issueKey };
}
