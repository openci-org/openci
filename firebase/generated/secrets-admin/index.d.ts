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

export interface CreateSecretReferenceData {
  secretReference_insert: SecretReference_Key;
}

export interface CreateSecretReferenceVariables {
  teamId: string;
  name: string;
  secretVersionPath: string;
}

export interface DeleteSecretReferenceData {
  secretReference_deleteMany: number;
}

export interface DeleteSecretReferenceVariables {
  teamId: string;
  name: string;
  expectedSecretVersionPath: string;
}

export interface GetSecretReferenceData {
  secretReference?: {
    teamId: string;
    name: string;
    secretVersionPath: string;
    createdAt: Int64String;
    updatedAt: Int64String;
  } & SecretReference_Key;
}

export interface GetSecretReferenceVariables {
  teamId: string;
  name: string;
}

export interface GetSecretsData {
  secrets: ({
    teamId: string;
    name: string;
    createdAt: Int64String;
    updatedAt: Int64String;
  } & SecretReference_Key)[];
}

export interface GetSecretsVariables {
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

export interface UpdateSecretReferenceData {
  secretReference_updateMany: number;
}

export interface UpdateSecretReferenceVariables {
  teamId: string;
  name: string;
  expectedSecretVersionPath: string;
  secretVersionPath: string;
}

export interface WebhookTask_Key {
  id: string;
  __typename?: "WebhookTask_Key";
}

/** Generated Node Admin SDK operation action function for the 'CreateSecretReference' Mutation. Allow users to execute without passing in DataConnect. */
export function createSecretReference(
  dc: DataConnect,
  vars: CreateSecretReferenceVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateSecretReferenceData>>;
/** Generated Node Admin SDK operation action function for the 'CreateSecretReference' Mutation. Allow users to pass in custom DataConnect instances. */
export function createSecretReference(
  vars: CreateSecretReferenceVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateSecretReferenceData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateSecretReference' Mutation. Allow users to execute without passing in DataConnect. */
export function updateSecretReference(
  dc: DataConnect,
  vars: UpdateSecretReferenceVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<UpdateSecretReferenceData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateSecretReference' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateSecretReference(
  vars: UpdateSecretReferenceVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<UpdateSecretReferenceData>>;

/** Generated Node Admin SDK operation action function for the 'DeleteSecretReference' Mutation. Allow users to execute without passing in DataConnect. */
export function deleteSecretReference(
  dc: DataConnect,
  vars: DeleteSecretReferenceVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<DeleteSecretReferenceData>>;
/** Generated Node Admin SDK operation action function for the 'DeleteSecretReference' Mutation. Allow users to pass in custom DataConnect instances. */
export function deleteSecretReference(
  vars: DeleteSecretReferenceVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<DeleteSecretReferenceData>>;

/** Generated Node Admin SDK operation action function for the 'GetSecrets' Query. Allow users to execute without passing in DataConnect. */
export function getSecrets(
  dc: DataConnect,
  vars: GetSecretsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetSecretsData>>;
/** Generated Node Admin SDK operation action function for the 'GetSecrets' Query. Allow users to pass in custom DataConnect instances. */
export function getSecrets(
  vars: GetSecretsVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetSecretsData>>;

/** Generated Node Admin SDK operation action function for the 'GetSecretReference' Query. Allow users to execute without passing in DataConnect. */
export function getSecretReference(
  dc: DataConnect,
  vars: GetSecretReferenceVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetSecretReferenceData>>;
/** Generated Node Admin SDK operation action function for the 'GetSecretReference' Query. Allow users to pass in custom DataConnect instances. */
export function getSecretReference(
  vars: GetSecretReferenceVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetSecretReferenceData>>;
