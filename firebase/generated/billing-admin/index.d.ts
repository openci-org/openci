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

export interface BindBillingAdmissionRunData {
  billingAccount_updateMany: number;
  billingAdmission_updateMany: number;
  buildJob_updateMany: number;
  buildRun_insert: BuildRun_Key;
}

export interface BindBillingAdmissionRunVariables {
  id: string;
  teamId: string;
  jobId: string;
  workerHost: string;
  runId: string;
  expectedUsageRevision: Int64String;
  atMs: Int64String;
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

export interface CloseBillingCheckoutCreationData {
  billingCheckoutCreation_updateMany: number;
}

export interface CloseBillingCheckoutCreationVariables {
  idempotencyKey: string;
  teamId: string;
  stripeCustomerId: string;
  livemode: boolean;
  stripeCheckoutSessionId: string;
  closedAt: Int64String;
}

export interface CreateBillingAdmissionData {
  billingAccount_updateMany: number;
  buildJob_updateMany: number;
  billingAdmission_insert: BillingAdmission_Key;
}

export interface CreateBillingAdmissionVariables {
  id: string;
  teamId: string;
  jobId: string;
  workerHost: string;
  periodId: string;
  atMs: Int64String;
  vmName?: string | null;
}

export interface CreateBillingCheckoutCreationData {
  billingCheckoutCreation_insert: BillingCheckoutCreation_Key;
}

export interface CreateBillingCheckoutCreationVariables {
  idempotencyKey: string;
  teamId: string;
  planId: string;
  stripeCustomerId: string;
  stripePriceId: string;
  successUrl: string;
  cancelUrl: string;
  livemode: boolean;
  createdAt: Int64String;
}

export interface CreateBillingCustomerCreationData {
  billingAccount_upsert: BillingAccount_Key;
  billingCustomerCreation_insert: BillingCustomerCreation_Key;
}

export interface CreateBillingCustomerCreationVariables {
  teamId: string;
  idempotencyKey: string;
  livemode: boolean;
  createdAt: Int64String;
}

export interface CreateBillingPeriodData {
  billingAccount_upsert: BillingAccount_Key;
  billingPeriod_insert: BillingPeriod_Key;
}

export interface CreateBillingPeriodVariables {
  id: string;
  teamId: string;
  planId: string;
  periodType: string;
  startsAt: Int64String;
  endsAt: Int64String;
  allowanceSeconds?: Int64String | null;
}

export interface DeleteBillingTeamData {
  billingAccount_upsert: BillingAccount_Key;
  cleanup?: {
    secrets: {
      secretVersionPath: string;
    }[];
    requests: {
      codeVerifierSecretVersionPath: string;
    }[];
    sessions: {
      accessTokenSecretVersionPath?: string | null;
    }[];
  };
  team_delete?: Team_Key | null;
}

export interface DeleteBillingTeamVariables {
  teamId: string;
  userId: string;
  livemode: boolean;
  expectedCustomerCreationKey?: string | null;
  expectedStripeCustomerId?: string | null;
  expectedStripeRevision?: Int64String | null;
}

export interface ExpireBillingAdmissionData {
  billingAccount_updateMany: number;
  buildJob_updateMany: number;
  buildRun_updateMany: number;
  billingAdmission_update?: BillingAdmission_Key | null;
}

export interface ExpireBillingAdmissionVariables {
  id: string;
  teamId: string;
  runId?: string | null;
  expectedUsageRevision: Int64String;
  atMs: Int64String;
}

export interface ExpireBillingExecutionData {
  billingAccount_updateMany: number;
  billingExecution_update?: BillingExecution_Key | null;
  billingAdmission_updateMany: number;
}

export interface ExpireBillingExecutionVariables {
  teamId: string;
  runId: string;
  expectedUsageRevision: Int64String;
  atMs: Int64String;
}

export interface FinishBillingExecutionData {
  billingAccount_updateMany: number;
  buildJob_updateMany: number;
  billingExecution_update?: BillingExecution_Key | null;
  billingAdmission_updateMany: number;
}

export interface FinishBillingExecutionVariables {
  teamId: string;
  jobId: string;
  workerHost: string;
  runId: string;
  expectedUsageRevision: Int64String;
  atMs: Int64String;
  outcome: string;
}

export interface GetBillingAdmissionData {
  billingAccount?: {
    usageRevision: Int64String;
  };
  billingAdmission?: {
    id: string;
    teamId: string;
    jobId: string;
    workerHost: string;
    periodId: string;
    claimedAtMs: Int64String;
    startByMs: Int64String;
    reservedMillis: Int64String;
    runId?: string | null;
    closedAtMs?: Int64String | null;
    openJobId?: string | null;
  } & BillingAdmission_Key;
}

export interface GetBillingAdmissionVariables {
  teamId: string;
  id: string;
}

export interface GetBillingCheckoutCreationData {
  checkout?: {
    idempotencyKey: string;
    teamId: string;
    planId: string;
    stripeCustomerId: string;
    stripePriceId: string;
    successUrl: string;
    cancelUrl: string;
    livemode: boolean;
    createdAt: Int64String;
    stripeCheckoutSessionId?: string | null;
    closedAt?: Int64String | null;
    openTeamId?: string | null;
  } & BillingCheckoutCreation_Key;
}

export interface GetBillingCheckoutCreationVariables {
  teamId: string;
  idempotencyKey: string;
  livemode: boolean;
}

export interface GetBillingContextData {
  account?: {
    usageRevision: Int64String;
  };
  customer?: {
    teamId: string;
    idempotencyKey: string;
    livemode: boolean;
    createdAt: Int64String;
    stripeCustomerId?: string | null;
  } & BillingCustomerCreation_Key;
  stripe?: {
    teamId: string;
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
    cancelAtPeriodEnd: boolean;
    syncedAt: Int64String;
    revision: Int64String;
  } & BillingStripeState_Key;
  checkout?: {
    idempotencyKey: string;
    teamId: string;
    planId: string;
    stripeCustomerId: string;
    stripePriceId: string;
    successUrl: string;
    cancelUrl: string;
    livemode: boolean;
    createdAt: Int64String;
    stripeCheckoutSessionId?: string | null;
    closedAt?: Int64String | null;
    openTeamId?: string | null;
  } & BillingCheckoutCreation_Key;
}

export interface GetBillingContextVariables {
  teamId: string;
  userId: string;
}

export interface GetBillingCustomerByStripeIdData {
  customer?: {
    teamId: string;
    idempotencyKey: string;
    livemode: boolean;
    createdAt: Int64String;
    stripeCustomerId?: string | null;
  } & BillingCustomerCreation_Key;
}

export interface GetBillingCustomerByStripeIdVariables {
  stripeCustomerId: string;
  livemode: boolean;
}

export interface GetBillingCustomerCreationData {
  billingCustomerCreation?: {
    teamId: string;
    idempotencyKey: string;
    livemode: boolean;
    createdAt: Int64String;
    stripeCustomerId?: string | null;
  } & BillingCustomerCreation_Key;
}

export interface GetBillingCustomerCreationVariables {
  teamId: string;
  livemode: boolean;
}

export interface GetBillingExecutionData {
  billingAccount?: {
    usageRevision: Int64String;
  };
  billingExecution?: {
    runId: string;
    teamId: string;
    jobId: string;
    workerHost: string;
    periodId: string;
    startedAtMs: Int64String;
    observedAtMs: Int64String;
    leaseUntilMs: Int64String;
    finishedAtMs?: Int64String | null;
    outcome?: string | null;
    measurementIncomplete: boolean;
  } & BillingExecution_Key;
}

export interface GetBillingExecutionVariables {
  teamId: string;
  runId: string;
}

export interface GetBillingJobData {
  job?: {
    id: string;
    teamId?: string | null;
    status: string;
    workerHost?: string | null;
    latestRunId?: string | null;
  } & BuildJob_Key;
}

export interface GetBillingJobVariables {
  id: string;
}

export interface GetBillingPeriodData {
  period?: {
    id: string;
    teamId: string;
    planId: string;
    periodType: string;
    startsAt: Int64String;
    endsAt: Int64String;
    allowanceSeconds?: Int64String | null;
  } & BillingPeriod_Key;
}

export interface GetBillingPeriodUsageData {
  usage?: unknown | null;
}

export interface GetBillingPeriodUsageVariables {
  teamId: string;
  periodId: string;
  atMs: Int64String;
}

export interface GetBillingPeriodVariables {
  teamId: string;
  id: string;
}

export interface GetBillingStripeEventData {
  billingStripeEvent?: {
    eventId: string;
    eventType: string;
    eventCreated: Int64String;
    processedAt: Int64String;
  } & BillingStripeEvent_Key;
}

export interface GetBillingStripeEventVariables {
  eventId: string;
}

export interface GetBillingStripeStateData {
  billingStripeState?: {
    teamId: string;
    stripeCustomerId: string;
    livemode: boolean;
    stripeSubscriptionId?: string | null;
    subscriptionStatus: string;
    planId?: string | null;
    paidPeriodId?: string | null;
    paidPeriod?: {
      endsAt: Int64String;
    };
    cancelAtPeriodEnd: boolean;
    syncedAt: Int64String;
    revision: Int64String;
  } & BillingStripeState_Key;
}

export interface GetBillingStripeStateVariables {
  teamId: string;
  livemode: boolean;
}

export interface GetBillingTrialEligibilityData {
  userClaim?: {
    teamId: string;
    claimedAt: Int64String;
  };
  teamClaim?: {
    userId: string;
    claimedAt: Int64String;
  } & BillingTrialClaim_Key;
  activePaidPeriod?: {
    id: string;
  } & BillingPeriod_Key;
}

export interface GetBillingTrialEligibilityVariables {
  teamId: string;
  userId: string;
}

export interface GetBillingWorkerJobsData {
  jobs: ({
    id: string;
    teamId?: string | null;
    latestRunId?: string | null;
  } & BuildJob_Key)[];
}

export interface GetBillingWorkerJobsVariables {
  workerHost: string;
}

export interface GetExpiredBillingWorkData {
  billingExecutions: ({
    runId: string;
    teamId: string;
    jobId: string;
    workerHost: string;
    periodId: string;
    startedAtMs: Int64String;
    observedAtMs: Int64String;
    leaseUntilMs: Int64String;
    finishedAtMs?: Int64String | null;
    outcome?: string | null;
    measurementIncomplete: boolean;
  } & BillingExecution_Key)[];
  admissions?: unknown[] | null;
}

export interface GetExpiredBillingWorkVariables {
  atMs: Int64String;
}

export interface GetOpenBillingCheckoutCreationData {
  billingCheckoutCreation?: {
    idempotencyKey: string;
    teamId: string;
    planId: string;
    stripeCustomerId: string;
    stripePriceId: string;
    successUrl: string;
    cancelUrl: string;
    livemode: boolean;
    createdAt: Int64String;
    stripeCheckoutSessionId?: string | null;
  } & BillingCheckoutCreation_Key;
}

export interface GetOpenBillingCheckoutCreationVariables {
  teamId: string;
  livemode: boolean;
}

export interface GetQueuedBillingJobsData {
  jobs: ({
    id: string;
    teamId?: string | null;
    createdAt: Int64String;
  } & BuildJob_Key)[];
}

export interface GetQueuedBillingJobsVariables {
  afterCreatedAt?: Int64String;
  afterId?: string;
  excludedTeamIds?: string[];
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

export interface HeartbeatBillingExecutionData {
  billingAccount_updateMany: number;
  buildJob_updateMany: number;
  billingExecution_update?: BillingExecution_Key | null;
}

export interface HeartbeatBillingExecutionVariables {
  teamId: string;
  jobId: string;
  workerHost: string;
  runId: string;
  expectedUsageRevision: Int64String;
  atMs: Int64String;
}

export interface InitializeBillingStripeStateData {
  billingStripeState_insert: BillingStripeState_Key;
}

export interface InitializeBillingStripeStateVariables {
  teamId: string;
  stripeCustomerId: string;
  livemode: boolean;
}

export interface RecordBillingCheckoutSessionData {
  billingCheckoutCreation_updateMany: number;
}

export interface RecordBillingCheckoutSessionVariables {
  idempotencyKey: string;
  teamId: string;
  planId: string;
  stripeCustomerId: string;
  stripePriceId: string;
  successUrl: string;
  cancelUrl: string;
  livemode: boolean;
  createdAt: Int64String;
  stripeCheckoutSessionId: string;
}

export interface RecordBillingCustomerData {
  billingCustomerCreation_updateMany: number;
}

export interface RecordBillingCustomerVariables {
  teamId: string;
  idempotencyKey: string;
  livemode: boolean;
  stripeCustomerId: string;
}

export interface RecordBillingStripeEventData {
  billingStripeState_updateMany: number;
  billingStripeEvent_insert: BillingStripeEvent_Key;
}

export interface RecordBillingStripeEventVariables {
  teamId: string;
  stripeCustomerId: string;
  livemode: boolean;
  expectedRevision: Int64String;
  stripeSubscriptionId?: string | null;
  subscriptionStatus: string;
  planId?: string | null;
  paidPeriodId?: string | null;
  cancelAtPeriodEnd: boolean;
  eventId: string;
  eventType: string;
  eventCreated: Int64String;
  processedAt: Int64String;
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

export interface StartBillingExecutionData {
  billingAccount_updateMany: number;
  buildJob_updateMany: number;
  billingExecution_insert: BillingExecution_Key;
}

export interface StartBillingExecutionVariables {
  admissionId: string;
  teamId: string;
  jobId: string;
  workerHost: string;
  runId: string;
  expectedUsageRevision: Int64String;
  atMs: Int64String;
}

export interface StartBillingTrialData {
  billingAccount_upsert: BillingAccount_Key;
  billingTrialClaim_insert: BillingTrialClaim_Key;
  billingPeriod_insert: BillingPeriod_Key;
}

export interface StartBillingTrialVariables {
  teamId: string;
  userId: string;
  periodId: string;
  allowanceSeconds?: Int64String | null;
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

/** Generated Node Admin SDK operation action function for the 'GetBillingAdmission' Query. Allow users to execute without passing in DataConnect. */
export function getBillingAdmission(
  dc: DataConnect,
  vars: GetBillingAdmissionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingAdmissionData>>;
/** Generated Node Admin SDK operation action function for the 'GetBillingAdmission' Query. Allow users to pass in custom DataConnect instances. */
export function getBillingAdmission(
  vars: GetBillingAdmissionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingAdmissionData>>;

/** Generated Node Admin SDK operation action function for the 'CreateBillingAdmission' Mutation. Allow users to execute without passing in DataConnect. */
export function createBillingAdmission(
  dc: DataConnect,
  vars: CreateBillingAdmissionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateBillingAdmissionData>>;
/** Generated Node Admin SDK operation action function for the 'CreateBillingAdmission' Mutation. Allow users to pass in custom DataConnect instances. */
export function createBillingAdmission(
  vars: CreateBillingAdmissionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateBillingAdmissionData>>;

/** Generated Node Admin SDK operation action function for the 'BindBillingAdmissionRun' Mutation. Allow users to execute without passing in DataConnect. */
export function bindBillingAdmissionRun(
  dc: DataConnect,
  vars: BindBillingAdmissionRunVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<BindBillingAdmissionRunData>>;
/** Generated Node Admin SDK operation action function for the 'BindBillingAdmissionRun' Mutation. Allow users to pass in custom DataConnect instances. */
export function bindBillingAdmissionRun(
  vars: BindBillingAdmissionRunVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<BindBillingAdmissionRunData>>;

/** Generated Node Admin SDK operation action function for the 'ExpireBillingAdmission' Mutation. Allow users to execute without passing in DataConnect. */
export function expireBillingAdmission(
  dc: DataConnect,
  vars: ExpireBillingAdmissionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ExpireBillingAdmissionData>>;
/** Generated Node Admin SDK operation action function for the 'ExpireBillingAdmission' Mutation. Allow users to pass in custom DataConnect instances. */
export function expireBillingAdmission(
  vars: ExpireBillingAdmissionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ExpireBillingAdmissionData>>;

/** Generated Node Admin SDK operation action function for the 'CreateBillingCheckoutCreation' Mutation. Allow users to execute without passing in DataConnect. */
export function createBillingCheckoutCreation(
  dc: DataConnect,
  vars: CreateBillingCheckoutCreationVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateBillingCheckoutCreationData>>;
/** Generated Node Admin SDK operation action function for the 'CreateBillingCheckoutCreation' Mutation. Allow users to pass in custom DataConnect instances. */
export function createBillingCheckoutCreation(
  vars: CreateBillingCheckoutCreationVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateBillingCheckoutCreationData>>;

/** Generated Node Admin SDK operation action function for the 'GetOpenBillingCheckoutCreation' Query. Allow users to execute without passing in DataConnect. */
export function getOpenBillingCheckoutCreation(
  dc: DataConnect,
  vars: GetOpenBillingCheckoutCreationVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetOpenBillingCheckoutCreationData>>;
/** Generated Node Admin SDK operation action function for the 'GetOpenBillingCheckoutCreation' Query. Allow users to pass in custom DataConnect instances. */
export function getOpenBillingCheckoutCreation(
  vars: GetOpenBillingCheckoutCreationVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetOpenBillingCheckoutCreationData>>;

/** Generated Node Admin SDK operation action function for the 'RecordBillingCheckoutSession' Mutation. Allow users to execute without passing in DataConnect. */
export function recordBillingCheckoutSession(
  dc: DataConnect,
  vars: RecordBillingCheckoutSessionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RecordBillingCheckoutSessionData>>;
/** Generated Node Admin SDK operation action function for the 'RecordBillingCheckoutSession' Mutation. Allow users to pass in custom DataConnect instances. */
export function recordBillingCheckoutSession(
  vars: RecordBillingCheckoutSessionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RecordBillingCheckoutSessionData>>;

/** Generated Node Admin SDK operation action function for the 'CloseBillingCheckoutCreation' Mutation. Allow users to execute without passing in DataConnect. */
export function closeBillingCheckoutCreation(
  dc: DataConnect,
  vars: CloseBillingCheckoutCreationVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CloseBillingCheckoutCreationData>>;
/** Generated Node Admin SDK operation action function for the 'CloseBillingCheckoutCreation' Mutation. Allow users to pass in custom DataConnect instances. */
export function closeBillingCheckoutCreation(
  vars: CloseBillingCheckoutCreationVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CloseBillingCheckoutCreationData>>;

/** Generated Node Admin SDK operation action function for the 'GetBillingContext' Query. Allow users to execute without passing in DataConnect. */
export function getBillingContext(
  dc: DataConnect,
  vars: GetBillingContextVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingContextData>>;
/** Generated Node Admin SDK operation action function for the 'GetBillingContext' Query. Allow users to pass in custom DataConnect instances. */
export function getBillingContext(
  vars: GetBillingContextVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingContextData>>;

/** Generated Node Admin SDK operation action function for the 'GetBillingCustomerByStripeId' Query. Allow users to execute without passing in DataConnect. */
export function getBillingCustomerByStripeId(
  dc: DataConnect,
  vars: GetBillingCustomerByStripeIdVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingCustomerByStripeIdData>>;
/** Generated Node Admin SDK operation action function for the 'GetBillingCustomerByStripeId' Query. Allow users to pass in custom DataConnect instances. */
export function getBillingCustomerByStripeId(
  vars: GetBillingCustomerByStripeIdVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingCustomerByStripeIdData>>;

/** Generated Node Admin SDK operation action function for the 'GetBillingCheckoutCreation' Query. Allow users to execute without passing in DataConnect. */
export function getBillingCheckoutCreation(
  dc: DataConnect,
  vars: GetBillingCheckoutCreationVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingCheckoutCreationData>>;
/** Generated Node Admin SDK operation action function for the 'GetBillingCheckoutCreation' Query. Allow users to pass in custom DataConnect instances. */
export function getBillingCheckoutCreation(
  vars: GetBillingCheckoutCreationVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingCheckoutCreationData>>;

/** Generated Node Admin SDK operation action function for the 'GetBillingPeriod' Query. Allow users to execute without passing in DataConnect. */
export function getBillingPeriod(
  dc: DataConnect,
  vars: GetBillingPeriodVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingPeriodData>>;
/** Generated Node Admin SDK operation action function for the 'GetBillingPeriod' Query. Allow users to pass in custom DataConnect instances. */
export function getBillingPeriod(
  vars: GetBillingPeriodVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingPeriodData>>;

/** Generated Node Admin SDK operation action function for the 'CreateBillingCustomerCreation' Mutation. Allow users to execute without passing in DataConnect. */
export function createBillingCustomerCreation(
  dc: DataConnect,
  vars: CreateBillingCustomerCreationVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateBillingCustomerCreationData>>;
/** Generated Node Admin SDK operation action function for the 'CreateBillingCustomerCreation' Mutation. Allow users to pass in custom DataConnect instances. */
export function createBillingCustomerCreation(
  vars: CreateBillingCustomerCreationVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateBillingCustomerCreationData>>;

/** Generated Node Admin SDK operation action function for the 'GetBillingCustomerCreation' Query. Allow users to execute without passing in DataConnect. */
export function getBillingCustomerCreation(
  dc: DataConnect,
  vars: GetBillingCustomerCreationVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingCustomerCreationData>>;
/** Generated Node Admin SDK operation action function for the 'GetBillingCustomerCreation' Query. Allow users to pass in custom DataConnect instances. */
export function getBillingCustomerCreation(
  vars: GetBillingCustomerCreationVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingCustomerCreationData>>;

/** Generated Node Admin SDK operation action function for the 'RecordBillingCustomer' Mutation. Allow users to execute without passing in DataConnect. */
export function recordBillingCustomer(
  dc: DataConnect,
  vars: RecordBillingCustomerVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RecordBillingCustomerData>>;
/** Generated Node Admin SDK operation action function for the 'RecordBillingCustomer' Mutation. Allow users to pass in custom DataConnect instances. */
export function recordBillingCustomer(
  vars: RecordBillingCustomerVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RecordBillingCustomerData>>;

/** Generated Node Admin SDK operation action function for the 'DeleteBillingTeam' Mutation. Allow users to execute without passing in DataConnect. */
export function deleteBillingTeam(
  dc: DataConnect,
  vars: DeleteBillingTeamVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<DeleteBillingTeamData>>;
/** Generated Node Admin SDK operation action function for the 'DeleteBillingTeam' Mutation. Allow users to pass in custom DataConnect instances. */
export function deleteBillingTeam(
  vars: DeleteBillingTeamVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<DeleteBillingTeamData>>;

/** Generated Node Admin SDK operation action function for the 'GetBillingExecution' Query. Allow users to execute without passing in DataConnect. */
export function getBillingExecution(
  dc: DataConnect,
  vars: GetBillingExecutionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingExecutionData>>;
/** Generated Node Admin SDK operation action function for the 'GetBillingExecution' Query. Allow users to pass in custom DataConnect instances. */
export function getBillingExecution(
  vars: GetBillingExecutionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingExecutionData>>;

/** Generated Node Admin SDK operation action function for the 'StartBillingExecution' Mutation. Allow users to execute without passing in DataConnect. */
export function startBillingExecution(
  dc: DataConnect,
  vars: StartBillingExecutionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<StartBillingExecutionData>>;
/** Generated Node Admin SDK operation action function for the 'StartBillingExecution' Mutation. Allow users to pass in custom DataConnect instances. */
export function startBillingExecution(
  vars: StartBillingExecutionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<StartBillingExecutionData>>;

/** Generated Node Admin SDK operation action function for the 'HeartbeatBillingExecution' Mutation. Allow users to execute without passing in DataConnect. */
export function heartbeatBillingExecution(
  dc: DataConnect,
  vars: HeartbeatBillingExecutionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<HeartbeatBillingExecutionData>>;
/** Generated Node Admin SDK operation action function for the 'HeartbeatBillingExecution' Mutation. Allow users to pass in custom DataConnect instances. */
export function heartbeatBillingExecution(
  vars: HeartbeatBillingExecutionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<HeartbeatBillingExecutionData>>;

/** Generated Node Admin SDK operation action function for the 'FinishBillingExecution' Mutation. Allow users to execute without passing in DataConnect. */
export function finishBillingExecution(
  dc: DataConnect,
  vars: FinishBillingExecutionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<FinishBillingExecutionData>>;
/** Generated Node Admin SDK operation action function for the 'FinishBillingExecution' Mutation. Allow users to pass in custom DataConnect instances. */
export function finishBillingExecution(
  vars: FinishBillingExecutionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<FinishBillingExecutionData>>;

/** Generated Node Admin SDK operation action function for the 'ExpireBillingExecution' Mutation. Allow users to execute without passing in DataConnect. */
export function expireBillingExecution(
  dc: DataConnect,
  vars: ExpireBillingExecutionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ExpireBillingExecutionData>>;
/** Generated Node Admin SDK operation action function for the 'ExpireBillingExecution' Mutation. Allow users to pass in custom DataConnect instances. */
export function expireBillingExecution(
  vars: ExpireBillingExecutionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ExpireBillingExecutionData>>;

/** Generated Node Admin SDK operation action function for the 'GetExpiredBillingWork' Query. Allow users to execute without passing in DataConnect. */
export function getExpiredBillingWork(
  dc: DataConnect,
  vars: GetExpiredBillingWorkVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetExpiredBillingWorkData>>;
/** Generated Node Admin SDK operation action function for the 'GetExpiredBillingWork' Query. Allow users to pass in custom DataConnect instances. */
export function getExpiredBillingWork(
  vars: GetExpiredBillingWorkVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetExpiredBillingWorkData>>;

/** Generated Node Admin SDK operation action function for the 'GetQueuedBillingJobs' Query. Allow users to execute without passing in DataConnect. */
export function getQueuedBillingJobs(
  dc: DataConnect,
  vars?: GetQueuedBillingJobsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetQueuedBillingJobsData>>;
/** Generated Node Admin SDK operation action function for the 'GetQueuedBillingJobs' Query. Allow users to pass in custom DataConnect instances. */
export function getQueuedBillingJobs(
  vars?: GetQueuedBillingJobsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetQueuedBillingJobsData>>;

/** Generated Node Admin SDK operation action function for the 'GetBillingWorkerJobs' Query. Allow users to execute without passing in DataConnect. */
export function getBillingWorkerJobs(
  dc: DataConnect,
  vars: GetBillingWorkerJobsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingWorkerJobsData>>;
/** Generated Node Admin SDK operation action function for the 'GetBillingWorkerJobs' Query. Allow users to pass in custom DataConnect instances. */
export function getBillingWorkerJobs(
  vars: GetBillingWorkerJobsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingWorkerJobsData>>;

/** Generated Node Admin SDK operation action function for the 'GetBillingJob' Query. Allow users to execute without passing in DataConnect. */
export function getBillingJob(
  dc: DataConnect,
  vars: GetBillingJobVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingJobData>>;
/** Generated Node Admin SDK operation action function for the 'GetBillingJob' Query. Allow users to pass in custom DataConnect instances. */
export function getBillingJob(
  vars: GetBillingJobVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingJobData>>;

/** Generated Node Admin SDK operation action function for the 'CreateBillingPeriod' Mutation. Allow users to execute without passing in DataConnect. */
export function createBillingPeriod(
  dc: DataConnect,
  vars: CreateBillingPeriodVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateBillingPeriodData>>;
/** Generated Node Admin SDK operation action function for the 'CreateBillingPeriod' Mutation. Allow users to pass in custom DataConnect instances. */
export function createBillingPeriod(
  vars: CreateBillingPeriodVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateBillingPeriodData>>;

/** Generated Node Admin SDK operation action function for the 'GetBillingStripeState' Query. Allow users to execute without passing in DataConnect. */
export function getBillingStripeState(
  dc: DataConnect,
  vars: GetBillingStripeStateVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingStripeStateData>>;
/** Generated Node Admin SDK operation action function for the 'GetBillingStripeState' Query. Allow users to pass in custom DataConnect instances. */
export function getBillingStripeState(
  vars: GetBillingStripeStateVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingStripeStateData>>;

/** Generated Node Admin SDK operation action function for the 'GetBillingStripeEvent' Query. Allow users to execute without passing in DataConnect. */
export function getBillingStripeEvent(
  dc: DataConnect,
  vars: GetBillingStripeEventVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingStripeEventData>>;
/** Generated Node Admin SDK operation action function for the 'GetBillingStripeEvent' Query. Allow users to pass in custom DataConnect instances. */
export function getBillingStripeEvent(
  vars: GetBillingStripeEventVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingStripeEventData>>;

/** Generated Node Admin SDK operation action function for the 'InitializeBillingStripeState' Mutation. Allow users to execute without passing in DataConnect. */
export function initializeBillingStripeState(
  dc: DataConnect,
  vars: InitializeBillingStripeStateVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<InitializeBillingStripeStateData>>;
/** Generated Node Admin SDK operation action function for the 'InitializeBillingStripeState' Mutation. Allow users to pass in custom DataConnect instances. */
export function initializeBillingStripeState(
  vars: InitializeBillingStripeStateVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<InitializeBillingStripeStateData>>;

/** Generated Node Admin SDK operation action function for the 'RecordBillingStripeEvent' Mutation. Allow users to execute without passing in DataConnect. */
export function recordBillingStripeEvent(
  dc: DataConnect,
  vars: RecordBillingStripeEventVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RecordBillingStripeEventData>>;
/** Generated Node Admin SDK operation action function for the 'RecordBillingStripeEvent' Mutation. Allow users to pass in custom DataConnect instances. */
export function recordBillingStripeEvent(
  vars: RecordBillingStripeEventVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RecordBillingStripeEventData>>;

/** Generated Node Admin SDK operation action function for the 'GetBillingTrialEligibility' Query. Allow users to execute without passing in DataConnect. */
export function getBillingTrialEligibility(
  dc: DataConnect,
  vars: GetBillingTrialEligibilityVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingTrialEligibilityData>>;
/** Generated Node Admin SDK operation action function for the 'GetBillingTrialEligibility' Query. Allow users to pass in custom DataConnect instances. */
export function getBillingTrialEligibility(
  vars: GetBillingTrialEligibilityVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingTrialEligibilityData>>;

/** Generated Node Admin SDK operation action function for the 'StartBillingTrial' Mutation. Allow users to execute without passing in DataConnect. */
export function startBillingTrial(
  dc: DataConnect,
  vars: StartBillingTrialVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<StartBillingTrialData>>;
/** Generated Node Admin SDK operation action function for the 'StartBillingTrial' Mutation. Allow users to pass in custom DataConnect instances. */
export function startBillingTrial(
  vars: StartBillingTrialVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<StartBillingTrialData>>;

/** Generated Node Admin SDK operation action function for the 'GetBillingPeriodUsage' Query. Allow users to execute without passing in DataConnect. */
export function getBillingPeriodUsage(
  dc: DataConnect,
  vars: GetBillingPeriodUsageVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingPeriodUsageData>>;
/** Generated Node Admin SDK operation action function for the 'GetBillingPeriodUsage' Query. Allow users to pass in custom DataConnect instances. */
export function getBillingPeriodUsage(
  vars: GetBillingPeriodUsageVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetBillingPeriodUsageData>>;
