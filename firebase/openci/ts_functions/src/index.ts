import { setGlobalOptions } from "firebase-functions/v2";
import "./dataConnect";

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

export { generateAiWorkflowResponse } from "./ai/generateAiWorkflow";
export {
  ascListApps,
  ascListBuilds,
  ascSubmitForReview,
  ascSubmitToTestFlight,
} from "./asc/ascHandlers";
export { buildJobStatusChange } from "./buildJob/buildJobStatusChange";
export { cancelBuildJob } from "./buildJob/cancelBuildJob";
export { checkRunUpdate } from "./buildJob/checkRunUpdate";
export { generateFailureSummary } from "./buildJob/generateFailureSummary";
export { retryBuildJob, retryWorkflowRun } from "./buildJob/retryHandlers";
export { searchGitHubActions } from "./github/actions";
export {
  createWorkflowFile,
  listBranches,
  listDirectories,
  listRepositories,
  listWorkflowFiles,
  syncWorkflowFiles,
} from "./github/repositories";
export { createGitHubSetupUrl, githubSetup } from "./github/setup";
export { githubWebhook } from "./github/webhook";
export { acceptInvitation } from "./invitation/acceptInvitation";
export { acceptInvitations } from "./invitation/acceptInvitations";
export {
  backfillCursorAgentPullRequests,
  startIssueCursorAgent,
} from "./issues/cursorAgentHandlers";
export {
  completeGitHubDeviceFlow,
  connectGitHub,
  listGitHubRepositories,
  startGitHubDeviceFlow,
} from "./issues/githubConnectionHandlers";
export {
  backfillIssueKeys,
  createGitHubIssue,
  createGitHubSubIssue,
  importGitHubIssues,
  syncGitHubIssues,
} from "./issues/githubIssueHandlers";
export { githubPullRequestWebhook } from "./issues/githubWebhookHandlers";
export {
  autoEstimateIssueWeightOnIssueWrite,
  estimateIssueWeight,
  recomputeResolutionWeights,
} from "./issues/issueWeightHandlers";
export {
  autoSyncIssueToGitHubOnIssueWrite,
  issueLifecycleEventLogger,
} from "./issues/lifecycleHandlers";
export {
  createSecretV1,
  deleteSecretV1,
  generateCertificateKeyV1,
  setupAscApiKeyV1,
  updateSecretV1,
} from "./secrets/secretHandlers";
export { getTeamMembers, inviteTeamMember } from "./team/teamHandlers";
