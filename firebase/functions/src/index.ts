import { setGlobalOptions } from "firebase-functions/v2";

setGlobalOptions({
  region: "asia-northeast1",
  maxInstances: 10,
  secrets: [
    "GITHUB_APP_ID",
    "GITHUB_PRIVATE_KEY",
    "GITHUB_WEBHOOK_SECRET",
    "ANTHROPIC_API_KEY",
    "CURSOR_API_KEY",
  ],
});

export { generateAiWorkflowResponse } from "./ai/generateAiWorkflow.js";
export {
  ascListApps,
  ascListBuilds,
  ascSubmitForReview,
  ascSubmitToTestFlight,
} from "./asc/ascHandlers.js";
export { buildJobStatusChange } from "./buildJob/buildJobStatusChange.js";
export { cancelBuildJob } from "./buildJob/cancelBuildJob.js";
export { checkRunUpdate } from "./buildJob/checkRunUpdate.js";
export {
  generateFailureSummary,
  generateFailureSummaryOnBuildJobFailure,
} from "./buildJob/generateFailureSummary.js";
export { retryBuildJob, retryWorkflowRun } from "./buildJob/retryHandlers.js";
export { searchGitHubActions } from "./github/actions.js";
export {
  createWorkflowFile,
  listBranches,
  listDirectories,
  listRepositories,
  listWorkflowFiles,
} from "./github/repositories.js";
export { createGitHubSetupUrl, githubSetup } from "./github/setup.js";
export { githubWebhook } from "./github/webhook.js";
export { acceptInvitation } from "./invitation/acceptInvitation.js";
export { acceptInvitations } from "./invitation/acceptInvitations.js";
export {
  backfillCursorAgentPullRequests,
  startIssueCursorAgent,
} from "./issues/cursorAgentHandlers.js";
export {
  completeGitHubDeviceFlow,
  connectGitHub,
  listGitHubRepositories,
  startGitHubDeviceFlow,
} from "./issues/githubConnectionHandlers.js";
export {
  backfillIssueKeys,
  createGitHubIssue,
  createGitHubSubIssue,
  importGitHubIssues,
  linkIssueToGitHubPullRequest,
  syncGitHubIssues,
} from "./issues/githubIssueHandlers.js";
export { githubPullRequestWebhook } from "./issues/githubWebhookHandlers.js";
export {
  autoEstimateIssueWeightOnIssueWrite,
  estimateIssueWeight,
  recomputeResolutionWeights,
} from "./issues/issueWeightHandlers.js";
export {
  autoSyncIssueToGitHubOnIssueWrite,
  issueLifecycleEventLogger,
} from "./issues/lifecycleHandlers.js";
export {
  createSecretV1,
  deleteSecretV1,
  generateCertificateKeyV1,
  generateDeveloperIdCsrV1,
  registerDeveloperIdCertificateV1,
  setupAscApiKeyV1,
  updateSecretV1,
} from "./secrets/secretHandlers.js";
export { getTeamMembers, inviteTeamMember } from "./team/teamHandlers.js";
