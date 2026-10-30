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

export interface CommitManagedSecretData {
  team_update?: Team_Key | null;
  secretReference_upsert: SecretReference_Key;
}

export interface CommitManagedSecretVariables {
  teamId: string;
  actorUid: string;
  name: string;
  expectedPath?: string | null;
  path: string;
}

export interface CompleteSecretVersionCleanupData {
  secretVersionCleanup_delete?: SecretVersionCleanup_Key | null;
}

export interface CompleteSecretVersionCleanupVariables {
  path: string;
}

export interface CreateSecretReferenceData {
  secretReference_insert: SecretReference_Key;
}

export interface CreateSecretReferenceVariables {
  teamId: string;
  name: string;
  secretVersionPath: string;
}

export interface DeleteManagedSecretData {
  team_update?: Team_Key | null;
  secretReference_deleteMany: number;
}

export interface DeleteManagedSecretVariables {
  teamId: string;
  actorUid: string;
  name: string;
  expectedPath: string;
}

export interface DeleteSecretReferenceData {
  secretReference_deleteMany: number;
}

export interface DeleteSecretReferenceVariables {
  teamId: string;
  name: string;
  expectedSecretVersionPath: string;
}

export interface GetDueSecretVersionsData {
  versions: ({
    path: string;
  } & SecretVersionCleanup_Key)[];
}

export interface GetManagedSecretContextData {
  teamMember?: {
    id: Int64String;
  } & TeamMember_Key;
  secrets: {
    name: string;
    secretVersionPath: string;
    createdAt: Int64String;
    updatedAt: Int64String;
  }[];
}

export interface GetManagedSecretContextVariables {
  teamId: string;
  actorUid: string;
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

export interface GetSecretVersionReferencesData {
  references: {
    name: string;
  }[];
}

export interface GetSecretVersionReferencesVariables {
  path: string;
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

export interface QueueSecretVersionCleanupData {
  secretVersionCleanup_upsert: SecretVersionCleanup_Key;
}

export interface QueueSecretVersionCleanupVariables {
  path: string;
}

export interface RenameManagedSecretData {
  team_update?: Team_Key | null;
  secretReference_delete?: SecretReference_Key | null;
  secretReference_insert: SecretReference_Key;
}

export interface RenameManagedSecretVariables {
  teamId: string;
  actorUid: string;
  name: string;
  newName: string;
  expectedPath: string;
  path?: string | null;
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

/** Generated Node Admin SDK operation action function for the 'GetManagedSecretContext' Query. Allow users to execute without passing in DataConnect. */
export function getManagedSecretContext(
  dc: DataConnect,
  vars: GetManagedSecretContextVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetManagedSecretContextData>>;
/** Generated Node Admin SDK operation action function for the 'GetManagedSecretContext' Query. Allow users to pass in custom DataConnect instances. */
export function getManagedSecretContext(
  vars: GetManagedSecretContextVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetManagedSecretContextData>>;

/** Generated Node Admin SDK operation action function for the 'CommitManagedSecret' Mutation. Allow users to execute without passing in DataConnect. */
export function commitManagedSecret(
  dc: DataConnect,
  vars: CommitManagedSecretVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CommitManagedSecretData>>;
/** Generated Node Admin SDK operation action function for the 'CommitManagedSecret' Mutation. Allow users to pass in custom DataConnect instances. */
export function commitManagedSecret(
  vars: CommitManagedSecretVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CommitManagedSecretData>>;

/** Generated Node Admin SDK operation action function for the 'RenameManagedSecret' Mutation. Allow users to execute without passing in DataConnect. */
export function renameManagedSecret(
  dc: DataConnect,
  vars: RenameManagedSecretVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RenameManagedSecretData>>;
/** Generated Node Admin SDK operation action function for the 'RenameManagedSecret' Mutation. Allow users to pass in custom DataConnect instances. */
export function renameManagedSecret(
  vars: RenameManagedSecretVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RenameManagedSecretData>>;

/** Generated Node Admin SDK operation action function for the 'DeleteManagedSecret' Mutation. Allow users to execute without passing in DataConnect. */
export function deleteManagedSecret(
  dc: DataConnect,
  vars: DeleteManagedSecretVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<DeleteManagedSecretData>>;
/** Generated Node Admin SDK operation action function for the 'DeleteManagedSecret' Mutation. Allow users to pass in custom DataConnect instances. */
export function deleteManagedSecret(
  vars: DeleteManagedSecretVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<DeleteManagedSecretData>>;

/** Generated Node Admin SDK operation action function for the 'QueueSecretVersionCleanup' Mutation. Allow users to execute without passing in DataConnect. */
export function queueSecretVersionCleanup(
  dc: DataConnect,
  vars: QueueSecretVersionCleanupVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<QueueSecretVersionCleanupData>>;
/** Generated Node Admin SDK operation action function for the 'QueueSecretVersionCleanup' Mutation. Allow users to pass in custom DataConnect instances. */
export function queueSecretVersionCleanup(
  vars: QueueSecretVersionCleanupVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<QueueSecretVersionCleanupData>>;

/** Generated Node Admin SDK operation action function for the 'GetDueSecretVersions' Query. Allow users to execute without passing in DataConnect. */
export function getDueSecretVersions(
  dc: DataConnect,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetDueSecretVersionsData>>;
/** Generated Node Admin SDK operation action function for the 'GetDueSecretVersions' Query. Allow users to pass in custom DataConnect instances. */
export function getDueSecretVersions(
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetDueSecretVersionsData>>;

/** Generated Node Admin SDK operation action function for the 'GetSecretVersionReferences' Query. Allow users to execute without passing in DataConnect. */
export function getSecretVersionReferences(
  dc: DataConnect,
  vars: GetSecretVersionReferencesVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetSecretVersionReferencesData>>;
/** Generated Node Admin SDK operation action function for the 'GetSecretVersionReferences' Query. Allow users to pass in custom DataConnect instances. */
export function getSecretVersionReferences(
  vars: GetSecretVersionReferencesVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetSecretVersionReferencesData>>;

/** Generated Node Admin SDK operation action function for the 'CompleteSecretVersionCleanup' Mutation. Allow users to execute without passing in DataConnect. */
export function completeSecretVersionCleanup(
  dc: DataConnect,
  vars: CompleteSecretVersionCleanupVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CompleteSecretVersionCleanupData>>;
/** Generated Node Admin SDK operation action function for the 'CompleteSecretVersionCleanup' Mutation. Allow users to pass in custom DataConnect instances. */
export function completeSecretVersionCleanup(
  vars: CompleteSecretVersionCleanupVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CompleteSecretVersionCleanupData>>;

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
