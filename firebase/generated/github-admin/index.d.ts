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

export interface ConfirmGitHubConnectionData {
  team_update?: Team_Key | null;
  query?: {
    session?: {
      githubUserId: Int64String;
      accessTokenSecretVersionPath?: string | null;
    };
  };
  gitHubConnectionSession_updateMany: number;
  connection: GitHubConnection_Key;
}

export interface ConfirmGitHubConnectionVariables {
  teamId: string;
  userId: string;
  referenceHash: string;
  githubApiBaseUrl: string;
  githubAppId: Int64String;
  installationId: Int64String;
  accountId: Int64String;
  accountType: string;
  accountLogin: string;
}

export interface ConsumeGitHubConnectionRequestData {
  query?: {
    request?: {
      id: string;
      userId: string;
      teamId: string;
      codeVerifierSecretVersionPath: string;
    } & GitHubConnectionRequest_Key;
  };
  gitHubConnectionRequest_deleteMany: number;
}

export interface ConsumeGitHubConnectionRequestVariables {
  stateHash: string;
}

export interface CreateGitHubConnectionRequestData {
  gitHubConnectionRequest_insert: GitHubConnectionRequest_Key;
}

export interface CreateGitHubConnectionRequestVariables {
  id: string;
  userId: string;
  teamId: string;
  stateHash: string;
  codeVerifierSecretVersionPath: string;
}

export interface CreateGitHubConnectionSessionData {
  gitHubConnectionSession_insert: GitHubConnectionSession_Key;
}

export interface CreateGitHubConnectionSessionVariables {
  id: string;
  userId: string;
  teamId: string;
  githubUserId: Int64String;
  referenceHash: string;
  accessTokenSecretVersionPath: string;
}

export interface DeleteExpiredGitHubConnectionRequestData {
  gitHubConnectionRequest_deleteMany: number;
}

export interface DeleteExpiredGitHubConnectionRequestVariables {
  id: string;
}

export interface DeleteExpiredGitHubConnectionSessionData {
  gitHubConnectionSession_deleteMany: number;
}

export interface DeleteExpiredGitHubConnectionSessionVariables {
  id: string;
}

export interface GetActiveGitHubConnectionData {
  connection?: {
    id: string;
    teamId: string;
    githubApiBaseUrl: string;
    githubAppId: Int64String;
    installationId: Int64String;
    accountId: Int64String;
    accountType: string;
    accountLogin: string;
    status: string;
    verifiedAt: Int64String;
  } & GitHubConnection_Key;
}

export interface GetActiveGitHubConnectionVariables {
  githubApiBaseUrl: string;
  githubAppId: Int64String;
  installationId: Int64String;
}

export interface GetExpiredGitHubConnectionCredentialsData {
  requests: ({
    id: string;
    codeVerifierSecretVersionPath: string;
  } & GitHubConnectionRequest_Key)[];
  sessions: ({
    id: string;
    accessTokenSecretVersionPath?: string | null;
  } & GitHubConnectionSession_Key)[];
}

export interface GetGitHubConnectionContextData {
  teamMember?: {
    id: Int64String;
  } & TeamMember_Key;
}

export interface GetGitHubConnectionContextVariables {
  teamId: string;
  userId: string;
}

export interface GetGitHubConnectionSessionData {
  session?: {
    id: string;
    teamId: string;
    userId: string;
    githubUserId: Int64String;
    accessTokenSecretVersionPath?: string | null;
    expiresAt: Int64String;
  } & GitHubConnectionSession_Key;
}

export interface GetGitHubConnectionSessionVariables {
  teamId: string;
  userId: string;
  referenceHash: string;
}

export interface GetGitHubConnectionsData {
  connections: ({
    id: string;
    teamId: string;
    githubApiBaseUrl: string;
    githubAppId: Int64String;
    installationId: Int64String;
    accountId: Int64String;
    accountType: string;
    accountLogin: string;
    status: string;
    verifiedAt: Int64String;
  } & GitHubConnection_Key)[];
}

export interface GetGitHubConnectionsVariables {
  teamId: string;
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

export interface WebhookTask_Key {
  id: string;
  __typename?: "WebhookTask_Key";
}

/** Generated Node Admin SDK operation action function for the 'GetExpiredGitHubConnectionCredentials' Query. Allow users to execute without passing in DataConnect. */
export function getExpiredGitHubConnectionCredentials(
  dc: DataConnect,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetExpiredGitHubConnectionCredentialsData>>;
/** Generated Node Admin SDK operation action function for the 'GetExpiredGitHubConnectionCredentials' Query. Allow users to pass in custom DataConnect instances. */
export function getExpiredGitHubConnectionCredentials(
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetExpiredGitHubConnectionCredentialsData>>;

/** Generated Node Admin SDK operation action function for the 'DeleteExpiredGitHubConnectionRequest' Mutation. Allow users to execute without passing in DataConnect. */
export function deleteExpiredGitHubConnectionRequest(
  dc: DataConnect,
  vars: DeleteExpiredGitHubConnectionRequestVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<DeleteExpiredGitHubConnectionRequestData>>;
/** Generated Node Admin SDK operation action function for the 'DeleteExpiredGitHubConnectionRequest' Mutation. Allow users to pass in custom DataConnect instances. */
export function deleteExpiredGitHubConnectionRequest(
  vars: DeleteExpiredGitHubConnectionRequestVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<DeleteExpiredGitHubConnectionRequestData>>;

/** Generated Node Admin SDK operation action function for the 'DeleteExpiredGitHubConnectionSession' Mutation. Allow users to execute without passing in DataConnect. */
export function deleteExpiredGitHubConnectionSession(
  dc: DataConnect,
  vars: DeleteExpiredGitHubConnectionSessionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<DeleteExpiredGitHubConnectionSessionData>>;
/** Generated Node Admin SDK operation action function for the 'DeleteExpiredGitHubConnectionSession' Mutation. Allow users to pass in custom DataConnect instances. */
export function deleteExpiredGitHubConnectionSession(
  vars: DeleteExpiredGitHubConnectionSessionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<DeleteExpiredGitHubConnectionSessionData>>;

/** Generated Node Admin SDK operation action function for the 'ConfirmGitHubConnection' Mutation. Allow users to execute without passing in DataConnect. */
export function confirmGitHubConnection(
  dc: DataConnect,
  vars: ConfirmGitHubConnectionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ConfirmGitHubConnectionData>>;
/** Generated Node Admin SDK operation action function for the 'ConfirmGitHubConnection' Mutation. Allow users to pass in custom DataConnect instances. */
export function confirmGitHubConnection(
  vars: ConfirmGitHubConnectionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ConfirmGitHubConnectionData>>;

/** Generated Node Admin SDK operation action function for the 'GetGitHubConnections' Query. Allow users to execute without passing in DataConnect. */
export function getGitHubConnections(
  dc: DataConnect,
  vars: GetGitHubConnectionsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetGitHubConnectionsData>>;
/** Generated Node Admin SDK operation action function for the 'GetGitHubConnections' Query. Allow users to pass in custom DataConnect instances. */
export function getGitHubConnections(
  vars: GetGitHubConnectionsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetGitHubConnectionsData>>;

/** Generated Node Admin SDK operation action function for the 'GetActiveGitHubConnection' Query. Allow users to execute without passing in DataConnect. */
export function getActiveGitHubConnection(
  dc: DataConnect,
  vars: GetActiveGitHubConnectionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetActiveGitHubConnectionData>>;
/** Generated Node Admin SDK operation action function for the 'GetActiveGitHubConnection' Query. Allow users to pass in custom DataConnect instances. */
export function getActiveGitHubConnection(
  vars: GetActiveGitHubConnectionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetActiveGitHubConnectionData>>;

/** Generated Node Admin SDK operation action function for the 'GetGitHubConnectionContext' Query. Allow users to execute without passing in DataConnect. */
export function getGitHubConnectionContext(
  dc: DataConnect,
  vars: GetGitHubConnectionContextVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetGitHubConnectionContextData>>;
/** Generated Node Admin SDK operation action function for the 'GetGitHubConnectionContext' Query. Allow users to pass in custom DataConnect instances. */
export function getGitHubConnectionContext(
  vars: GetGitHubConnectionContextVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetGitHubConnectionContextData>>;

/** Generated Node Admin SDK operation action function for the 'CreateGitHubConnectionRequest' Mutation. Allow users to execute without passing in DataConnect. */
export function createGitHubConnectionRequest(
  dc: DataConnect,
  vars: CreateGitHubConnectionRequestVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateGitHubConnectionRequestData>>;
/** Generated Node Admin SDK operation action function for the 'CreateGitHubConnectionRequest' Mutation. Allow users to pass in custom DataConnect instances. */
export function createGitHubConnectionRequest(
  vars: CreateGitHubConnectionRequestVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateGitHubConnectionRequestData>>;

/** Generated Node Admin SDK operation action function for the 'ConsumeGitHubConnectionRequest' Mutation. Allow users to execute without passing in DataConnect. */
export function consumeGitHubConnectionRequest(
  dc: DataConnect,
  vars: ConsumeGitHubConnectionRequestVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ConsumeGitHubConnectionRequestData>>;
/** Generated Node Admin SDK operation action function for the 'ConsumeGitHubConnectionRequest' Mutation. Allow users to pass in custom DataConnect instances. */
export function consumeGitHubConnectionRequest(
  vars: ConsumeGitHubConnectionRequestVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<ConsumeGitHubConnectionRequestData>>;

/** Generated Node Admin SDK operation action function for the 'CreateGitHubConnectionSession' Mutation. Allow users to execute without passing in DataConnect. */
export function createGitHubConnectionSession(
  dc: DataConnect,
  vars: CreateGitHubConnectionSessionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateGitHubConnectionSessionData>>;
/** Generated Node Admin SDK operation action function for the 'CreateGitHubConnectionSession' Mutation. Allow users to pass in custom DataConnect instances. */
export function createGitHubConnectionSession(
  vars: CreateGitHubConnectionSessionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateGitHubConnectionSessionData>>;

/** Generated Node Admin SDK operation action function for the 'GetGitHubConnectionSession' Query. Allow users to execute without passing in DataConnect. */
export function getGitHubConnectionSession(
  dc: DataConnect,
  vars: GetGitHubConnectionSessionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetGitHubConnectionSessionData>>;
/** Generated Node Admin SDK operation action function for the 'GetGitHubConnectionSession' Query. Allow users to pass in custom DataConnect instances. */
export function getGitHubConnectionSession(
  vars: GetGitHubConnectionSessionVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetGitHubConnectionSessionData>>;
