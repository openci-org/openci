import {
  ConnectorConfig,
  DataConnect,
  OperationOptions,
  ExecuteOperationResponse,
} from "firebase-admin/data-connect";

export const connectorConfig: ConnectorConfig;

export type TimestampString = string;
export type UUIDString = string;
export type Int64String = string;
export type DateString = string;

export interface BillingAccount_Key {
  teamId: string;
  __typename?: "BillingAccount_Key";
}

export interface BillingAdmission_Key {
  id: string;
  __typename?: "BillingAdmission_Key";
}

export interface BillingCheckoutCreation_Key {
  idempotencyKey: string;
  __typename?: "BillingCheckoutCreation_Key";
}

export interface BillingCustomerCreation_Key {
  teamId: string;
  __typename?: "BillingCustomerCreation_Key";
}

export interface BillingExecution_Key {
  runId: string;
  __typename?: "BillingExecution_Key";
}

export interface BillingPeriod_Key {
  id: string;
  __typename?: "BillingPeriod_Key";
}

export interface BillingStripeEvent_Key {
  eventId: string;
  __typename?: "BillingStripeEvent_Key";
}

export interface BillingStripeState_Key {
  teamId: string;
  __typename?: "BillingStripeState_Key";
}

export interface BillingTrialClaim_Key {
  userId: string;
  __typename?: "BillingTrialClaim_Key";
}

export interface BuildJob_Key {
  id: string;
  __typename?: "BuildJob_Key";
}

export interface BuildLog_Key {
  runId: string;
  sequence: Int64String;
  __typename?: "BuildLog_Key";
}

export interface BuildRun_Key {
  id: string;
  __typename?: "BuildRun_Key";
}

export interface BuildStep_Key {
  runId: string;
  stepId: string;
  __typename?: "BuildStep_Key";
}

export interface GetBuildJobsData {
  buildJobs: ({
    id: string;
    status: string;
    owner: string;
    repo: string;
    teamId?: string | null;
    workflowId?: string | null;
    workflowName: string;
    workflowFileName: string;
    commitSha?: string | null;
    commitMessage?: string | null;
    pullRequestNumber?: Int64String | null;
    branch?: string | null;
    tagName?: string | null;
    jobKey?: string | null;
    workflowJobKey?: string | null;
    workflowRunId?: string | null;
    matrix?: string | null;
    matrixLabel?: string | null;
    needs?: string | null;
    runsOn?: string | null;
    runCount?: Int64String | null;
    latestRunId?: string | null;
    createdAt: Int64String;
    updatedAt: Int64String;
    completedAt?: Int64String | null;
  } & BuildJob_Key)[];
}

export interface GetBuildJobsVariables {
  teamId: string;
  offset?: number;
  limit?: number;
}

export interface GitHubConnectionRequest_Key {
  id: string;
  __typename?: "GitHubConnectionRequest_Key";
}

export interface GitHubConnectionSession_Key {
  id: string;
  __typename?: "GitHubConnectionSession_Key";
}

export interface GitHubConnection_Key {
  id: string;
  __typename?: "GitHubConnection_Key";
}

export interface SecretReference_Key {
  teamId: string;
  name: string;
  __typename?: "SecretReference_Key";
}

export interface SkippedWorkflowReport_Key {
  id: string;
  __typename?: "SkippedWorkflowReport_Key";
}

export interface TeamMember_Key {
  id: Int64String;
  __typename?: "TeamMember_Key";
}

export interface Team_Key {
  id: string;
  __typename?: "Team_Key";
}

export interface WebhookTask_Key {
  id: string;
  __typename?: "WebhookTask_Key";
}

/** Generated Node Admin SDK operation action function for the 'GetBuildJobs' Query. Allow users to execute without passing in DataConnect. */
export function getBuildJobs(
  dc: DataConnect,
  vars: GetBuildJobsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildJobsData>>;
/** Generated Node Admin SDK operation action function for the 'GetBuildJobs' Query. Allow users to pass in custom DataConnect instances. */
export function getBuildJobs(
  vars: GetBuildJobsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildJobsData>>;
