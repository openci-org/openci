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

export interface AppendBuildLogData {
  buildRun_updateMany: number;
  buildLog_insert: BuildLog_Key;
}

export interface AppendBuildLogVariables {
  teamId: string;
  runId: string;
  stepId?: string | null;
  expectedLastSequence: Int64String;
  sequence: Int64String;
  logId: UUIDString;
  source: string;
  stream: string;
  message: string;
  occurredAt: TimestampString;
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

export interface BillingTrialClaim_Key {
  userId: string;
  __typename?: "BillingTrialClaim_Key";
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

export interface CreateBuildStepData {
  buildStep_insert: BuildStep_Key;
}

export interface CreateBuildStepVariables {
  teamId: string;
  runId: string;
  stepId: string;
  name: string;
  stepOrder: number;
}

export interface DeleteExpiredBuildLogsData {
  buildLog_deleteMany: number;
}

export interface DeleteExpiredBuildLogsVariables {
  runId: string;
  throughSequence: Int64String;
}

export interface GetBuildLogStateData {
  run?: {
    id: string;
    status: string;
    lastLogSequence: Int64String;
    logsExpireAt?: TimestampString | null;
    allSteps: {
      stepId: string;
      name: string;
      status: string;
      stepOrder: number;
      durationMs: Int64String;
      createdAt: TimestampString;
      updatedAt: TimestampString;
    }[];
  } & BuildRun_Key;
}

export interface GetBuildLogStateVariables {
  teamId: string;
  jobId: string;
  runId: string;
}

export interface GetBuildLogWriteStateData {
  run?: {
    id: string;
    lastLogSequence: Int64String;
    logsExpireAt?: TimestampString | null;
    logs: {
      logId: UUIDString;
      sequence: Int64String;
      stepId?: string | null;
      source: string;
      stream: string;
      message: string;
      occurredAt: TimestampString;
      createdAt: TimestampString;
    }[];
  } & BuildRun_Key;
}

export interface GetBuildLogWriteStateVariables {
  teamId: string;
  runId: string;
  logIds: UUIDString[];
}

export interface GetBuildLogsData {
  run?: {
    id: string;
    lastLogSequence: Int64String;
    logsExpireAt?: TimestampString | null;
    logEntries: {
      logId: UUIDString;
      sequence: Int64String;
      stepId?: string | null;
      source: string;
      stream: string;
      message: string;
      occurredAt: TimestampString;
      createdAt: TimestampString;
    }[];
  } & BuildRun_Key;
}

export interface GetBuildLogsVariables {
  teamId: string;
  runId: string;
  afterSequence?: Int64String;
  limit?: number;
}

export interface GetBuildStepWriteStateData {
  run?: {
    id: string;
    steps: {
      stepId: string;
      name: string;
      status: string;
      stepOrder: number;
      durationMs: Int64String;
      createdAt: TimestampString;
      updatedAt: TimestampString;
    }[];
  } & BuildRun_Key;
}

export interface GetBuildStepWriteStateVariables {
  teamId: string;
  runId: string;
  stepId: string;
}

export interface GetBuildStepsData {
  run?: {
    id: string;
    stepSummaries: {
      stepId: string;
      name: string;
      status: string;
      stepOrder: number;
      durationMs: Int64String;
      createdAt: TimestampString;
      updatedAt: TimestampString;
    }[];
  } & BuildRun_Key;
}

export interface GetBuildStepsVariables {
  teamId: string;
  runId: string;
  offset?: number;
  limit?: number;
}

export interface GetExpiredBuildLogsData {
  runs: ({
    id: string;
    expiredLogs: {
      sequence: Int64String;
    }[];
  } & BuildRun_Key)[];
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

export interface SecretVersionCleanup_Key {
  path: string;
  __typename?: "SecretVersionCleanup_Key";
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

export interface UpdateBuildStepData {
  buildStep_updateMany: number;
}

export interface UpdateBuildStepVariables {
  teamId: string;
  runId: string;
  stepId: string;
  status: string;
  durationMs: Int64String;
}

export interface WebhookTask_Key {
  id: string;
  __typename?: "WebhookTask_Key";
}

/** Generated Node Admin SDK operation action function for the 'AppendBuildLog' Mutation. Allow users to execute without passing in DataConnect. */
export function appendBuildLog(
  dc: DataConnect,
  vars: AppendBuildLogVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<AppendBuildLogData>>;
/** Generated Node Admin SDK operation action function for the 'AppendBuildLog' Mutation. Allow users to pass in custom DataConnect instances. */
export function appendBuildLog(
  vars: AppendBuildLogVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<AppendBuildLogData>>;

/** Generated Node Admin SDK operation action function for the 'GetBuildSteps' Query. Allow users to execute without passing in DataConnect. */
export function getBuildSteps(
  dc: DataConnect,
  vars: GetBuildStepsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildStepsData>>;
/** Generated Node Admin SDK operation action function for the 'GetBuildSteps' Query. Allow users to pass in custom DataConnect instances. */
export function getBuildSteps(
  vars: GetBuildStepsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildStepsData>>;

/** Generated Node Admin SDK operation action function for the 'GetBuildLogs' Query. Allow users to execute without passing in DataConnect. */
export function getBuildLogs(
  dc: DataConnect,
  vars: GetBuildLogsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildLogsData>>;
/** Generated Node Admin SDK operation action function for the 'GetBuildLogs' Query. Allow users to pass in custom DataConnect instances. */
export function getBuildLogs(
  vars: GetBuildLogsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildLogsData>>;

/** Generated Node Admin SDK operation action function for the 'GetBuildLogWriteState' Query. Allow users to execute without passing in DataConnect. */
export function getBuildLogWriteState(
  dc: DataConnect,
  vars: GetBuildLogWriteStateVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildLogWriteStateData>>;
/** Generated Node Admin SDK operation action function for the 'GetBuildLogWriteState' Query. Allow users to pass in custom DataConnect instances. */
export function getBuildLogWriteState(
  vars: GetBuildLogWriteStateVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildLogWriteStateData>>;

/** Generated Node Admin SDK operation action function for the 'GetBuildStepWriteState' Query. Allow users to execute without passing in DataConnect. */
export function getBuildStepWriteState(
  dc: DataConnect,
  vars: GetBuildStepWriteStateVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildStepWriteStateData>>;
/** Generated Node Admin SDK operation action function for the 'GetBuildStepWriteState' Query. Allow users to pass in custom DataConnect instances. */
export function getBuildStepWriteState(
  vars: GetBuildStepWriteStateVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildStepWriteStateData>>;

/** Generated Node Admin SDK operation action function for the 'GetBuildLogState' Query. Allow users to execute without passing in DataConnect. */
export function getBuildLogState(
  dc: DataConnect,
  vars: GetBuildLogStateVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildLogStateData>>;
/** Generated Node Admin SDK operation action function for the 'GetBuildLogState' Query. Allow users to pass in custom DataConnect instances. */
export function getBuildLogState(
  vars: GetBuildLogStateVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildLogStateData>>;

/** Generated Node Admin SDK operation action function for the 'GetExpiredBuildLogs' Query. Allow users to execute without passing in DataConnect. */
export function getExpiredBuildLogs(
  dc: DataConnect,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetExpiredBuildLogsData>>;
/** Generated Node Admin SDK operation action function for the 'GetExpiredBuildLogs' Query. Allow users to pass in custom DataConnect instances. */
export function getExpiredBuildLogs(
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetExpiredBuildLogsData>>;

/** Generated Node Admin SDK operation action function for the 'DeleteExpiredBuildLogs' Mutation. Allow users to execute without passing in DataConnect. */
export function deleteExpiredBuildLogs(
  dc: DataConnect,
  vars: DeleteExpiredBuildLogsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<DeleteExpiredBuildLogsData>>;
/** Generated Node Admin SDK operation action function for the 'DeleteExpiredBuildLogs' Mutation. Allow users to pass in custom DataConnect instances. */
export function deleteExpiredBuildLogs(
  vars: DeleteExpiredBuildLogsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<DeleteExpiredBuildLogsData>>;

/** Generated Node Admin SDK operation action function for the 'CreateBuildStep' Mutation. Allow users to execute without passing in DataConnect. */
export function createBuildStep(
  dc: DataConnect,
  vars: CreateBuildStepVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateBuildStepData>>;
/** Generated Node Admin SDK operation action function for the 'CreateBuildStep' Mutation. Allow users to pass in custom DataConnect instances. */
export function createBuildStep(
  vars: CreateBuildStepVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateBuildStepData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateBuildStep' Mutation. Allow users to execute without passing in DataConnect. */
export function updateBuildStep(
  dc: DataConnect,
  vars: UpdateBuildStepVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<UpdateBuildStepData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateBuildStep' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateBuildStep(
  vars: UpdateBuildStepVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<UpdateBuildStepData>>;
