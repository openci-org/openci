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

export interface CompleteWebhookTaskData {
  webhookTask_updateMany: number;
  jobs?: unknown[] | null;
}

export interface CompleteWebhookTaskVariables {
  id: string;
  jobsJson: string;
  jobCount: number;
  connectionId?: string | null;
  owner?: string | null;
  repo?: string | null;
  commitSha?: string | null;
  branch?: string | null;
  commitMessage?: string | null;
  pullRequestNumber?: Int64String | null;
  githubBaseUrl?: string | null;
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

export interface SecretReference_Key {
  teamId: string;
  name: string;
  __typename?: "SecretReference_Key";
}

export interface SecretVersionCleanup_Key {
  path: string;
  __typename?: "SecretVersionCleanup_Key";
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
