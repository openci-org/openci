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

export interface AcquireBuildDispatchLaunchData {
  acquired: number;
}

export interface AcquireBuildDispatchLaunchVariables {
  id: string;
  owner: string;
}

export interface AcquireBuildDispatchSchedulerData {
  acquired: number;
}

export interface AcquireBuildDispatchSchedulerVariables {
  owner: string;
}

export interface AcquireBuildExecutionCleanupData {
  acquired: number;
}

export interface AcquireBuildExecutionCleanupVariables {
  id: string;
  owner: string;
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

export interface CancelUnstartedBuildDispatchData {
  buildJobDispatch_updateMany: number;
}

export interface CancelUnstartedBuildDispatchVariables {
  jobId: string;
}

export interface ClaimBuildJobExecutionData {
  buildJob_updateMany: number;
  acquired: number;
}

export interface ClaimBuildJobExecutionVariables {
  id: string;
  executorId: string;
  executionName: string;
  timeoutSeconds?: number;
}

export interface CompleteBuildExecutionData {
  buildJob_updateMany: number;
  completed: number;
  buildRun_updateMany: number;
  buildStep_updateMany: number;
  buildJobDispatch_updateMany: number;
}

export interface CompleteBuildExecutionVariables {
  id: string;
  jobId: string;
  owner: string;
}

export interface ConfigureBuildExecutionRunData {
  buildJob_updateMany: number;
  buildRun_updateMany: number;
}

export interface ConfigureBuildExecutionRunVariables {
  id: string;
  jobId: string;
  executorId: string;
}

export interface ConfirmBuildVmDeletedData {
  buildJobDispatch_updateMany: number;
}

export interface ConfirmBuildVmDeletedVariables {
  id: string;
  owner: string;
}

export interface ExpireUnstartedBuildDispatchesData {
  buildJobDispatch_updateMany: number;
}

export interface FinishBuildJobDispatchData {
  buildJobDispatch_updateMany: number;
}

export interface FinishBuildJobDispatchVariables {
  id: string;
  jobId: string;
  executorId: string;
}

export interface GetActiveBuildDispatchesData {
  dispatches: ({
    id: string;
    jobId: string;
    teamId?: string | null;
    activeJobId?: string | null;
    vmName: string;
    cpu: number;
    memoryMiB: number;
    image: string;
    cloudRunJob: string;
    state: string;
    launchOwner?: string | null;
    launchLeaseUntil?: TimestampString | null;
    operationName?: string | null;
    executionName?: string | null;
    executorId?: string | null;
    runId?: string | null;
    checkRunId?: string | null;
    startedAt?: TimestampString | null;
    heartbeatAt?: TimestampString | null;
    deadlineAt?: TimestampString | null;
    outcome?: string | null;
    resultAt?: TimestampString | null;
    vmRequestedAt?: TimestampString | null;
    vmDeletedAt?: TimestampString | null;
    cleanupOwner?: string | null;
    cleanupLeaseUntil?: TimestampString | null;
    startDeadline: TimestampString;
    createdAt: TimestampString;
    updatedAt: TimestampString;
    finishedAt?: TimestampString | null;
  } & BuildJobDispatch_Key)[];
}

export interface GetBuildDispatchStateData {
  job?: {
    id: string;
    status: string;
    runsOn?: string | null;
  } & BuildJob_Key;
  dispatch?: {
    id: string;
    jobId: string;
    teamId?: string | null;
    activeJobId?: string | null;
    vmName: string;
    cpu: number;
    memoryMiB: number;
    image: string;
    cloudRunJob: string;
    state: string;
    launchOwner?: string | null;
    launchLeaseUntil?: TimestampString | null;
    operationName?: string | null;
    executionName?: string | null;
    executorId?: string | null;
    runId?: string | null;
    checkRunId?: string | null;
    startedAt?: TimestampString | null;
    heartbeatAt?: TimestampString | null;
    deadlineAt?: TimestampString | null;
    outcome?: string | null;
    resultAt?: TimestampString | null;
    vmRequestedAt?: TimestampString | null;
    vmDeletedAt?: TimestampString | null;
    cleanupOwner?: string | null;
    cleanupLeaseUntil?: TimestampString | null;
    startDeadline: TimestampString;
    createdAt: TimestampString;
    updatedAt: TimestampString;
    finishedAt?: TimestampString | null;
  } & BuildJobDispatch_Key;
}

export interface GetBuildDispatchStateVariables {
  jobId: string;
}

export interface GetBuildExecutionData {
  dispatch?: {
    id: string;
    jobId: string;
    teamId?: string | null;
    activeJobId?: string | null;
    vmName: string;
    cpu: number;
    memoryMiB: number;
    image: string;
    cloudRunJob: string;
    state: string;
    launchOwner?: string | null;
    launchLeaseUntil?: TimestampString | null;
    operationName?: string | null;
    executionName?: string | null;
    executorId?: string | null;
    runId?: string | null;
    checkRunId?: string | null;
    startedAt?: TimestampString | null;
    heartbeatAt?: TimestampString | null;
    deadlineAt?: TimestampString | null;
    outcome?: string | null;
    resultAt?: TimestampString | null;
    vmRequestedAt?: TimestampString | null;
    vmDeletedAt?: TimestampString | null;
    cleanupOwner?: string | null;
    cleanupLeaseUntil?: TimestampString | null;
    startDeadline: TimestampString;
    createdAt: TimestampString;
    updatedAt: TimestampString;
    finishedAt?: TimestampString | null;
  } & BuildJobDispatch_Key;
  job?: {
    id: string;
    teamId?: string | null;
    status: string;
    owner: string;
    repo: string;
    workflowName: string;
    workflowFileName: string;
    commitSha?: string | null;
    branch?: string | null;
    installationId?: string | null;
    githubBaseUrl?: string | null;
    latestRunId?: string | null;
    workerHost?: string | null;
    runCount?: Int64String | null;
  } & BuildJob_Key;
  run?: {
    id: string;
    runNumber?: Int64String | null;
    status: string;
    conclusion?: string | null;
  } & BuildRun_Key;
}

export interface GetBuildExecutionSecretsData {
  secrets: {
    name: string;
    secretVersionPath: string;
  }[];
}

export interface GetBuildExecutionSecretsVariables {
  teamId: string;
}

export interface GetBuildExecutionVariables {
  id: string;
  jobId: string;
  runId: string;
}

export interface GetBuildExecutorContextData {
  team?: {
    id: string;
  } & Team_Key;
  connection?: {
    id: string;
    accountId: Int64String;
    accountLogin: string;
  } & GitHubConnection_Key;
  customer?: {
    stripeCustomerId?: string | null;
    livemode: boolean;
  };
  stripe?: {
    stripeCustomerId: string;
    livemode: boolean;
    stripeSubscriptionId?: string | null;
    subscriptionStatus: string;
    planId?: string | null;
    paidPeriodId?: string | null;
    paidPeriod?: {
      id: string;
      teamId: string;
      planId: string;
      periodType: string;
      startsAt: Int64String;
      endsAt: Int64String;
      allowanceSeconds?: Int64String | null;
    } & BillingPeriod_Key;
  };
}

export interface GetBuildExecutorContextVariables {
  teamId: string;
  installationId: Int64String;
  appId: Int64String;
  apiBaseUrl: string;
}

export interface GetBuildJobDispatchData {
  dispatch?: {
    id: string;
    jobId: string;
    teamId?: string | null;
    activeJobId?: string | null;
    vmName: string;
    cpu: number;
    memoryMiB: number;
    image: string;
    cloudRunJob: string;
    state: string;
    launchOwner?: string | null;
    launchLeaseUntil?: TimestampString | null;
    operationName?: string | null;
    executionName?: string | null;
    executorId?: string | null;
    runId?: string | null;
    checkRunId?: string | null;
    startedAt?: TimestampString | null;
    heartbeatAt?: TimestampString | null;
    deadlineAt?: TimestampString | null;
    outcome?: string | null;
    resultAt?: TimestampString | null;
    vmRequestedAt?: TimestampString | null;
    vmDeletedAt?: TimestampString | null;
    cleanupOwner?: string | null;
    cleanupLeaseUntil?: TimestampString | null;
    startDeadline: TimestampString;
    createdAt: TimestampString;
    updatedAt: TimestampString;
    finishedAt?: TimestampString | null;
  } & BuildJobDispatch_Key;
}

export interface GetBuildJobDispatchVariables {
  id: string;
}

export interface GetFinishedBuildExecutionsForVmsData {
  dispatches: ({
    id: string;
    vmName: string;
  } & BuildJobDispatch_Key)[];
}

export interface GetFinishedBuildExecutionsForVmsVariables {
  vmNames: string[];
}

export interface GetRecoverableBuildExecutionsData {
  dispatches: ({
    id: string;
    jobId: string;
    teamId?: string | null;
    activeJobId?: string | null;
    vmName: string;
    cpu: number;
    memoryMiB: number;
    image: string;
    cloudRunJob: string;
    state: string;
    launchOwner?: string | null;
    launchLeaseUntil?: TimestampString | null;
    operationName?: string | null;
    executionName?: string | null;
    executorId?: string | null;
    runId?: string | null;
    checkRunId?: string | null;
    startedAt?: TimestampString | null;
    heartbeatAt?: TimestampString | null;
    deadlineAt?: TimestampString | null;
    outcome?: string | null;
    resultAt?: TimestampString | null;
    vmRequestedAt?: TimestampString | null;
    vmDeletedAt?: TimestampString | null;
    cleanupOwner?: string | null;
    cleanupLeaseUntil?: TimestampString | null;
    startDeadline: TimestampString;
    createdAt: TimestampString;
    updatedAt: TimestampString;
    finishedAt?: TimestampString | null;
  } & BuildJobDispatch_Key)[];
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

export interface HeartbeatBuildExecutionData {
  updated: number;
}

export interface HeartbeatBuildExecutionVariables {
  id: string;
  executorId: string;
}

export interface InitializeBuildDispatchSchedulerData {
  buildDispatchScheduler_upsert: BuildDispatchScheduler_Key;
}

export interface MarkBuildVmRequestedData {
  buildJobDispatch_updateMany: number;
}

export interface MarkBuildVmRequestedVariables {
  id: string;
  executorId: string;
}

export interface RecordBuildDispatchLaunchData {
  buildJobDispatch_updateMany: number;
}

export interface RecordBuildDispatchLaunchVariables {
  id: string;
  owner: string;
  operationName: string;
}

export interface RecordBuildExecutionCheckData {
  buildJobDispatch_updateMany: number;
}

export interface RecordBuildExecutionCheckVariables {
  id: string;
  checkRunId: string;
}

export interface RecordBuildExecutionResultData {
  updated: number;
}

export interface RecordBuildExecutionResultVariables {
  id: string;
  executorId: string;
  outcome: string;
}

export interface ReleaseBuildDispatchSchedulerData {
  buildDispatchScheduler_updateMany: number;
}

export interface ReleaseBuildDispatchSchedulerVariables {
  owner: string;
}

export interface ReserveBuildJobDispatchData {
  buildDispatchScheduler_updateMany: number;
  buildJob_updateMany: number;
  buildJobDispatch_insert: BuildJobDispatch_Key;
}

export interface ReserveBuildJobDispatchVariables {
  owner: string;
  id: string;
  jobId: string;
  vmName: string;
  cpu: number;
  memoryMiB: number;
  image: string;
  cloudRunJob: string;
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

/** Generated Node Admin SDK operation action function for the 'GetBuildDispatchState' Query. Allow users to execute without passing in DataConnect. */
export function getBuildDispatchState(
  dc: DataConnect,
  vars: GetBuildDispatchStateVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildDispatchStateData>>;
/** Generated Node Admin SDK operation action function for the 'GetBuildDispatchState' Query. Allow users to pass in custom DataConnect instances. */
export function getBuildDispatchState(
  vars: GetBuildDispatchStateVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildDispatchStateData>>;

/** Generated Node Admin SDK operation action function for the 'GetBuildJobDispatch' Query. Allow users to execute without passing in DataConnect. */
export function getBuildJobDispatch(
  dc: DataConnect,
  vars: GetBuildJobDispatchVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildJobDispatchData>>;
/** Generated Node Admin SDK operation action function for the 'GetBuildJobDispatch' Query. Allow users to pass in custom DataConnect instances. */
export function getBuildJobDispatch(
  vars: GetBuildJobDispatchVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildJobDispatchData>>;

/** Generated Node Admin SDK operation action function for the 'GetActiveBuildDispatches' Query. Allow users to execute without passing in DataConnect. */
export function getActiveBuildDispatches(
  dc: DataConnect,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetActiveBuildDispatchesData>>;
/** Generated Node Admin SDK operation action function for the 'GetActiveBuildDispatches' Query. Allow users to pass in custom DataConnect instances. */
export function getActiveBuildDispatches(
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetActiveBuildDispatchesData>>;

/** Generated Node Admin SDK operation action function for the 'InitializeBuildDispatchScheduler' Mutation. Allow users to execute without passing in DataConnect. */
export function initializeBuildDispatchScheduler(
  dc: DataConnect,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<InitializeBuildDispatchSchedulerData>>;
/** Generated Node Admin SDK operation action function for the 'InitializeBuildDispatchScheduler' Mutation. Allow users to pass in custom DataConnect instances. */
export function initializeBuildDispatchScheduler(
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<InitializeBuildDispatchSchedulerData>>;

/** Generated Node Admin SDK operation action function for the 'AcquireBuildDispatchScheduler' Mutation. Allow users to execute without passing in DataConnect. */
export function acquireBuildDispatchScheduler(
  dc: DataConnect,
  vars: AcquireBuildDispatchSchedulerVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<AcquireBuildDispatchSchedulerData>>;
/** Generated Node Admin SDK operation action function for the 'AcquireBuildDispatchScheduler' Mutation. Allow users to pass in custom DataConnect instances. */
export function acquireBuildDispatchScheduler(
  vars: AcquireBuildDispatchSchedulerVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<AcquireBuildDispatchSchedulerData>>;

/** Generated Node Admin SDK operation action function for the 'ReleaseBuildDispatchScheduler' Mutation. Allow users to execute without passing in DataConnect. */
export function releaseBuildDispatchScheduler(
  dc: DataConnect,
  vars: ReleaseBuildDispatchSchedulerVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ReleaseBuildDispatchSchedulerData>>;
/** Generated Node Admin SDK operation action function for the 'ReleaseBuildDispatchScheduler' Mutation. Allow users to pass in custom DataConnect instances. */
export function releaseBuildDispatchScheduler(
  vars: ReleaseBuildDispatchSchedulerVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ReleaseBuildDispatchSchedulerData>>;

/** Generated Node Admin SDK operation action function for the 'ReserveBuildJobDispatch' Mutation. Allow users to execute without passing in DataConnect. */
export function reserveBuildJobDispatch(
  dc: DataConnect,
  vars: ReserveBuildJobDispatchVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ReserveBuildJobDispatchData>>;
/** Generated Node Admin SDK operation action function for the 'ReserveBuildJobDispatch' Mutation. Allow users to pass in custom DataConnect instances. */
export function reserveBuildJobDispatch(
  vars: ReserveBuildJobDispatchVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ReserveBuildJobDispatchData>>;

/** Generated Node Admin SDK operation action function for the 'ExpireUnstartedBuildDispatches' Mutation. Allow users to execute without passing in DataConnect. */
export function expireUnstartedBuildDispatches(
  dc: DataConnect,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ExpireUnstartedBuildDispatchesData>>;
/** Generated Node Admin SDK operation action function for the 'ExpireUnstartedBuildDispatches' Mutation. Allow users to pass in custom DataConnect instances. */
export function expireUnstartedBuildDispatches(
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ExpireUnstartedBuildDispatchesData>>;

/** Generated Node Admin SDK operation action function for the 'CancelUnstartedBuildDispatch' Mutation. Allow users to execute without passing in DataConnect. */
export function cancelUnstartedBuildDispatch(
  dc: DataConnect,
  vars: CancelUnstartedBuildDispatchVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CancelUnstartedBuildDispatchData>>;
/** Generated Node Admin SDK operation action function for the 'CancelUnstartedBuildDispatch' Mutation. Allow users to pass in custom DataConnect instances. */
export function cancelUnstartedBuildDispatch(
  vars: CancelUnstartedBuildDispatchVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CancelUnstartedBuildDispatchData>>;

/** Generated Node Admin SDK operation action function for the 'AcquireBuildDispatchLaunch' Mutation. Allow users to execute without passing in DataConnect. */
export function acquireBuildDispatchLaunch(
  dc: DataConnect,
  vars: AcquireBuildDispatchLaunchVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<AcquireBuildDispatchLaunchData>>;
/** Generated Node Admin SDK operation action function for the 'AcquireBuildDispatchLaunch' Mutation. Allow users to pass in custom DataConnect instances. */
export function acquireBuildDispatchLaunch(
  vars: AcquireBuildDispatchLaunchVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<AcquireBuildDispatchLaunchData>>;

/** Generated Node Admin SDK operation action function for the 'RecordBuildDispatchLaunch' Mutation. Allow users to execute without passing in DataConnect. */
export function recordBuildDispatchLaunch(
  dc: DataConnect,
  vars: RecordBuildDispatchLaunchVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RecordBuildDispatchLaunchData>>;
/** Generated Node Admin SDK operation action function for the 'RecordBuildDispatchLaunch' Mutation. Allow users to pass in custom DataConnect instances. */
export function recordBuildDispatchLaunch(
  vars: RecordBuildDispatchLaunchVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RecordBuildDispatchLaunchData>>;

/** Generated Node Admin SDK operation action function for the 'ClaimBuildJobExecution' Mutation. Allow users to execute without passing in DataConnect. */
export function claimBuildJobExecution(
  dc: DataConnect,
  vars: ClaimBuildJobExecutionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ClaimBuildJobExecutionData>>;
/** Generated Node Admin SDK operation action function for the 'ClaimBuildJobExecution' Mutation. Allow users to pass in custom DataConnect instances. */
export function claimBuildJobExecution(
  vars: ClaimBuildJobExecutionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ClaimBuildJobExecutionData>>;

/** Generated Node Admin SDK operation action function for the 'FinishBuildJobDispatch' Mutation. Allow users to execute without passing in DataConnect. */
export function finishBuildJobDispatch(
  dc: DataConnect,
  vars: FinishBuildJobDispatchVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<FinishBuildJobDispatchData>>;
/** Generated Node Admin SDK operation action function for the 'FinishBuildJobDispatch' Mutation. Allow users to pass in custom DataConnect instances. */
export function finishBuildJobDispatch(
  vars: FinishBuildJobDispatchVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<FinishBuildJobDispatchData>>;

/** Generated Node Admin SDK operation action function for the 'GetBuildExecution' Query. Allow users to execute without passing in DataConnect. */
export function getBuildExecution(
  dc: DataConnect,
  vars: GetBuildExecutionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildExecutionData>>;
/** Generated Node Admin SDK operation action function for the 'GetBuildExecution' Query. Allow users to pass in custom DataConnect instances. */
export function getBuildExecution(
  vars: GetBuildExecutionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildExecutionData>>;

/** Generated Node Admin SDK operation action function for the 'GetBuildExecutorContext' Query. Allow users to execute without passing in DataConnect. */
export function getBuildExecutorContext(
  dc: DataConnect,
  vars: GetBuildExecutorContextVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildExecutorContextData>>;
/** Generated Node Admin SDK operation action function for the 'GetBuildExecutorContext' Query. Allow users to pass in custom DataConnect instances. */
export function getBuildExecutorContext(
  vars: GetBuildExecutorContextVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildExecutorContextData>>;

/** Generated Node Admin SDK operation action function for the 'GetBuildExecutionSecrets' Query. Allow users to execute without passing in DataConnect. */
export function getBuildExecutionSecrets(
  dc: DataConnect,
  vars: GetBuildExecutionSecretsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildExecutionSecretsData>>;
/** Generated Node Admin SDK operation action function for the 'GetBuildExecutionSecrets' Query. Allow users to pass in custom DataConnect instances. */
export function getBuildExecutionSecrets(
  vars: GetBuildExecutionSecretsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBuildExecutionSecretsData>>;

/** Generated Node Admin SDK operation action function for the 'ConfigureBuildExecutionRun' Mutation. Allow users to execute without passing in DataConnect. */
export function configureBuildExecutionRun(
  dc: DataConnect,
  vars: ConfigureBuildExecutionRunVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ConfigureBuildExecutionRunData>>;
/** Generated Node Admin SDK operation action function for the 'ConfigureBuildExecutionRun' Mutation. Allow users to pass in custom DataConnect instances. */
export function configureBuildExecutionRun(
  vars: ConfigureBuildExecutionRunVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ConfigureBuildExecutionRunData>>;

/** Generated Node Admin SDK operation action function for the 'HeartbeatBuildExecution' Mutation. Allow users to execute without passing in DataConnect. */
export function heartbeatBuildExecution(
  dc: DataConnect,
  vars: HeartbeatBuildExecutionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<HeartbeatBuildExecutionData>>;
/** Generated Node Admin SDK operation action function for the 'HeartbeatBuildExecution' Mutation. Allow users to pass in custom DataConnect instances. */
export function heartbeatBuildExecution(
  vars: HeartbeatBuildExecutionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<HeartbeatBuildExecutionData>>;

/** Generated Node Admin SDK operation action function for the 'MarkBuildVmRequested' Mutation. Allow users to execute without passing in DataConnect. */
export function markBuildVmRequested(
  dc: DataConnect,
  vars: MarkBuildVmRequestedVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<MarkBuildVmRequestedData>>;
/** Generated Node Admin SDK operation action function for the 'MarkBuildVmRequested' Mutation. Allow users to pass in custom DataConnect instances. */
export function markBuildVmRequested(
  vars: MarkBuildVmRequestedVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<MarkBuildVmRequestedData>>;

/** Generated Node Admin SDK operation action function for the 'RecordBuildExecutionCheck' Mutation. Allow users to execute without passing in DataConnect. */
export function recordBuildExecutionCheck(
  dc: DataConnect,
  vars: RecordBuildExecutionCheckVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RecordBuildExecutionCheckData>>;
/** Generated Node Admin SDK operation action function for the 'RecordBuildExecutionCheck' Mutation. Allow users to pass in custom DataConnect instances. */
export function recordBuildExecutionCheck(
  vars: RecordBuildExecutionCheckVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RecordBuildExecutionCheckData>>;

/** Generated Node Admin SDK operation action function for the 'RecordBuildExecutionResult' Mutation. Allow users to execute without passing in DataConnect. */
export function recordBuildExecutionResult(
  dc: DataConnect,
  vars: RecordBuildExecutionResultVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RecordBuildExecutionResultData>>;
/** Generated Node Admin SDK operation action function for the 'RecordBuildExecutionResult' Mutation. Allow users to pass in custom DataConnect instances. */
export function recordBuildExecutionResult(
  vars: RecordBuildExecutionResultVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RecordBuildExecutionResultData>>;

/** Generated Node Admin SDK operation action function for the 'GetRecoverableBuildExecutions' Query. Allow users to execute without passing in DataConnect. */
export function getRecoverableBuildExecutions(
  dc: DataConnect,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetRecoverableBuildExecutionsData>>;
/** Generated Node Admin SDK operation action function for the 'GetRecoverableBuildExecutions' Query. Allow users to pass in custom DataConnect instances. */
export function getRecoverableBuildExecutions(
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetRecoverableBuildExecutionsData>>;

/** Generated Node Admin SDK operation action function for the 'GetFinishedBuildExecutionsForVms' Query. Allow users to execute without passing in DataConnect. */
export function getFinishedBuildExecutionsForVms(
  dc: DataConnect,
  vars: GetFinishedBuildExecutionsForVmsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetFinishedBuildExecutionsForVmsData>>;
/** Generated Node Admin SDK operation action function for the 'GetFinishedBuildExecutionsForVms' Query. Allow users to pass in custom DataConnect instances. */
export function getFinishedBuildExecutionsForVms(
  vars: GetFinishedBuildExecutionsForVmsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetFinishedBuildExecutionsForVmsData>>;

/** Generated Node Admin SDK operation action function for the 'AcquireBuildExecutionCleanup' Mutation. Allow users to execute without passing in DataConnect. */
export function acquireBuildExecutionCleanup(
  dc: DataConnect,
  vars: AcquireBuildExecutionCleanupVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<AcquireBuildExecutionCleanupData>>;
/** Generated Node Admin SDK operation action function for the 'AcquireBuildExecutionCleanup' Mutation. Allow users to pass in custom DataConnect instances. */
export function acquireBuildExecutionCleanup(
  vars: AcquireBuildExecutionCleanupVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<AcquireBuildExecutionCleanupData>>;

/** Generated Node Admin SDK operation action function for the 'ConfirmBuildVmDeleted' Mutation. Allow users to execute without passing in DataConnect. */
export function confirmBuildVmDeleted(
  dc: DataConnect,
  vars: ConfirmBuildVmDeletedVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ConfirmBuildVmDeletedData>>;
/** Generated Node Admin SDK operation action function for the 'ConfirmBuildVmDeleted' Mutation. Allow users to pass in custom DataConnect instances. */
export function confirmBuildVmDeleted(
  vars: ConfirmBuildVmDeletedVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ConfirmBuildVmDeletedData>>;

/** Generated Node Admin SDK operation action function for the 'CompleteBuildExecution' Mutation. Allow users to execute without passing in DataConnect. */
export function completeBuildExecution(
  dc: DataConnect,
  vars: CompleteBuildExecutionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CompleteBuildExecutionData>>;
/** Generated Node Admin SDK operation action function for the 'CompleteBuildExecution' Mutation. Allow users to pass in custom DataConnect instances. */
export function completeBuildExecution(
  vars: CompleteBuildExecutionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CompleteBuildExecutionData>>;
