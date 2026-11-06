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

export interface BeginPullRequestPlanningData {
  webhookTask_updateMany: number;
  pullRequestPlanning_upsert: PullRequestPlanning_Key;
}

export interface BeginPullRequestPlanningVariables {
  id: string;
  taskId: string;
  connectionId: string;
  repositoryId: Int64String;
  pullRequestNumber: Int64String;
  token: string;
}

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

export interface BillingTeamDeletion_Key {
  teamId: string;
  __typename?: "BillingTeamDeletion_Key";
}

export interface BuildDispatchScheduler_Key {
  id: string;
  __typename?: "BuildDispatchScheduler_Key";
}

export interface BuildJobDispatch_Key {
  id: string;
  __typename?: "BuildJobDispatch_Key";
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

export interface ClaimSkippedWorkflowCheckData {
  claimed: number;
}

export interface ClaimSkippedWorkflowCheckVariables {
  id: string;
  leaseOwner: string;
}

export interface CompleteSkippedWorkflowCheckData {
  skippedWorkflowCheck_updateMany: number;
}

export interface CompleteSkippedWorkflowCheckVariables {
  id: string;
  leaseOwner: string;
  checkRunId: string;
}

export interface CompleteWebhookTaskData {
  webhookTask_updateMany: number;
  jobs?: unknown[] | null;
  cancelled?: number | null;
  skipped?: unknown[] | null;
}

export interface CompleteWebhookTaskVariables {
  id: string;
  jobsJson: string;
  jobCount: number;
  skippedJson?: string;
  skippedCount?: number;
  pathFilterReason?: string | null;
  comparisonBaseSha?: string | null;
  connectionId?: string | null;
  owner?: string | null;
  repo?: string | null;
  commitSha?: string | null;
  branch?: string | null;
  commitMessage?: string | null;
  pullRequestNumber?: Int64String | null;
  githubBaseUrl?: string | null;
  planningId?: string | null;
  planningToken?: string | null;
  cancelClosedPullRequest?: boolean;
}

export interface CreateWebhookTaskData {
  webhookTask_insert: WebhookTask_Key;
}

export interface CreateWebhookTaskVariables {
  id: string;
  deliveryId: string;
  eventType: string;
  payload: string;
  receivedAt: Int64String;
}

export interface GetPendingSkippedWorkflowChecksData {
  checks: ({
    id: string;
  } & SkippedWorkflowCheck_Key)[];
}

export interface GetSkippedWorkflowCheckData {
  check?: {
    id: string;
    owner: string;
    repo: string;
    workflowName: string;
    workflowFileName: string;
    commitSha: string;
    comparisonBaseSha: string;
    githubBaseUrl: string;
    status: string;
    checkRunId?: string | null;
    leaseOwner?: string | null;
    leaseExpiresAt?: TimestampString | null;
    createdAt: Int64String;
    connection: {
      id: string;
      status: string;
      githubAppId: Int64String;
      githubApiBaseUrl: string;
      installationId: Int64String;
      accountId: Int64String;
    } & GitHubConnection_Key;
  } & SkippedWorkflowCheck_Key;
}

export interface GetSkippedWorkflowCheckVariables {
  id: string;
}

export interface GetWebhookTaskByDeliveryIdData {
  webhookTask?: {
    id: string;
    deliveryId: string;
    eventType: string;
    payload: string;
    status: string;
    retryCount: Int64String;
    createdAt: Int64String;
    updatedAt: Int64String;
  } & WebhookTask_Key;
}

export interface GetWebhookTaskByDeliveryIdVariables {
  deliveryId: string;
}

export interface GetWebhookTaskData {
  webhookTask?: {
    id: string;
    deliveryId: string;
    eventType: string;
    payload: string;
    status: string;
    errorMessage?: string | null;
    pathFilterReason?: string | null;
  } & WebhookTask_Key;
}

export interface GetWebhookTaskVariables {
  id: string;
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

export interface PullRequestPlanning_Key {
  id: string;
  __typename?: "PullRequestPlanning_Key";
}

export interface RejectWebhookTaskData {
  webhookTask_updateMany: number;
}

export interface RejectWebhookTaskVariables {
  id: string;
  reason: string;
}

export interface RequestWebhookTaskPlanningData {
  task?: WebhookTask_Key | null;
}

export interface RequestWebhookTaskPlanningVariables {
  id: string;
}

export interface RetrySkippedWorkflowCheckData {
  skippedWorkflowCheck_updateMany: number;
}

export interface RetrySkippedWorkflowCheckVariables {
  id: string;
  leaseOwner: string;
}

export interface SecretReference_Key {
  teamId: string;
  name: string;
  __typename?: "SecretReference_Key";
}

export interface SecretVersionCleanup_Key {
  path: string;
  __typename?: "SecretVersionCleanup_Key";
}

export interface SkippedWorkflowCheck_Key {
  id: string;
  __typename?: "SkippedWorkflowCheck_Key";
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

/** Generated Node Admin SDK operation action function for the 'CompleteWebhookTask' Mutation. Allow users to execute without passing in DataConnect. */
export function completeWebhookTask(
  dc: DataConnect,
  vars: CompleteWebhookTaskVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CompleteWebhookTaskData>>;
/** Generated Node Admin SDK operation action function for the 'CompleteWebhookTask' Mutation. Allow users to pass in custom DataConnect instances. */
export function completeWebhookTask(
  vars: CompleteWebhookTaskVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CompleteWebhookTaskData>>;

/** Generated Node Admin SDK operation action function for the 'RejectWebhookTask' Mutation. Allow users to execute without passing in DataConnect. */
export function rejectWebhookTask(
  dc: DataConnect,
  vars: RejectWebhookTaskVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RejectWebhookTaskData>>;
/** Generated Node Admin SDK operation action function for the 'RejectWebhookTask' Mutation. Allow users to pass in custom DataConnect instances. */
export function rejectWebhookTask(
  vars: RejectWebhookTaskVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RejectWebhookTaskData>>;

/** Generated Node Admin SDK operation action function for the 'CreateWebhookTask' Mutation. Allow users to execute without passing in DataConnect. */
export function createWebhookTask(
  dc: DataConnect,
  vars: CreateWebhookTaskVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateWebhookTaskData>>;
/** Generated Node Admin SDK operation action function for the 'CreateWebhookTask' Mutation. Allow users to pass in custom DataConnect instances. */
export function createWebhookTask(
  vars: CreateWebhookTaskVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateWebhookTaskData>>;

/** Generated Node Admin SDK operation action function for the 'RequestWebhookTaskPlanning' Mutation. Allow users to execute without passing in DataConnect. */
export function requestWebhookTaskPlanning(
  dc: DataConnect,
  vars: RequestWebhookTaskPlanningVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RequestWebhookTaskPlanningData>>;
/** Generated Node Admin SDK operation action function for the 'RequestWebhookTaskPlanning' Mutation. Allow users to pass in custom DataConnect instances. */
export function requestWebhookTaskPlanning(
  vars: RequestWebhookTaskPlanningVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RequestWebhookTaskPlanningData>>;

/** Generated Node Admin SDK operation action function for the 'BeginPullRequestPlanning' Mutation. Allow users to execute without passing in DataConnect. */
export function beginPullRequestPlanning(
  dc: DataConnect,
  vars: BeginPullRequestPlanningVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<BeginPullRequestPlanningData>>;
/** Generated Node Admin SDK operation action function for the 'BeginPullRequestPlanning' Mutation. Allow users to pass in custom DataConnect instances. */
export function beginPullRequestPlanning(
  vars: BeginPullRequestPlanningVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<BeginPullRequestPlanningData>>;

/** Generated Node Admin SDK operation action function for the 'GetWebhookTaskByDeliveryId' Query. Allow users to execute without passing in DataConnect. */
export function getWebhookTaskByDeliveryId(
  dc: DataConnect,
  vars: GetWebhookTaskByDeliveryIdVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetWebhookTaskByDeliveryIdData>>;
/** Generated Node Admin SDK operation action function for the 'GetWebhookTaskByDeliveryId' Query. Allow users to pass in custom DataConnect instances. */
export function getWebhookTaskByDeliveryId(
  vars: GetWebhookTaskByDeliveryIdVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetWebhookTaskByDeliveryIdData>>;

/** Generated Node Admin SDK operation action function for the 'GetWebhookTask' Query. Allow users to execute without passing in DataConnect. */
export function getWebhookTask(
  dc: DataConnect,
  vars: GetWebhookTaskVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetWebhookTaskData>>;
/** Generated Node Admin SDK operation action function for the 'GetWebhookTask' Query. Allow users to pass in custom DataConnect instances. */
export function getWebhookTask(
  vars: GetWebhookTaskVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetWebhookTaskData>>;

/** Generated Node Admin SDK operation action function for the 'GetSkippedWorkflowCheck' Query. Allow users to execute without passing in DataConnect. */
export function getSkippedWorkflowCheck(
  dc: DataConnect,
  vars: GetSkippedWorkflowCheckVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetSkippedWorkflowCheckData>>;
/** Generated Node Admin SDK operation action function for the 'GetSkippedWorkflowCheck' Query. Allow users to pass in custom DataConnect instances. */
export function getSkippedWorkflowCheck(
  vars: GetSkippedWorkflowCheckVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetSkippedWorkflowCheckData>>;

/** Generated Node Admin SDK operation action function for the 'GetPendingSkippedWorkflowChecks' Query. Allow users to execute without passing in DataConnect. */
export function getPendingSkippedWorkflowChecks(
  dc: DataConnect,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetPendingSkippedWorkflowChecksData>>;
/** Generated Node Admin SDK operation action function for the 'GetPendingSkippedWorkflowChecks' Query. Allow users to pass in custom DataConnect instances. */
export function getPendingSkippedWorkflowChecks(
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetPendingSkippedWorkflowChecksData>>;

/** Generated Node Admin SDK operation action function for the 'ClaimSkippedWorkflowCheck' Mutation. Allow users to execute without passing in DataConnect. */
export function claimSkippedWorkflowCheck(
  dc: DataConnect,
  vars: ClaimSkippedWorkflowCheckVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ClaimSkippedWorkflowCheckData>>;
/** Generated Node Admin SDK operation action function for the 'ClaimSkippedWorkflowCheck' Mutation. Allow users to pass in custom DataConnect instances. */
export function claimSkippedWorkflowCheck(
  vars: ClaimSkippedWorkflowCheckVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ClaimSkippedWorkflowCheckData>>;

/** Generated Node Admin SDK operation action function for the 'CompleteSkippedWorkflowCheck' Mutation. Allow users to execute without passing in DataConnect. */
export function completeSkippedWorkflowCheck(
  dc: DataConnect,
  vars: CompleteSkippedWorkflowCheckVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CompleteSkippedWorkflowCheckData>>;
/** Generated Node Admin SDK operation action function for the 'CompleteSkippedWorkflowCheck' Mutation. Allow users to pass in custom DataConnect instances. */
export function completeSkippedWorkflowCheck(
  vars: CompleteSkippedWorkflowCheckVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CompleteSkippedWorkflowCheckData>>;

/** Generated Node Admin SDK operation action function for the 'RetrySkippedWorkflowCheck' Mutation. Allow users to execute without passing in DataConnect. */
export function retrySkippedWorkflowCheck(
  dc: DataConnect,
  vars: RetrySkippedWorkflowCheckVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RetrySkippedWorkflowCheckData>>;
/** Generated Node Admin SDK operation action function for the 'RetrySkippedWorkflowCheck' Mutation. Allow users to pass in custom DataConnect instances. */
export function retrySkippedWorkflowCheck(
  vars: RetrySkippedWorkflowCheckVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RetrySkippedWorkflowCheckData>>;
