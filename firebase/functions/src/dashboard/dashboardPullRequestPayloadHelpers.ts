import { asString } from "./dashboardPayloadHelpers.js";
import { findIssueKeyFromBranchName } from "./findIssueKeyFromBranchName.js";

export interface DashboardPullRequestPayload {
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

export function isOpenedPullRequestPayload(payload: DashboardPullRequestPayload): boolean {
  return asString(payload.action) === "opened";
}

export function findRepoFullNameFromPullRequestPayload(
  payload: DashboardPullRequestPayload,
): string | null {
  const repoFullName = payload.repository?.full_name;
  return typeof repoFullName === "string" && repoFullName.length > 0 ? repoFullName : null;
}

export function findIssueKeyFromPullRequestBranch(
  payload: DashboardPullRequestPayload,
): string | null {
  const branch = payload.pull_request?.head?.ref;
  return typeof branch === "string" && branch.length > 0
    ? findIssueKeyFromBranchName(branch)
    : null;
}
