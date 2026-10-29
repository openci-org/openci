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

export interface AddTeamMemberData {
  team_update?: Team_Key | null;
  teamMember_insert: TeamMember_Key;
}

export interface AddTeamMemberVariables {
  teamId: string;
  actorUid: string;
  userId: string;
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

export interface CreateTeamData {
  team_insert: Team_Key;
  teamMember_insert: TeamMember_Key;
}

export interface CreateTeamVariables {
  id: string;
  name: string;
}

export interface GetMyTeamsData {
  teams: ({
    id: string;
    name: string;
    runNumber: Int64String;
    createdAt: Int64String;
    updatedAt: Int64String;
    members: {
      userId: string;
    }[];
  } & Team_Key)[];
}

export interface GetTeamMembersData {
  team?: {
    members: {
      userId: string;
    }[];
  };
}

export interface GetTeamMembersVariables {
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

export interface RemoveTeamMemberData {
  team_update?: Team_Key | null;
  teamMember_delete?: TeamMember_Key | null;
}

export interface RemoveTeamMemberVariables {
  teamId: string;
  userId: string;
}

export interface RenameTeamData {
  team_update?: Team_Key | null;
}

export interface RenameTeamVariables {
  teamId: string;
  name: string;
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

/** Generated Node Admin SDK operation action function for the 'GetTeamMembers' Query. Allow users to execute without passing in DataConnect. */
export function getTeamMembers(
  dc: DataConnect,
  vars: GetTeamMembersVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetTeamMembersData>>;
/** Generated Node Admin SDK operation action function for the 'GetTeamMembers' Query. Allow users to pass in custom DataConnect instances. */
export function getTeamMembers(
  vars: GetTeamMembersVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetTeamMembersData>>;

/** Generated Node Admin SDK operation action function for the 'AddTeamMember' Mutation. Allow users to execute without passing in DataConnect. */
export function addTeamMember(
  dc: DataConnect,
  vars: AddTeamMemberVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<AddTeamMemberData>>;
/** Generated Node Admin SDK operation action function for the 'AddTeamMember' Mutation. Allow users to pass in custom DataConnect instances. */
export function addTeamMember(
  vars: AddTeamMemberVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<AddTeamMemberData>>;

/** Generated Node Admin SDK operation action function for the 'RemoveTeamMember' Mutation. Allow users to execute without passing in DataConnect. */
export function removeTeamMember(
  dc: DataConnect,
  vars: RemoveTeamMemberVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RemoveTeamMemberData>>;
/** Generated Node Admin SDK operation action function for the 'RemoveTeamMember' Mutation. Allow users to pass in custom DataConnect instances. */
export function removeTeamMember(
  vars: RemoveTeamMemberVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RemoveTeamMemberData>>;

/** Generated Node Admin SDK operation action function for the 'CreateTeam' Mutation. Allow users to execute without passing in DataConnect. */
export function createTeam(
  dc: DataConnect,
  vars: CreateTeamVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateTeamData>>;
/** Generated Node Admin SDK operation action function for the 'CreateTeam' Mutation. Allow users to pass in custom DataConnect instances. */
export function createTeam(
  vars: CreateTeamVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<CreateTeamData>>;

/** Generated Node Admin SDK operation action function for the 'RenameTeam' Mutation. Allow users to execute without passing in DataConnect. */
export function renameTeam(
  dc: DataConnect,
  vars: RenameTeamVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RenameTeamData>>;
/** Generated Node Admin SDK operation action function for the 'RenameTeam' Mutation. Allow users to pass in custom DataConnect instances. */
export function renameTeam(
  vars: RenameTeamVariables,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<RenameTeamData>>;

/** Generated Node Admin SDK operation action function for the 'GetMyTeams' Query. Allow users to execute without passing in DataConnect. */
export function getMyTeams(
  dc: DataConnect,
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetMyTeamsData>>;
/** Generated Node Admin SDK operation action function for the 'GetMyTeams' Query. Allow users to pass in custom DataConnect instances. */
export function getMyTeams(
  options?: OperationOptions,
): Promise<ExecuteOperationResponse<GetMyTeamsData>>;
