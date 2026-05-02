import { setGlobalOptions } from "firebase-functions/v2";
import "./dataConnect";

setGlobalOptions({
  region: "asia-northeast1",
  maxInstances: 10,
  secrets: ["GITHUB_APP_ID", "GITHUB_PRIVATE_KEY", "GITHUB_WEBHOOK_SECRET"],
});

export { acceptInvitation } from "./invitation/acceptInvitation";
export { acceptInvitations } from "./invitation/acceptInvitations";
export {
  createWorkflowFile,
  listBranches,
  listDirectories,
  listRepositories,
  listWorkflowFiles,
  syncWorkflowFiles,
} from "./github/repositories";
export { searchGitHubActions } from "./github/actions";
export { createGitHubSetupUrl, githubSetup } from "./github/setup";
export { githubWebhook } from "./github/webhook";
export {
  ascListApps,
  ascListBuilds,
  ascSubmitForReview,
  ascSubmitToTestFlight,
} from "./asc/ascHandlers";
export { generateAiWorkflowResponse } from "./ai/generateAiWorkflow";
export { buildJobStatusChange } from "./buildJob/buildJobStatusChange";
export { cancelBuildJob } from "./buildJob/cancelBuildJob";
export { checkRunUpdate } from "./buildJob/checkRunUpdate";
export { generateFailureSummary } from "./buildJob/generateFailureSummary";
export { retryBuildJob, retryWorkflowRun } from "./buildJob/retryHandlers";
export {
  createSecretV1,
  deleteSecretV1,
  generateCertificateKeyV1,
  setupAscApiKeyV1,
  updateSecretV1,
} from "./secrets/secretHandlers";
export { getTeamMembers, inviteTeamMember } from "./team/teamHandlers";
