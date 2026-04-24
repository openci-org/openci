import { ConnectorConfig, DataConnect, OperationOptions, ExecuteOperationResponse } from 'firebase-admin/data-connect';

export const connectorConfig: ConnectorConfig;

export type TimestampString = string;
export type UUIDString = string;
export type Int64String = string;
export type DateString = string;


export interface AcceptInvitationAndJoinTeamData {
  user_upsert: {
    id: string;
  };
    invitation_update?: {
      id: UUIDString;
    };
      teamMember_upsert: {
        teamId: UUIDString;
        userId: string;
      };
}

export interface AcceptInvitationAndJoinTeamVariables {
  id: UUIDString;
  teamId: UUIDString;
}

export interface AcceptInvitationData {
  invitation_update?: {
    id: UUIDString;
  };
}

export interface AcceptInvitationVariables {
  id: UUIDString;
}

export interface AddTeamMemberData {
  teamMember_upsert: {
    teamId: UUIDString;
    userId: string;
  };
}

export interface AddTeamMemberVariables {
  teamId: UUIDString;
}

export interface CreateInvitationData {
  invitation_insert: {
    id: UUIDString;
  };
}

export interface CreateInvitationVariables {
  email: string;
  teamId: UUIDString;
  teamNameSnapshot: string;
  token: string;
  expiresAt: TimestampString;
}

export interface ExpireInvitationData {
  invitation_update?: {
    id: UUIDString;
  };
}

export interface ExpireInvitationVariables {
  id: UUIDString;
}

export interface FindExistingPendingInvitationData {
  invitations: ({
    id: UUIDString;
    token: string;
    expiresAt: TimestampString;
  } & Invitation_Key)[];
}

export interface FindExistingPendingInvitationVariables {
  email: string;
  teamId: UUIDString;
}

export interface GetInvitationByTokenData {
  invitations: ({
    id: UUIDString;
    email: string;
    status: InvitationStatus;
    expiresAt: TimestampString;
    createdAt: TimestampString;
    teamNameSnapshot: string;
    team: {
      id: UUIDString;
      name: string;
    } & Team_Key;
      invitedBy?: {
        id: string;
        email: string;
      } & User_Key;
  } & Invitation_Key)[];
}

export interface GetInvitationByTokenVariables {
  token: string;
}

export interface Invitation_Key {
  id: UUIDString;
  __typename?: 'Invitation_Key';
}

export interface ListMyPendingInvitationsData {
  invitations: ({
    id: UUIDString;
    teamNameSnapshot: string;
    expiresAt: TimestampString;
    createdAt: TimestampString;
    team: {
      id: UUIDString;
      name: string;
    } & Team_Key;
  } & Invitation_Key)[];
}

export interface ListTeamPendingInvitationsData {
  teamMember?: {
    teamId: UUIDString;
  };
    invitations: ({
      id: UUIDString;
      email: string;
      createdAt: TimestampString;
      expiresAt: TimestampString;
      invitedBy?: {
        id: string;
        email: string;
      } & User_Key;
    } & Invitation_Key)[];
}

export interface ListTeamPendingInvitationsVariables {
  teamId: UUIDString;
}

export interface ReinviteInvitationData {
  invitation_update?: {
    id: UUIDString;
  };
}

export interface ReinviteInvitationVariables {
  id: UUIDString;
  teamId: UUIDString;
  token: string;
  expiresAt: TimestampString;
}

export interface TeamMember_Key {
  teamId: UUIDString;
  userId: string;
  __typename?: 'TeamMember_Key';
}

export interface Team_Key {
  id: UUIDString;
  __typename?: 'Team_Key';
}

export interface User_Key {
  id: string;
  __typename?: 'User_Key';
}

/** Generated Node Admin SDK operation action function for the 'GetInvitationByToken' Query. Allow users to execute without passing in DataConnect. */
export function getInvitationByToken(dc: DataConnect, vars: GetInvitationByTokenVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetInvitationByTokenData>>;
/** Generated Node Admin SDK operation action function for the 'GetInvitationByToken' Query. Allow users to pass in custom DataConnect instances. */
export function getInvitationByToken(vars: GetInvitationByTokenVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetInvitationByTokenData>>;

/** Generated Node Admin SDK operation action function for the 'ListMyPendingInvitations' Query. Allow users to execute without passing in DataConnect. */
export function listMyPendingInvitations(dc: DataConnect, options?: OperationOptions): Promise<ExecuteOperationResponse<ListMyPendingInvitationsData>>;
/** Generated Node Admin SDK operation action function for the 'ListMyPendingInvitations' Query. Allow users to pass in custom DataConnect instances. */
export function listMyPendingInvitations(options?: OperationOptions): Promise<ExecuteOperationResponse<ListMyPendingInvitationsData>>;

/** Generated Node Admin SDK operation action function for the 'ListTeamPendingInvitations' Query. Allow users to execute without passing in DataConnect. */
export function listTeamPendingInvitations(dc: DataConnect, vars: ListTeamPendingInvitationsVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListTeamPendingInvitationsData>>;
/** Generated Node Admin SDK operation action function for the 'ListTeamPendingInvitations' Query. Allow users to pass in custom DataConnect instances. */
export function listTeamPendingInvitations(vars: ListTeamPendingInvitationsVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListTeamPendingInvitationsData>>;

/** Generated Node Admin SDK operation action function for the 'FindExistingPendingInvitation' Query. Allow users to execute without passing in DataConnect. */
export function findExistingPendingInvitation(dc: DataConnect, vars: FindExistingPendingInvitationVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<FindExistingPendingInvitationData>>;
/** Generated Node Admin SDK operation action function for the 'FindExistingPendingInvitation' Query. Allow users to pass in custom DataConnect instances. */
export function findExistingPendingInvitation(vars: FindExistingPendingInvitationVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<FindExistingPendingInvitationData>>;

/** Generated Node Admin SDK operation action function for the 'CreateInvitation' Mutation. Allow users to execute without passing in DataConnect. */
export function createInvitation(dc: DataConnect, vars: CreateInvitationVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateInvitationData>>;
/** Generated Node Admin SDK operation action function for the 'CreateInvitation' Mutation. Allow users to pass in custom DataConnect instances. */
export function createInvitation(vars: CreateInvitationVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateInvitationData>>;

/** Generated Node Admin SDK operation action function for the 'ReinviteInvitation' Mutation. Allow users to execute without passing in DataConnect. */
export function reinviteInvitation(dc: DataConnect, vars: ReinviteInvitationVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ReinviteInvitationData>>;
/** Generated Node Admin SDK operation action function for the 'ReinviteInvitation' Mutation. Allow users to pass in custom DataConnect instances. */
export function reinviteInvitation(vars: ReinviteInvitationVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ReinviteInvitationData>>;

/** Generated Node Admin SDK operation action function for the 'AcceptInvitation' Mutation. Allow users to execute without passing in DataConnect. */
export function acceptInvitation(dc: DataConnect, vars: AcceptInvitationVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<AcceptInvitationData>>;
/** Generated Node Admin SDK operation action function for the 'AcceptInvitation' Mutation. Allow users to pass in custom DataConnect instances. */
export function acceptInvitation(vars: AcceptInvitationVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<AcceptInvitationData>>;

/** Generated Node Admin SDK operation action function for the 'ExpireInvitation' Mutation. Allow users to execute without passing in DataConnect. */
export function expireInvitation(dc: DataConnect, vars: ExpireInvitationVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ExpireInvitationData>>;
/** Generated Node Admin SDK operation action function for the 'ExpireInvitation' Mutation. Allow users to pass in custom DataConnect instances. */
export function expireInvitation(vars: ExpireInvitationVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ExpireInvitationData>>;

/** Generated Node Admin SDK operation action function for the 'AddTeamMember' Mutation. Allow users to execute without passing in DataConnect. */
export function addTeamMember(dc: DataConnect, vars: AddTeamMemberVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<AddTeamMemberData>>;
/** Generated Node Admin SDK operation action function for the 'AddTeamMember' Mutation. Allow users to pass in custom DataConnect instances. */
export function addTeamMember(vars: AddTeamMemberVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<AddTeamMemberData>>;

/** Generated Node Admin SDK operation action function for the 'AcceptInvitationAndJoinTeam' Mutation. Allow users to execute without passing in DataConnect. */
export function acceptInvitationAndJoinTeam(dc: DataConnect, vars: AcceptInvitationAndJoinTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<AcceptInvitationAndJoinTeamData>>;
/** Generated Node Admin SDK operation action function for the 'AcceptInvitationAndJoinTeam' Mutation. Allow users to pass in custom DataConnect instances. */
export function acceptInvitationAndJoinTeam(vars: AcceptInvitationAndJoinTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<AcceptInvitationAndJoinTeamData>>;

