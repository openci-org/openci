import { ConnectorConfig, DataConnect, OperationOptions, ExecuteOperationResponse } from 'firebase-admin/data-connect';

export const connectorConfig: ConnectorConfig;

export type TimestampString = string;
export type UUIDString = string;
export type Int64String = string;
export type DateString = string;

export enum BuildJobStatus {
  WAITING = "WAITING",
  QUEUED = "QUEUED",
  IN_PROGRESS = "IN_PROGRESS",
  SUCCESS = "SUCCESS",
  FAILURE = "FAILURE",
  CANCELLED = "CANCELLED",
  SKIPPED = "SKIPPED",
  TIMED_OUT = "TIMED_OUT",
}
export enum InvitationStatus {
  PENDING = "PENDING",
  ACCEPTED = "ACCEPTED",
  EXPIRED = "EXPIRED",
}

export interface AcceptInvitationAndJoinTeamData {
  user_upsert: {
    id: string;
  };
    invitation_update?: {
      id: string;
    };
      teamMember_upsert: {
        teamId: string;
        userId: string;
      };
}

export interface AcceptInvitationAndJoinTeamVariables {
  id: string;
  teamId: string;
}

export interface AcceptInvitationData {
  invitation_update?: {
    id: string;
  };
}

export interface AcceptInvitationVariables {
  id: string;
}

export interface AddCurrentUserFcmTokenData {
  user_update?: {
    id: string;
  };
}

export interface AddCurrentUserFcmTokenVariables {
  token: string;
}

export interface AddTeamMemberData {
  user_upsert: {
    id: string;
  };
    teamMember_upsert: {
      teamId: string;
      userId: string;
    };
}

export interface AddTeamMemberVariables {
  teamId: string;
  userId: string;
  email: string;
}

export interface AppendBuildLogForWorkerData {
  buildLog_upsert: {
    buildRunBuildJobId: string;
    buildRunId: string;
    id: string;
  };
}

export interface AppendBuildLogForWorkerVariables {
  buildJobId: string;
  runId: string;
  id: string;
  message: string;
  level: string;
  timestamp: TimestampString;
  stackTrace?: string | null;
}

export interface BuildJob_Key {
  id: string;
  __typename?: 'BuildJob_Key';
}

export interface BuildLog_Key {
  buildRunBuildJobId: string;
  buildRunId: string;
  id: string;
  __typename?: 'BuildLog_Key';
}

export interface BuildRun_Key {
  buildJobId: string;
  id: string;
  __typename?: 'BuildRun_Key';
}

export interface ClaimQueuedBuildJobData {
  job?: unknown | null;
}

export interface ClaimQueuedBuildJobVariables {
  runsOnPattern: string;
}

export interface CompleteBuildJobForWorkerData {
  buildJob_update?: {
    id: string;
  };
}

export interface CompleteBuildJobForWorkerVariables {
  id: string;
  status: BuildJobStatus;
  completedAt: TimestampString;
}

export interface CreateBuildJobData {
  buildJob_insert: {
    id: string;
  };
}

export interface CreateBuildJobVariables {
  id: string;
  status: BuildJobStatus;
  owner: string;
  repo: string;
  teamId?: string | null;
  workflowId?: string | null;
  workflowFileName?: string | null;
  workflowName?: string | null;
  jobKey?: string | null;
  workflowRunId?: string | null;
  needs?: string[] | null;
  resolvedNeeds?: unknown | null;
  installationId?: Int64String | null;
  installationToken?: string | null;
  tokenExpiresAt?: TimestampString | null;
  checkRunId?: Int64String | null;
  commitSha?: string | null;
  pullRequestNumber?: number | null;
  event?: string | null;
  action?: string | null;
  sender?: string | null;
  repository?: string | null;
  tagName?: string | null;
  branch?: string | null;
  releaseName?: string | null;
  runsOn?: string | null;
  runCount?: number | null;
  latestRunId?: string | null;
  retriedFromBuildJobId?: string | null;
  retriedFromWorkflowRunId?: string | null;
  githubApiBaseUrl?: string | null;
  githubBaseUrl?: string | null;
}

export interface CreateBuildRunForWorkerData {
  buildRun_upsert: {
    buildJobId: string;
    id: string;
  };
    buildJob_update?: {
      id: string;
    };
}

export interface CreateBuildRunForWorkerVariables {
  buildJobId: string;
  id: string;
}

export interface CreateEnvironmentVariableData {
  environmentVariable_insert: {
    id: string;
  };
}

export interface CreateEnvironmentVariableVariables {
  id: string;
  envKey: string;
  value: string;
  teamId: string;
  autoIncrement?: boolean | null;
}

export interface CreateInvitationData {
  invitation_insert: {
    id: string;
  };
}

export interface CreateInvitationVariables {
  email: string;
  teamId: string;
  teamNameSnapshot: string;
  token: string;
  expiresAt: TimestampString;
}

export interface CreateSecretMetadataData {
  secret_insert: {
    id: string;
  };
}

export interface CreateSecretMetadataVariables {
  id: string;
  name: string;
  teamId: string;
  pathToSecret: string;
}

export interface CreateTeamForCurrentUserData {
  createTeam?: number | null;
}

export interface CreateTeamForCurrentUserVariables {
  id: string;
  name: string;
}

export interface CreateWorkflowData {
  workflow_insert: {
    id: string;
  };
}

export interface CreateWorkflowVariables {
  id: string;
  teamId: string;
  name: string;
  workflowConfig: unknown;
  workflowSteps: unknown;
  isEditing: boolean;
}

export interface DeleteEnvironmentVariableData {
  environmentVariable_delete?: {
    id: string;
  };
}

export interface DeleteEnvironmentVariableVariables {
  id: string;
  teamId: string;
}

export interface DeleteSecretMetadataData {
  secret_delete?: {
    id: string;
  };
}

export interface DeleteSecretMetadataVariables {
  id: string;
}

export interface DeleteTeamData {
  team_delete?: {
    id: string;
  };
}

export interface DeleteTeamVariables {
  teamId: string;
}

export interface DeleteWorkflowData {
  workflow_delete?: {
    id: string;
  };
}

export interface DeleteWorkflowFileData {
  workflowFile_delete?: {
    id: string;
  };
}

export interface DeleteWorkflowFileVariables {
  id: string;
}

export interface DeleteWorkflowVariables {
  id: string;
  teamId: string;
}

export interface EnvironmentVariable_Key {
  id: string;
  __typename?: 'EnvironmentVariable_Key';
}

export interface ExpireInvitationData {
  invitation_update?: {
    id: string;
  };
}

export interface ExpireInvitationVariables {
  id: string;
}

export interface FindExistingPendingInvitationData {
  invitations: ({
    id: string;
    token: string;
    expiresAt: TimestampString;
  } & Invitation_Key)[];
}

export interface FindExistingPendingInvitationVariables {
  email: string;
  teamId: string;
}

export interface FindSecretByNameData {
  teamMember?: {
    teamId: string;
  };
    secrets: ({
      id: string;
      name: string;
      teamId: string;
    } & Secret_Key)[];
}

export interface FindSecretByNameVariables {
  teamId: string;
  name: string;
}

export interface FindTeamByInstallationData {
  teams: ({
    id: string;
    name: string;
    aiEnabled?: boolean | null;
    githubApiBaseUrl?: string | null;
    githubBaseUrl?: string | null;
    installationIds?: number[] | null;
  } & Team_Key)[];
}

export interface FindTeamByInstallationVariables {
  installationId: number;
}

export interface GetBuildJobData {
  buildJob?: {
    id: string;
    status: BuildJobStatus;
    owner: string;
    repo: string;
    teamId?: string | null;
    workflowId?: string | null;
    workflowFileName?: string | null;
    workflowName?: string | null;
    jobKey?: string | null;
    workflowRunId?: string | null;
    needs?: string[] | null;
    resolvedNeeds?: unknown | null;
    installationId?: Int64String | null;
    tokenExpiresAt?: TimestampString | null;
    checkRunId?: Int64String | null;
    commitSha?: string | null;
    pullRequestNumber?: number | null;
    event?: string | null;
    action?: string | null;
    sender?: string | null;
    repository?: string | null;
    tagName?: string | null;
    branch?: string | null;
    releaseName?: string | null;
    runsOn?: string | null;
    runCount?: number | null;
    latestRunId?: string | null;
    githubApiBaseUrl?: string | null;
    githubBaseUrl?: string | null;
    createdAt: TimestampString;
    updatedAt: TimestampString;
    completedAt?: TimestampString | null;
    failureSummaryStatus?: string | null;
    failureSummary?: string | null;
    failureSummaryModel?: string | null;
    failureSummaryDurationMs?: number | null;
  } & BuildJob_Key;
}

export interface GetBuildJobForTeamData {
  teamMember?: {
    teamId: string;
  };
    buildJob?: {
      id: string;
      status: BuildJobStatus;
      owner: string;
      repo: string;
      teamId?: string | null;
      workflowId?: string | null;
      workflowFileName?: string | null;
      workflowName?: string | null;
      jobKey?: string | null;
      workflowRunId?: string | null;
      needs?: string[] | null;
      resolvedNeeds?: unknown | null;
      installationId?: Int64String | null;
      tokenExpiresAt?: TimestampString | null;
      checkRunId?: Int64String | null;
      commitSha?: string | null;
      pullRequestNumber?: number | null;
      event?: string | null;
      action?: string | null;
      sender?: string | null;
      repository?: string | null;
      tagName?: string | null;
      branch?: string | null;
      releaseName?: string | null;
      runsOn?: string | null;
      runCount?: number | null;
      latestRunId?: string | null;
      githubApiBaseUrl?: string | null;
      githubBaseUrl?: string | null;
      createdAt: TimestampString;
      updatedAt: TimestampString;
      completedAt?: TimestampString | null;
      failureSummaryStatus?: string | null;
      failureSummary?: string | null;
      failureSummaryModel?: string | null;
      failureSummaryDurationMs?: number | null;
    } & BuildJob_Key;
}

export interface GetBuildJobForTeamVariables {
  id: string;
  teamId: string;
}

export interface GetBuildJobVariables {
  id: string;
}

export interface GetCurrentUserData {
  user?: {
    id: string;
    selectedTeamId?: string | null;
    notificationPreference?: string | null;
    fcmTokens?: string[] | null;
    selectedRepository?: string | null;
    selectedBranch?: string | null;
  } & User_Key;
}

export interface GetInvitationByTokenData {
  invitations: ({
    id: string;
    email: string;
    status: InvitationStatus;
    expiresAt: TimestampString;
    createdAt: TimestampString;
    teamNameSnapshot: string;
    team: {
      id: string;
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

export interface GetSecretForTeamData {
  teamMember?: {
    teamId: string;
  };
    secret?: {
      id: string;
      name: string;
      teamId: string;
    } & Secret_Key;
}

export interface GetSecretForTeamVariables {
  id: string;
  teamId: string;
}

export interface GetSecretPathForTeamData {
  secret?: {
    id: string;
    name: string;
    teamId: string;
    pathToSecret?: string | null;
  } & Secret_Key;
}

export interface GetSecretPathForTeamVariables {
  id: string;
  teamId: string;
}

export interface GetSecretsByNamesData {
  secrets: ({
    id: string;
    name: string;
    teamId: string;
  } & Secret_Key)[];
}

export interface GetSecretsByNamesForTeamData {
  teamMember?: {
    teamId: string;
  };
    secrets: ({
      id: string;
      name: string;
      teamId: string;
      pathToSecret?: string | null;
    } & Secret_Key)[];
}

export interface GetSecretsByNamesForTeamVariables {
  teamId: string;
  names: string[];
}

export interface GetSecretsByNamesVariables {
  teamId: string;
  names: string[];
}

export interface GetTeamByIdData {
  team?: {
    id: string;
    name: string;
    aiEnabled?: boolean | null;
    githubApiBaseUrl?: string | null;
    githubBaseUrl?: string | null;
    installationIds?: number[] | null;
  } & Team_Key;
}

export interface GetTeamByIdVariables {
  teamId: string;
}

export interface GetTeamForMemberData {
  teamMember?: {
    teamId: string;
  };
    team?: {
      id: string;
      name: string;
      aiEnabled?: boolean | null;
      githubApiBaseUrl?: string | null;
      githubBaseUrl?: string | null;
      installationIds?: number[] | null;
    } & Team_Key;
}

export interface GetTeamForMemberVariables {
  teamId: string;
}

export interface GetWorkflowData {
  teamMember?: {
    teamId: string;
  };
    workflow?: {
      id: string;
      teamId: string;
      name?: string | null;
      workflowConfig?: unknown | null;
      workflowSteps?: unknown | null;
      isEditing?: boolean | null;
      createdAt: TimestampString;
      updatedAt: TimestampString;
    } & Workflow_Key;
}

export interface GetWorkflowFileData {
  workflowFile?: {
    id: string;
    teamId: string;
    repository: string;
    branch: string;
    fileName: string;
    enabled?: boolean | null;
  } & WorkflowFile_Key;
}

export interface GetWorkflowFileVariables {
  id: string;
}

export interface GetWorkflowVariables {
  id: string;
  teamId: string;
}

export interface Invitation_Key {
  id: string;
  __typename?: 'Invitation_Key';
}

export interface LinkGitHubInstallationData {
  team_update?: {
    id: string;
  };
}

export interface LinkGitHubInstallationVariables {
  teamId: string;
  installationId: number;
}

export interface ListBuildJobsByWorkflowRunData {
  buildJobs: ({
    id: string;
    status: BuildJobStatus;
    owner: string;
    repo: string;
    teamId?: string | null;
    workflowId?: string | null;
    workflowFileName?: string | null;
    workflowName?: string | null;
    jobKey?: string | null;
    workflowRunId?: string | null;
    needs?: string[] | null;
    resolvedNeeds?: unknown | null;
    installationId?: Int64String | null;
    installationToken?: string | null;
    tokenExpiresAt?: TimestampString | null;
    checkRunId?: Int64String | null;
    commitSha?: string | null;
    pullRequestNumber?: number | null;
    event?: string | null;
    action?: string | null;
    sender?: string | null;
    repository?: string | null;
    tagName?: string | null;
    branch?: string | null;
    releaseName?: string | null;
    runsOn?: string | null;
    runCount?: number | null;
    latestRunId?: string | null;
    githubApiBaseUrl?: string | null;
    githubBaseUrl?: string | null;
    createdAt: TimestampString;
    updatedAt: TimestampString;
    completedAt?: TimestampString | null;
  } & BuildJob_Key)[];
}

export interface ListBuildJobsByWorkflowRunVariables {
  workflowRunId: string;
}

export interface ListBuildJobsForTeamData {
  teamMember?: {
    teamId: string;
  };
    buildJobs: ({
      id: string;
      status: BuildJobStatus;
      owner: string;
      repo: string;
      teamId?: string | null;
      workflowId?: string | null;
      workflowFileName?: string | null;
      workflowName?: string | null;
      jobKey?: string | null;
      workflowRunId?: string | null;
      needs?: string[] | null;
      commitSha?: string | null;
      pullRequestNumber?: number | null;
      tagName?: string | null;
      branch?: string | null;
      runCount?: number | null;
      latestRunId?: string | null;
      createdAt: TimestampString;
      updatedAt: TimestampString;
      completedAt?: TimestampString | null;
      failureSummaryStatus?: string | null;
      failureSummary?: string | null;
      failureSummaryModel?: string | null;
      failureSummaryDurationMs?: number | null;
    } & BuildJob_Key)[];
}

export interface ListBuildJobsForTeamVariables {
  teamId: string;
  limit: number;
}

export interface ListBuildLogsForRunData {
  teamMember?: {
    teamId: string;
  };
    buildLogs: ({
      id: string;
      message: string;
      level?: string | null;
      timestamp: TimestampString;
    })[];
}

export interface ListBuildLogsForRunVariables {
  buildJobId: string;
  runId: string;
  teamId: string;
  limit?: number | null;
}

export interface ListEnvironmentVariablesForTeamData {
  environmentVariables: ({
    id: string;
    key: string;
    value: string;
    teamId: string;
    autoIncrement?: boolean | null;
    createdAt: TimestampString;
    updatedAt: TimestampString;
  } & EnvironmentVariable_Key)[];
}

export interface ListEnvironmentVariablesForTeamVariables {
  teamId: string;
}

export interface ListLatestBuildLogsData {
  buildLogs: ({
    id: string;
    message: string;
    timestamp: TimestampString;
  })[];
}

export interface ListLatestBuildLogsVariables {
  buildJobId: string;
  runId: string;
  limit: number;
}

export interface ListMyPendingInvitationsData {
  invitations: ({
    id: string;
    teamNameSnapshot: string;
    expiresAt: TimestampString;
    createdAt: TimestampString;
    team: {
      id: string;
      name: string;
    } & Team_Key;
  } & Invitation_Key)[];
}

export interface ListMyTeamsData {
  teamMembers: ({
    team: {
      id: string;
      name: string;
      members?: string[] | null;
      installationIds?: number[] | null;
      aiEnabled?: boolean | null;
      githubApiBaseUrl?: string | null;
      githubBaseUrl?: string | null;
      createdAt: TimestampString;
      updatedAt: TimestampString;
    } & Team_Key;
  })[];
}

export interface ListSecretsForTeamData {
  teamMember?: {
    teamId: string;
  };
    secrets: ({
      id: string;
      name: string;
      teamId: string;
      createdAt: TimestampString;
      updatedAt: TimestampString;
    } & Secret_Key)[];
}

export interface ListSecretsForTeamVariables {
  teamId: string;
}

export interface ListTeamMembersData {
  teamMember?: {
    teamId: string;
  };
    teamMembers: ({
      userId: string;
      user: {
        id: string;
        email: string;
        displayName?: string | null;
        photoUrl?: string | null;
      } & User_Key;
    })[];
}

export interface ListTeamMembersVariables {
  teamId: string;
}

export interface ListTeamNotificationUsersData {
  teamMembers: ({
    user: {
      id: string;
      notificationPreference?: string | null;
      fcmTokens?: string[] | null;
    } & User_Key;
  })[];
}

export interface ListTeamNotificationUsersVariables {
  teamId: string;
}

export interface ListTeamPendingInvitationsData {
  teamMember?: {
    teamId: string;
  };
    invitations: ({
      id: string;
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
  teamId: string;
}

export interface ListWaitingBuildJobsData {
  buildJobs: ({
    id: string;
    jobKey?: string | null;
    needs?: string[] | null;
    resolvedNeeds?: unknown | null;
  } & BuildJob_Key)[];
}

export interface ListWaitingBuildJobsVariables {
  workflowRunId: string;
}

export interface ListWorkerEnvironmentVariablesData {
  environmentVariables: ({
    id: string;
    key: string;
    value: string;
    teamId: string;
    autoIncrement?: boolean | null;
  } & EnvironmentVariable_Key)[];
}

export interface ListWorkerEnvironmentVariablesVariables {
  teamId: string;
}

export interface ListWorkerSecretsData {
  secrets: ({
    id: string;
    name: string;
    teamId: string;
    pathToSecret?: string | null;
  } & Secret_Key)[];
}

export interface ListWorkerSecretsVariables {
  teamId: string;
}

export interface ListWorkflowFilesForBranchData {
  teamMember?: {
    teamId: string;
  };
    workflowFiles: ({
      id: string;
      fileName: string;
      filePath: string;
      content: string;
      enabled?: boolean | null;
    } & WorkflowFile_Key)[];
}

export interface ListWorkflowFilesForBranchVariables {
  teamId: string;
  repository: string;
  branch: string;
}

export interface ListWorkflowsForTeamData {
  teamMember?: {
    teamId: string;
  };
    workflows: ({
      id: string;
      teamId: string;
      name?: string | null;
      workflowConfig?: unknown | null;
      workflowSteps?: unknown | null;
      isEditing?: boolean | null;
      createdAt: TimestampString;
      updatedAt: TimestampString;
    } & Workflow_Key)[];
}

export interface ListWorkflowsForTeamVariables {
  teamId: string;
}

export interface ReinviteInvitationData {
  invitation_update?: {
    id: string;
  };
}

export interface ReinviteInvitationVariables {
  id: string;
  teamId: string;
  token: string;
  expiresAt: TimestampString;
}

export interface Secret_Key {
  id: string;
  __typename?: 'Secret_Key';
}

export interface TeamMember_Key {
  teamId: string;
  userId: string;
  __typename?: 'TeamMember_Key';
}

export interface Team_Key {
  id: string;
  __typename?: 'Team_Key';
}

export interface UpdateBuildJobFailureSummaryData {
  buildJob_update?: {
    id: string;
  };
}

export interface UpdateBuildJobFailureSummaryVariables {
  id: string;
  failureSummaryStatus: string;
  failureSummary?: string | null;
  failureSummaryModel?: string | null;
  failureSummaryDurationMs?: number | null;
}

export interface UpdateBuildJobStatusData {
  buildJob_update?: {
    id: string;
  };
}

export interface UpdateBuildJobStatusVariables {
  id: string;
  status: BuildJobStatus;
}

export interface UpdateBuildRunStatusForWorkerData {
  buildRun_update?: {
    buildJobId: string;
    id: string;
  };
}

export interface UpdateBuildRunStatusForWorkerVariables {
  buildJobId: string;
  runId: string;
  status: string;
  conclusion?: string | null;
}

export interface UpdateCurrentUserFcmTokensData {
  user_update?: {
    id: string;
  };
}

export interface UpdateCurrentUserFcmTokensVariables {
  fcmTokens: string[];
}

export interface UpdateCurrentUserNotificationPreferenceData {
  user_update?: {
    id: string;
  };
}

export interface UpdateCurrentUserNotificationPreferenceVariables {
  notificationPreference: string;
}

export interface UpdateCurrentUserRepositorySelectionData {
  user_update?: {
    id: string;
  };
}

export interface UpdateCurrentUserRepositorySelectionVariables {
  repository: string;
  branch: string;
}

export interface UpdateCurrentUserSelectedBranchData {
  user_update?: {
    id: string;
  };
}

export interface UpdateCurrentUserSelectedBranchVariables {
  branch: string;
}

export interface UpdateCurrentUserSelectedTeamData {
  user_update?: {
    id: string;
  };
}

export interface UpdateCurrentUserSelectedTeamVariables {
  teamId: string;
}

export interface UpdateEnvironmentVariableData {
  environmentVariable_update?: {
    id: string;
  };
}

export interface UpdateEnvironmentVariableValueForWorkerData {
  environmentVariable_update?: {
    id: string;
  };
}

export interface UpdateEnvironmentVariableValueForWorkerVariables {
  id: string;
  value: string;
}

export interface UpdateEnvironmentVariableVariables {
  id: string;
  teamId: string;
  envKey: string;
  value: string;
}

export interface UpdateSecretMetadataData {
  secret_update?: {
    id: string;
  };
}

export interface UpdateSecretMetadataVariables {
  id: string;
  name: string;
}

export interface UpdateTeamAiEnabledData {
  team_update?: {
    id: string;
  };
}

export interface UpdateTeamAiEnabledVariables {
  teamId: string;
  aiEnabled: boolean;
}

export interface UpdateTeamGitHubSettingsData {
  team_update?: {
    id: string;
  };
}

export interface UpdateTeamGitHubSettingsVariables {
  teamId: string;
  githubBaseUrl?: string | null;
  githubApiBaseUrl?: string | null;
  installationIds?: number[] | null;
}

export interface UpdateTeamNameData {
  team_update?: {
    id: string;
  };
}

export interface UpdateTeamNameVariables {
  teamId: string;
  name: string;
}

export interface UpdateUserFcmTokensData {
  user_update?: {
    id: string;
  };
}

export interface UpdateUserFcmTokensVariables {
  id: string;
  fcmTokens: string[];
}

export interface UpdateWorkflowConfigData {
  workflow_update?: {
    id: string;
  };
}

export interface UpdateWorkflowConfigVariables {
  id: string;
  teamId: string;
  workflowConfig: unknown;
}

export interface UpdateWorkflowFileEnabledData {
  workflowFile_update?: {
    id: string;
  };
}

export interface UpdateWorkflowFileEnabledVariables {
  id: string;
  teamId: string;
  enabled: boolean;
}

export interface UpdateWorkflowNameData {
  workflow_update?: {
    id: string;
  };
}

export interface UpdateWorkflowNameVariables {
  id: string;
  teamId: string;
  name: string;
}

export interface UpdateWorkflowSecretKeysData {
  workflow_update?: {
    id: string;
  };
}

export interface UpdateWorkflowSecretKeysVariables {
  id: string;
  workflowSteps: unknown;
}

export interface UpdateWorkflowStepsData {
  workflow_update?: {
    id: string;
  };
}

export interface UpdateWorkflowStepsVariables {
  id: string;
  teamId: string;
  workflowSteps: unknown;
}

export interface UpsertBuildJobFromFirestoreData {
  buildJob_upsert: {
    id: string;
  };
}

export interface UpsertBuildJobFromFirestoreVariables {
  id: string;
  status: BuildJobStatus;
  owner: string;
  repo: string;
  teamId?: string | null;
  workflowId?: string | null;
  workflowFileName?: string | null;
  workflowName?: string | null;
  jobKey?: string | null;
  workflowRunId?: string | null;
  needs?: string[] | null;
  resolvedNeeds?: unknown | null;
  installationId?: Int64String | null;
  installationToken?: string | null;
  tokenExpiresAt?: TimestampString | null;
  checkRunId?: Int64String | null;
  commitSha?: string | null;
  pullRequestNumber?: number | null;
  event?: string | null;
  action?: string | null;
  sender?: string | null;
  repository?: string | null;
  tagName?: string | null;
  branch?: string | null;
  releaseName?: string | null;
  runsOn?: string | null;
  runCount?: number | null;
  latestRunId?: string | null;
  retriedFromBuildJobId?: string | null;
  retriedFromWorkflowRunId?: string | null;
  githubApiBaseUrl?: string | null;
  githubBaseUrl?: string | null;
  failureSummaryStatus?: string | null;
  failureSummary?: string | null;
  failureSummaryModel?: string | null;
  failureSummaryDurationMs?: number | null;
  completedAt?: TimestampString | null;
}

export interface UpsertBuildLogFromFirestoreData {
  buildLog_upsert: {
    buildRunBuildJobId: string;
    buildRunId: string;
    id: string;
  };
}

export interface UpsertBuildLogFromFirestoreVariables {
  buildJobId: string;
  runId: string;
  id: string;
  message: string;
  timestamp: TimestampString;
}

export interface UpsertBuildRunFromFirestoreData {
  buildRun_upsert: {
    buildJobId: string;
    id: string;
  };
}

export interface UpsertBuildRunFromFirestoreVariables {
  buildJobId: string;
  id: string;
}

export interface UpsertEnvironmentVariableFromFirestoreData {
  environmentVariable_upsert: {
    id: string;
  };
}

export interface UpsertEnvironmentVariableFromFirestoreVariables {
  id: string;
  envKey: string;
  value: string;
  teamId: string;
  autoIncrement?: boolean | null;
}

export interface UpsertInvitationFromFirestoreData {
  invitation_upsert: {
    id: string;
  };
}

export interface UpsertInvitationFromFirestoreVariables {
  id: string;
  email: string;
  teamId: string;
  teamNameSnapshot: string;
  token: string;
  status: InvitationStatus;
  expiresAt: TimestampString;
  invitedById?: string | null;
  acceptedById?: string | null;
  acceptedAt?: TimestampString | null;
}

export interface UpsertSecretMetadataFromFirestoreData {
  secret_upsert: {
    id: string;
  };
}

export interface UpsertSecretMetadataFromFirestoreVariables {
  id: string;
  name: string;
  teamId: string;
  pathToSecret?: string | null;
}

export interface UpsertTeamFromFirestoreData {
  team_upsert: {
    id: string;
  };
}

export interface UpsertTeamFromFirestoreVariables {
  id: string;
  name: string;
  aiEnabled?: boolean | null;
  githubApiBaseUrl?: string | null;
  githubBaseUrl?: string | null;
  installationIds?: number[] | null;
  members?: string[] | null;
}

export interface UpsertTeamMemberFromFirestoreData {
  user_upsert: {
    id: string;
  };
    teamMember_upsert: {
      teamId: string;
      userId: string;
    };
}

export interface UpsertTeamMemberFromFirestoreVariables {
  teamId: string;
  userId: string;
  email: string;
}

export interface UpsertUserFromFirestoreData {
  user_upsert: {
    id: string;
  };
}

export interface UpsertUserFromFirestoreVariables {
  id: string;
  email: string;
  displayName?: string | null;
  photoUrl?: string | null;
  notificationPreference?: string | null;
  fcmTokens?: string[] | null;
  selectedTeamId?: string | null;
  selectedRepository?: string | null;
  selectedBranch?: string | null;
}

export interface UpsertUserProfileData {
  user_upsert: {
    id: string;
  };
}

export interface UpsertUserProfileVariables {
  id: string;
  email: string;
  displayName?: string | null;
  photoUrl?: string | null;
}

export interface UpsertWorkflowFileData {
  workflowFile_upsert: {
    id: string;
  };
}

export interface UpsertWorkflowFileVariables {
  id: string;
  teamId: string;
  repository: string;
  branch: string;
  fileName: string;
  filePath: string;
  content: string;
  enabled?: boolean | null;
}

export interface UpsertWorkflowFromFirestoreData {
  workflow_upsert: {
    id: string;
  };
}

export interface UpsertWorkflowFromFirestoreVariables {
  id: string;
  teamId: string;
  name?: string | null;
  workflowConfig?: unknown | null;
  workflowSteps?: unknown | null;
  isEditing?: boolean | null;
}

export interface User_Key {
  id: string;
  __typename?: 'User_Key';
}

export interface WorkflowFile_Key {
  id: string;
  __typename?: 'WorkflowFile_Key';
}

export interface Workflow_Key {
  id: string;
  __typename?: 'Workflow_Key';
}

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

/** Generated Node Admin SDK operation action function for the 'AcceptInvitationAndJoinTeam' Mutation. Allow users to execute without passing in DataConnect. */
export function acceptInvitationAndJoinTeam(dc: DataConnect, vars: AcceptInvitationAndJoinTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<AcceptInvitationAndJoinTeamData>>;
/** Generated Node Admin SDK operation action function for the 'AcceptInvitationAndJoinTeam' Mutation. Allow users to pass in custom DataConnect instances. */
export function acceptInvitationAndJoinTeam(vars: AcceptInvitationAndJoinTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<AcceptInvitationAndJoinTeamData>>;

/** Generated Node Admin SDK operation action function for the 'LinkGitHubInstallation' Mutation. Allow users to execute without passing in DataConnect. */
export function linkGitHubInstallation(dc: DataConnect, vars: LinkGitHubInstallationVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<LinkGitHubInstallationData>>;
/** Generated Node Admin SDK operation action function for the 'LinkGitHubInstallation' Mutation. Allow users to pass in custom DataConnect instances. */
export function linkGitHubInstallation(vars: LinkGitHubInstallationVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<LinkGitHubInstallationData>>;

/** Generated Node Admin SDK operation action function for the 'UpsertUserProfile' Mutation. Allow users to execute without passing in DataConnect. */
export function upsertUserProfile(dc: DataConnect, vars: UpsertUserProfileVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertUserProfileData>>;
/** Generated Node Admin SDK operation action function for the 'UpsertUserProfile' Mutation. Allow users to pass in custom DataConnect instances. */
export function upsertUserProfile(vars: UpsertUserProfileVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertUserProfileData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateCurrentUserSelectedTeam' Mutation. Allow users to execute without passing in DataConnect. */
export function updateCurrentUserSelectedTeam(dc: DataConnect, vars: UpdateCurrentUserSelectedTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateCurrentUserSelectedTeamData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateCurrentUserSelectedTeam' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateCurrentUserSelectedTeam(vars: UpdateCurrentUserSelectedTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateCurrentUserSelectedTeamData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateCurrentUserNotificationPreference' Mutation. Allow users to execute without passing in DataConnect. */
export function updateCurrentUserNotificationPreference(dc: DataConnect, vars: UpdateCurrentUserNotificationPreferenceVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateCurrentUserNotificationPreferenceData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateCurrentUserNotificationPreference' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateCurrentUserNotificationPreference(vars: UpdateCurrentUserNotificationPreferenceVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateCurrentUserNotificationPreferenceData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateCurrentUserFcmTokens' Mutation. Allow users to execute without passing in DataConnect. */
export function updateCurrentUserFcmTokens(dc: DataConnect, vars: UpdateCurrentUserFcmTokensVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateCurrentUserFcmTokensData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateCurrentUserFcmTokens' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateCurrentUserFcmTokens(vars: UpdateCurrentUserFcmTokensVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateCurrentUserFcmTokensData>>;

/** Generated Node Admin SDK operation action function for the 'AddCurrentUserFcmToken' Mutation. Allow users to execute without passing in DataConnect. */
export function addCurrentUserFcmToken(dc: DataConnect, vars: AddCurrentUserFcmTokenVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<AddCurrentUserFcmTokenData>>;
/** Generated Node Admin SDK operation action function for the 'AddCurrentUserFcmToken' Mutation. Allow users to pass in custom DataConnect instances. */
export function addCurrentUserFcmToken(vars: AddCurrentUserFcmTokenVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<AddCurrentUserFcmTokenData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateCurrentUserRepositorySelection' Mutation. Allow users to execute without passing in DataConnect. */
export function updateCurrentUserRepositorySelection(dc: DataConnect, vars: UpdateCurrentUserRepositorySelectionVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateCurrentUserRepositorySelectionData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateCurrentUserRepositorySelection' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateCurrentUserRepositorySelection(vars: UpdateCurrentUserRepositorySelectionVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateCurrentUserRepositorySelectionData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateCurrentUserSelectedBranch' Mutation. Allow users to execute without passing in DataConnect. */
export function updateCurrentUserSelectedBranch(dc: DataConnect, vars: UpdateCurrentUserSelectedBranchVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateCurrentUserSelectedBranchData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateCurrentUserSelectedBranch' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateCurrentUserSelectedBranch(vars: UpdateCurrentUserSelectedBranchVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateCurrentUserSelectedBranchData>>;

/** Generated Node Admin SDK operation action function for the 'UpsertUserFromFirestore' Mutation. Allow users to execute without passing in DataConnect. */
export function upsertUserFromFirestore(dc: DataConnect, vars: UpsertUserFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertUserFromFirestoreData>>;
/** Generated Node Admin SDK operation action function for the 'UpsertUserFromFirestore' Mutation. Allow users to pass in custom DataConnect instances. */
export function upsertUserFromFirestore(vars: UpsertUserFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertUserFromFirestoreData>>;

/** Generated Node Admin SDK operation action function for the 'UpsertTeamFromFirestore' Mutation. Allow users to execute without passing in DataConnect. */
export function upsertTeamFromFirestore(dc: DataConnect, vars: UpsertTeamFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertTeamFromFirestoreData>>;
/** Generated Node Admin SDK operation action function for the 'UpsertTeamFromFirestore' Mutation. Allow users to pass in custom DataConnect instances. */
export function upsertTeamFromFirestore(vars: UpsertTeamFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertTeamFromFirestoreData>>;

/** Generated Node Admin SDK operation action function for the 'CreateTeamForCurrentUser' Mutation. Allow users to execute without passing in DataConnect. */
export function createTeamForCurrentUser(dc: DataConnect, vars: CreateTeamForCurrentUserVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateTeamForCurrentUserData>>;
/** Generated Node Admin SDK operation action function for the 'CreateTeamForCurrentUser' Mutation. Allow users to pass in custom DataConnect instances. */
export function createTeamForCurrentUser(vars: CreateTeamForCurrentUserVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateTeamForCurrentUserData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateTeamName' Mutation. Allow users to execute without passing in DataConnect. */
export function updateTeamName(dc: DataConnect, vars: UpdateTeamNameVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateTeamNameData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateTeamName' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateTeamName(vars: UpdateTeamNameVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateTeamNameData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateTeamAiEnabled' Mutation. Allow users to execute without passing in DataConnect. */
export function updateTeamAiEnabled(dc: DataConnect, vars: UpdateTeamAiEnabledVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateTeamAiEnabledData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateTeamAiEnabled' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateTeamAiEnabled(vars: UpdateTeamAiEnabledVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateTeamAiEnabledData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateTeamGitHubSettings' Mutation. Allow users to execute without passing in DataConnect. */
export function updateTeamGitHubSettings(dc: DataConnect, vars: UpdateTeamGitHubSettingsVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateTeamGitHubSettingsData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateTeamGitHubSettings' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateTeamGitHubSettings(vars: UpdateTeamGitHubSettingsVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateTeamGitHubSettingsData>>;

/** Generated Node Admin SDK operation action function for the 'DeleteTeam' Mutation. Allow users to execute without passing in DataConnect. */
export function deleteTeam(dc: DataConnect, vars: DeleteTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<DeleteTeamData>>;
/** Generated Node Admin SDK operation action function for the 'DeleteTeam' Mutation. Allow users to pass in custom DataConnect instances. */
export function deleteTeam(vars: DeleteTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<DeleteTeamData>>;

/** Generated Node Admin SDK operation action function for the 'UpsertTeamMemberFromFirestore' Mutation. Allow users to execute without passing in DataConnect. */
export function upsertTeamMemberFromFirestore(dc: DataConnect, vars: UpsertTeamMemberFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertTeamMemberFromFirestoreData>>;
/** Generated Node Admin SDK operation action function for the 'UpsertTeamMemberFromFirestore' Mutation. Allow users to pass in custom DataConnect instances. */
export function upsertTeamMemberFromFirestore(vars: UpsertTeamMemberFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertTeamMemberFromFirestoreData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateUserFcmTokens' Mutation. Allow users to execute without passing in DataConnect. */
export function updateUserFcmTokens(dc: DataConnect, vars: UpdateUserFcmTokensVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateUserFcmTokensData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateUserFcmTokens' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateUserFcmTokens(vars: UpdateUserFcmTokensVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateUserFcmTokensData>>;

/** Generated Node Admin SDK operation action function for the 'AddTeamMember' Mutation. Allow users to execute without passing in DataConnect. */
export function addTeamMember(dc: DataConnect, vars: AddTeamMemberVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<AddTeamMemberData>>;
/** Generated Node Admin SDK operation action function for the 'AddTeamMember' Mutation. Allow users to pass in custom DataConnect instances. */
export function addTeamMember(vars: AddTeamMemberVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<AddTeamMemberData>>;

/** Generated Node Admin SDK operation action function for the 'CreateSecretMetadata' Mutation. Allow users to execute without passing in DataConnect. */
export function createSecretMetadata(dc: DataConnect, vars: CreateSecretMetadataVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateSecretMetadataData>>;
/** Generated Node Admin SDK operation action function for the 'CreateSecretMetadata' Mutation. Allow users to pass in custom DataConnect instances. */
export function createSecretMetadata(vars: CreateSecretMetadataVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateSecretMetadataData>>;

/** Generated Node Admin SDK operation action function for the 'UpsertSecretMetadataFromFirestore' Mutation. Allow users to execute without passing in DataConnect. */
export function upsertSecretMetadataFromFirestore(dc: DataConnect, vars: UpsertSecretMetadataFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertSecretMetadataFromFirestoreData>>;
/** Generated Node Admin SDK operation action function for the 'UpsertSecretMetadataFromFirestore' Mutation. Allow users to pass in custom DataConnect instances. */
export function upsertSecretMetadataFromFirestore(vars: UpsertSecretMetadataFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertSecretMetadataFromFirestoreData>>;

/** Generated Node Admin SDK operation action function for the 'UpsertEnvironmentVariableFromFirestore' Mutation. Allow users to execute without passing in DataConnect. */
export function upsertEnvironmentVariableFromFirestore(dc: DataConnect, vars: UpsertEnvironmentVariableFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertEnvironmentVariableFromFirestoreData>>;
/** Generated Node Admin SDK operation action function for the 'UpsertEnvironmentVariableFromFirestore' Mutation. Allow users to pass in custom DataConnect instances. */
export function upsertEnvironmentVariableFromFirestore(vars: UpsertEnvironmentVariableFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertEnvironmentVariableFromFirestoreData>>;

/** Generated Node Admin SDK operation action function for the 'CreateEnvironmentVariable' Mutation. Allow users to execute without passing in DataConnect. */
export function createEnvironmentVariable(dc: DataConnect, vars: CreateEnvironmentVariableVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateEnvironmentVariableData>>;
/** Generated Node Admin SDK operation action function for the 'CreateEnvironmentVariable' Mutation. Allow users to pass in custom DataConnect instances. */
export function createEnvironmentVariable(vars: CreateEnvironmentVariableVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateEnvironmentVariableData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateEnvironmentVariable' Mutation. Allow users to execute without passing in DataConnect. */
export function updateEnvironmentVariable(dc: DataConnect, vars: UpdateEnvironmentVariableVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateEnvironmentVariableData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateEnvironmentVariable' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateEnvironmentVariable(vars: UpdateEnvironmentVariableVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateEnvironmentVariableData>>;

/** Generated Node Admin SDK operation action function for the 'DeleteEnvironmentVariable' Mutation. Allow users to execute without passing in DataConnect. */
export function deleteEnvironmentVariable(dc: DataConnect, vars: DeleteEnvironmentVariableVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<DeleteEnvironmentVariableData>>;
/** Generated Node Admin SDK operation action function for the 'DeleteEnvironmentVariable' Mutation. Allow users to pass in custom DataConnect instances. */
export function deleteEnvironmentVariable(vars: DeleteEnvironmentVariableVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<DeleteEnvironmentVariableData>>;

/** Generated Node Admin SDK operation action function for the 'UpsertInvitationFromFirestore' Mutation. Allow users to execute without passing in DataConnect. */
export function upsertInvitationFromFirestore(dc: DataConnect, vars: UpsertInvitationFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertInvitationFromFirestoreData>>;
/** Generated Node Admin SDK operation action function for the 'UpsertInvitationFromFirestore' Mutation. Allow users to pass in custom DataConnect instances. */
export function upsertInvitationFromFirestore(vars: UpsertInvitationFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertInvitationFromFirestoreData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateSecretMetadata' Mutation. Allow users to execute without passing in DataConnect. */
export function updateSecretMetadata(dc: DataConnect, vars: UpdateSecretMetadataVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateSecretMetadataData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateSecretMetadata' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateSecretMetadata(vars: UpdateSecretMetadataVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateSecretMetadataData>>;

/** Generated Node Admin SDK operation action function for the 'DeleteSecretMetadata' Mutation. Allow users to execute without passing in DataConnect. */
export function deleteSecretMetadata(dc: DataConnect, vars: DeleteSecretMetadataVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<DeleteSecretMetadataData>>;
/** Generated Node Admin SDK operation action function for the 'DeleteSecretMetadata' Mutation. Allow users to pass in custom DataConnect instances. */
export function deleteSecretMetadata(vars: DeleteSecretMetadataVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<DeleteSecretMetadataData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateWorkflowSecretKeys' Mutation. Allow users to execute without passing in DataConnect. */
export function updateWorkflowSecretKeys(dc: DataConnect, vars: UpdateWorkflowSecretKeysVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateWorkflowSecretKeysData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateWorkflowSecretKeys' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateWorkflowSecretKeys(vars: UpdateWorkflowSecretKeysVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateWorkflowSecretKeysData>>;

/** Generated Node Admin SDK operation action function for the 'UpsertWorkflowFromFirestore' Mutation. Allow users to execute without passing in DataConnect. */
export function upsertWorkflowFromFirestore(dc: DataConnect, vars: UpsertWorkflowFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertWorkflowFromFirestoreData>>;
/** Generated Node Admin SDK operation action function for the 'UpsertWorkflowFromFirestore' Mutation. Allow users to pass in custom DataConnect instances. */
export function upsertWorkflowFromFirestore(vars: UpsertWorkflowFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertWorkflowFromFirestoreData>>;

/** Generated Node Admin SDK operation action function for the 'CreateWorkflow' Mutation. Allow users to execute without passing in DataConnect. */
export function createWorkflow(dc: DataConnect, vars: CreateWorkflowVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateWorkflowData>>;
/** Generated Node Admin SDK operation action function for the 'CreateWorkflow' Mutation. Allow users to pass in custom DataConnect instances. */
export function createWorkflow(vars: CreateWorkflowVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateWorkflowData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateWorkflowName' Mutation. Allow users to execute without passing in DataConnect. */
export function updateWorkflowName(dc: DataConnect, vars: UpdateWorkflowNameVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateWorkflowNameData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateWorkflowName' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateWorkflowName(vars: UpdateWorkflowNameVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateWorkflowNameData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateWorkflowConfig' Mutation. Allow users to execute without passing in DataConnect. */
export function updateWorkflowConfig(dc: DataConnect, vars: UpdateWorkflowConfigVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateWorkflowConfigData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateWorkflowConfig' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateWorkflowConfig(vars: UpdateWorkflowConfigVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateWorkflowConfigData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateWorkflowSteps' Mutation. Allow users to execute without passing in DataConnect. */
export function updateWorkflowSteps(dc: DataConnect, vars: UpdateWorkflowStepsVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateWorkflowStepsData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateWorkflowSteps' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateWorkflowSteps(vars: UpdateWorkflowStepsVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateWorkflowStepsData>>;

/** Generated Node Admin SDK operation action function for the 'DeleteWorkflow' Mutation. Allow users to execute without passing in DataConnect. */
export function deleteWorkflow(dc: DataConnect, vars: DeleteWorkflowVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<DeleteWorkflowData>>;
/** Generated Node Admin SDK operation action function for the 'DeleteWorkflow' Mutation. Allow users to pass in custom DataConnect instances. */
export function deleteWorkflow(vars: DeleteWorkflowVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<DeleteWorkflowData>>;

/** Generated Node Admin SDK operation action function for the 'UpsertWorkflowFile' Mutation. Allow users to execute without passing in DataConnect. */
export function upsertWorkflowFile(dc: DataConnect, vars: UpsertWorkflowFileVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertWorkflowFileData>>;
/** Generated Node Admin SDK operation action function for the 'UpsertWorkflowFile' Mutation. Allow users to pass in custom DataConnect instances. */
export function upsertWorkflowFile(vars: UpsertWorkflowFileVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertWorkflowFileData>>;

/** Generated Node Admin SDK operation action function for the 'DeleteWorkflowFile' Mutation. Allow users to execute without passing in DataConnect. */
export function deleteWorkflowFile(dc: DataConnect, vars: DeleteWorkflowFileVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<DeleteWorkflowFileData>>;
/** Generated Node Admin SDK operation action function for the 'DeleteWorkflowFile' Mutation. Allow users to pass in custom DataConnect instances. */
export function deleteWorkflowFile(vars: DeleteWorkflowFileVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<DeleteWorkflowFileData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateWorkflowFileEnabled' Mutation. Allow users to execute without passing in DataConnect. */
export function updateWorkflowFileEnabled(dc: DataConnect, vars: UpdateWorkflowFileEnabledVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateWorkflowFileEnabledData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateWorkflowFileEnabled' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateWorkflowFileEnabled(vars: UpdateWorkflowFileEnabledVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateWorkflowFileEnabledData>>;

/** Generated Node Admin SDK operation action function for the 'CreateBuildJob' Mutation. Allow users to execute without passing in DataConnect. */
export function createBuildJob(dc: DataConnect, vars: CreateBuildJobVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateBuildJobData>>;
/** Generated Node Admin SDK operation action function for the 'CreateBuildJob' Mutation. Allow users to pass in custom DataConnect instances. */
export function createBuildJob(vars: CreateBuildJobVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateBuildJobData>>;

/** Generated Node Admin SDK operation action function for the 'UpsertBuildJobFromFirestore' Mutation. Allow users to execute without passing in DataConnect. */
export function upsertBuildJobFromFirestore(dc: DataConnect, vars: UpsertBuildJobFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertBuildJobFromFirestoreData>>;
/** Generated Node Admin SDK operation action function for the 'UpsertBuildJobFromFirestore' Mutation. Allow users to pass in custom DataConnect instances. */
export function upsertBuildJobFromFirestore(vars: UpsertBuildJobFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertBuildJobFromFirestoreData>>;

/** Generated Node Admin SDK operation action function for the 'UpsertBuildRunFromFirestore' Mutation. Allow users to execute without passing in DataConnect. */
export function upsertBuildRunFromFirestore(dc: DataConnect, vars: UpsertBuildRunFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertBuildRunFromFirestoreData>>;
/** Generated Node Admin SDK operation action function for the 'UpsertBuildRunFromFirestore' Mutation. Allow users to pass in custom DataConnect instances. */
export function upsertBuildRunFromFirestore(vars: UpsertBuildRunFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertBuildRunFromFirestoreData>>;

/** Generated Node Admin SDK operation action function for the 'UpsertBuildLogFromFirestore' Mutation. Allow users to execute without passing in DataConnect. */
export function upsertBuildLogFromFirestore(dc: DataConnect, vars: UpsertBuildLogFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertBuildLogFromFirestoreData>>;
/** Generated Node Admin SDK operation action function for the 'UpsertBuildLogFromFirestore' Mutation. Allow users to pass in custom DataConnect instances. */
export function upsertBuildLogFromFirestore(vars: UpsertBuildLogFromFirestoreVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpsertBuildLogFromFirestoreData>>;

/** Generated Node Admin SDK operation action function for the 'ClaimQueuedBuildJob' Mutation. Allow users to execute without passing in DataConnect. */
export function claimQueuedBuildJob(dc: DataConnect, vars: ClaimQueuedBuildJobVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ClaimQueuedBuildJobData>>;
/** Generated Node Admin SDK operation action function for the 'ClaimQueuedBuildJob' Mutation. Allow users to pass in custom DataConnect instances. */
export function claimQueuedBuildJob(vars: ClaimQueuedBuildJobVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ClaimQueuedBuildJobData>>;

/** Generated Node Admin SDK operation action function for the 'CreateBuildRunForWorker' Mutation. Allow users to execute without passing in DataConnect. */
export function createBuildRunForWorker(dc: DataConnect, vars: CreateBuildRunForWorkerVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateBuildRunForWorkerData>>;
/** Generated Node Admin SDK operation action function for the 'CreateBuildRunForWorker' Mutation. Allow users to pass in custom DataConnect instances. */
export function createBuildRunForWorker(vars: CreateBuildRunForWorkerVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateBuildRunForWorkerData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateBuildRunStatusForWorker' Mutation. Allow users to execute without passing in DataConnect. */
export function updateBuildRunStatusForWorker(dc: DataConnect, vars: UpdateBuildRunStatusForWorkerVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateBuildRunStatusForWorkerData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateBuildRunStatusForWorker' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateBuildRunStatusForWorker(vars: UpdateBuildRunStatusForWorkerVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateBuildRunStatusForWorkerData>>;

/** Generated Node Admin SDK operation action function for the 'AppendBuildLogForWorker' Mutation. Allow users to execute without passing in DataConnect. */
export function appendBuildLogForWorker(dc: DataConnect, vars: AppendBuildLogForWorkerVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<AppendBuildLogForWorkerData>>;
/** Generated Node Admin SDK operation action function for the 'AppendBuildLogForWorker' Mutation. Allow users to pass in custom DataConnect instances. */
export function appendBuildLogForWorker(vars: AppendBuildLogForWorkerVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<AppendBuildLogForWorkerData>>;

/** Generated Node Admin SDK operation action function for the 'CompleteBuildJobForWorker' Mutation. Allow users to execute without passing in DataConnect. */
export function completeBuildJobForWorker(dc: DataConnect, vars: CompleteBuildJobForWorkerVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CompleteBuildJobForWorkerData>>;
/** Generated Node Admin SDK operation action function for the 'CompleteBuildJobForWorker' Mutation. Allow users to pass in custom DataConnect instances. */
export function completeBuildJobForWorker(vars: CompleteBuildJobForWorkerVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CompleteBuildJobForWorkerData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateEnvironmentVariableValueForWorker' Mutation. Allow users to execute without passing in DataConnect. */
export function updateEnvironmentVariableValueForWorker(dc: DataConnect, vars: UpdateEnvironmentVariableValueForWorkerVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateEnvironmentVariableValueForWorkerData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateEnvironmentVariableValueForWorker' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateEnvironmentVariableValueForWorker(vars: UpdateEnvironmentVariableValueForWorkerVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateEnvironmentVariableValueForWorkerData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateBuildJobStatus' Mutation. Allow users to execute without passing in DataConnect. */
export function updateBuildJobStatus(dc: DataConnect, vars: UpdateBuildJobStatusVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateBuildJobStatusData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateBuildJobStatus' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateBuildJobStatus(vars: UpdateBuildJobStatusVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateBuildJobStatusData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateBuildJobFailureSummary' Mutation. Allow users to execute without passing in DataConnect. */
export function updateBuildJobFailureSummary(dc: DataConnect, vars: UpdateBuildJobFailureSummaryVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateBuildJobFailureSummaryData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateBuildJobFailureSummary' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateBuildJobFailureSummary(vars: UpdateBuildJobFailureSummaryVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateBuildJobFailureSummaryData>>;

/** Generated Node Admin SDK operation action function for the 'GetInvitationByToken' Query. Allow users to execute without passing in DataConnect. */
export function getInvitationByToken(dc: DataConnect, vars: GetInvitationByTokenVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetInvitationByTokenData>>;
/** Generated Node Admin SDK operation action function for the 'GetInvitationByToken' Query. Allow users to pass in custom DataConnect instances. */
export function getInvitationByToken(vars: GetInvitationByTokenVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetInvitationByTokenData>>;

/** Generated Node Admin SDK operation action function for the 'ListMyPendingInvitations' Query. Allow users to execute without passing in DataConnect. */
export function listMyPendingInvitations(dc: DataConnect, options?: OperationOptions): Promise<ExecuteOperationResponse<ListMyPendingInvitationsData>>;
/** Generated Node Admin SDK operation action function for the 'ListMyPendingInvitations' Query. Allow users to pass in custom DataConnect instances. */
export function listMyPendingInvitations(options?: OperationOptions): Promise<ExecuteOperationResponse<ListMyPendingInvitationsData>>;

/** Generated Node Admin SDK operation action function for the 'GetCurrentUser' Query. Allow users to execute without passing in DataConnect. */
export function getCurrentUser(dc: DataConnect, options?: OperationOptions): Promise<ExecuteOperationResponse<GetCurrentUserData>>;
/** Generated Node Admin SDK operation action function for the 'GetCurrentUser' Query. Allow users to pass in custom DataConnect instances. */
export function getCurrentUser(options?: OperationOptions): Promise<ExecuteOperationResponse<GetCurrentUserData>>;

/** Generated Node Admin SDK operation action function for the 'ListMyTeams' Query. Allow users to execute without passing in DataConnect. */
export function listMyTeams(dc: DataConnect, options?: OperationOptions): Promise<ExecuteOperationResponse<ListMyTeamsData>>;
/** Generated Node Admin SDK operation action function for the 'ListMyTeams' Query. Allow users to pass in custom DataConnect instances. */
export function listMyTeams(options?: OperationOptions): Promise<ExecuteOperationResponse<ListMyTeamsData>>;

/** Generated Node Admin SDK operation action function for the 'ListTeamPendingInvitations' Query. Allow users to execute without passing in DataConnect. */
export function listTeamPendingInvitations(dc: DataConnect, vars: ListTeamPendingInvitationsVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListTeamPendingInvitationsData>>;
/** Generated Node Admin SDK operation action function for the 'ListTeamPendingInvitations' Query. Allow users to pass in custom DataConnect instances. */
export function listTeamPendingInvitations(vars: ListTeamPendingInvitationsVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListTeamPendingInvitationsData>>;

/** Generated Node Admin SDK operation action function for the 'FindExistingPendingInvitation' Query. Allow users to execute without passing in DataConnect. */
export function findExistingPendingInvitation(dc: DataConnect, vars: FindExistingPendingInvitationVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<FindExistingPendingInvitationData>>;
/** Generated Node Admin SDK operation action function for the 'FindExistingPendingInvitation' Query. Allow users to pass in custom DataConnect instances. */
export function findExistingPendingInvitation(vars: FindExistingPendingInvitationVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<FindExistingPendingInvitationData>>;

/** Generated Node Admin SDK operation action function for the 'GetTeamForMember' Query. Allow users to execute without passing in DataConnect. */
export function getTeamForMember(dc: DataConnect, vars: GetTeamForMemberVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetTeamForMemberData>>;
/** Generated Node Admin SDK operation action function for the 'GetTeamForMember' Query. Allow users to pass in custom DataConnect instances. */
export function getTeamForMember(vars: GetTeamForMemberVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetTeamForMemberData>>;

/** Generated Node Admin SDK operation action function for the 'ListTeamMembers' Query. Allow users to execute without passing in DataConnect. */
export function listTeamMembers(dc: DataConnect, vars: ListTeamMembersVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListTeamMembersData>>;
/** Generated Node Admin SDK operation action function for the 'ListTeamMembers' Query. Allow users to pass in custom DataConnect instances. */
export function listTeamMembers(vars: ListTeamMembersVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListTeamMembersData>>;

/** Generated Node Admin SDK operation action function for the 'ListTeamNotificationUsers' Query. Allow users to execute without passing in DataConnect. */
export function listTeamNotificationUsers(dc: DataConnect, vars: ListTeamNotificationUsersVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListTeamNotificationUsersData>>;
/** Generated Node Admin SDK operation action function for the 'ListTeamNotificationUsers' Query. Allow users to pass in custom DataConnect instances. */
export function listTeamNotificationUsers(vars: ListTeamNotificationUsersVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListTeamNotificationUsersData>>;

/** Generated Node Admin SDK operation action function for the 'GetTeamById' Query. Allow users to execute without passing in DataConnect. */
export function getTeamById(dc: DataConnect, vars: GetTeamByIdVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetTeamByIdData>>;
/** Generated Node Admin SDK operation action function for the 'GetTeamById' Query. Allow users to pass in custom DataConnect instances. */
export function getTeamById(vars: GetTeamByIdVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetTeamByIdData>>;

/** Generated Node Admin SDK operation action function for the 'FindTeamByInstallation' Query. Allow users to execute without passing in DataConnect. */
export function findTeamByInstallation(dc: DataConnect, vars: FindTeamByInstallationVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<FindTeamByInstallationData>>;
/** Generated Node Admin SDK operation action function for the 'FindTeamByInstallation' Query. Allow users to pass in custom DataConnect instances. */
export function findTeamByInstallation(vars: FindTeamByInstallationVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<FindTeamByInstallationData>>;

/** Generated Node Admin SDK operation action function for the 'GetSecretsByNames' Query. Allow users to execute without passing in DataConnect. */
export function getSecretsByNames(dc: DataConnect, vars: GetSecretsByNamesVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetSecretsByNamesData>>;
/** Generated Node Admin SDK operation action function for the 'GetSecretsByNames' Query. Allow users to pass in custom DataConnect instances. */
export function getSecretsByNames(vars: GetSecretsByNamesVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetSecretsByNamesData>>;

/** Generated Node Admin SDK operation action function for the 'GetSecretsByNamesForTeam' Query. Allow users to execute without passing in DataConnect. */
export function getSecretsByNamesForTeam(dc: DataConnect, vars: GetSecretsByNamesForTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetSecretsByNamesForTeamData>>;
/** Generated Node Admin SDK operation action function for the 'GetSecretsByNamesForTeam' Query. Allow users to pass in custom DataConnect instances. */
export function getSecretsByNamesForTeam(vars: GetSecretsByNamesForTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetSecretsByNamesForTeamData>>;

/** Generated Node Admin SDK operation action function for the 'FindSecretByName' Query. Allow users to execute without passing in DataConnect. */
export function findSecretByName(dc: DataConnect, vars: FindSecretByNameVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<FindSecretByNameData>>;
/** Generated Node Admin SDK operation action function for the 'FindSecretByName' Query. Allow users to pass in custom DataConnect instances. */
export function findSecretByName(vars: FindSecretByNameVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<FindSecretByNameData>>;

/** Generated Node Admin SDK operation action function for the 'GetSecretForTeam' Query. Allow users to execute without passing in DataConnect. */
export function getSecretForTeam(dc: DataConnect, vars: GetSecretForTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetSecretForTeamData>>;
/** Generated Node Admin SDK operation action function for the 'GetSecretForTeam' Query. Allow users to pass in custom DataConnect instances. */
export function getSecretForTeam(vars: GetSecretForTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetSecretForTeamData>>;

/** Generated Node Admin SDK operation action function for the 'GetSecretPathForTeam' Query. Allow users to execute without passing in DataConnect. */
export function getSecretPathForTeam(dc: DataConnect, vars: GetSecretPathForTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetSecretPathForTeamData>>;
/** Generated Node Admin SDK operation action function for the 'GetSecretPathForTeam' Query. Allow users to pass in custom DataConnect instances. */
export function getSecretPathForTeam(vars: GetSecretPathForTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetSecretPathForTeamData>>;

/** Generated Node Admin SDK operation action function for the 'ListSecretsForTeam' Query. Allow users to execute without passing in DataConnect. */
export function listSecretsForTeam(dc: DataConnect, vars: ListSecretsForTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListSecretsForTeamData>>;
/** Generated Node Admin SDK operation action function for the 'ListSecretsForTeam' Query. Allow users to pass in custom DataConnect instances. */
export function listSecretsForTeam(vars: ListSecretsForTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListSecretsForTeamData>>;

/** Generated Node Admin SDK operation action function for the 'ListEnvironmentVariablesForTeam' Query. Allow users to execute without passing in DataConnect. */
export function listEnvironmentVariablesForTeam(dc: DataConnect, vars: ListEnvironmentVariablesForTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListEnvironmentVariablesForTeamData>>;
/** Generated Node Admin SDK operation action function for the 'ListEnvironmentVariablesForTeam' Query. Allow users to pass in custom DataConnect instances. */
export function listEnvironmentVariablesForTeam(vars: ListEnvironmentVariablesForTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListEnvironmentVariablesForTeamData>>;

/** Generated Node Admin SDK operation action function for the 'ListWorkerEnvironmentVariables' Query. Allow users to execute without passing in DataConnect. */
export function listWorkerEnvironmentVariables(dc: DataConnect, vars: ListWorkerEnvironmentVariablesVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListWorkerEnvironmentVariablesData>>;
/** Generated Node Admin SDK operation action function for the 'ListWorkerEnvironmentVariables' Query. Allow users to pass in custom DataConnect instances. */
export function listWorkerEnvironmentVariables(vars: ListWorkerEnvironmentVariablesVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListWorkerEnvironmentVariablesData>>;

/** Generated Node Admin SDK operation action function for the 'ListWorkerSecrets' Query. Allow users to execute without passing in DataConnect. */
export function listWorkerSecrets(dc: DataConnect, vars: ListWorkerSecretsVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListWorkerSecretsData>>;
/** Generated Node Admin SDK operation action function for the 'ListWorkerSecrets' Query. Allow users to pass in custom DataConnect instances. */
export function listWorkerSecrets(vars: ListWorkerSecretsVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListWorkerSecretsData>>;

/** Generated Node Admin SDK operation action function for the 'ListWorkflowsForTeam' Query. Allow users to execute without passing in DataConnect. */
export function listWorkflowsForTeam(dc: DataConnect, vars: ListWorkflowsForTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListWorkflowsForTeamData>>;
/** Generated Node Admin SDK operation action function for the 'ListWorkflowsForTeam' Query. Allow users to pass in custom DataConnect instances. */
export function listWorkflowsForTeam(vars: ListWorkflowsForTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListWorkflowsForTeamData>>;

/** Generated Node Admin SDK operation action function for the 'GetWorkflow' Query. Allow users to execute without passing in DataConnect. */
export function getWorkflow(dc: DataConnect, vars: GetWorkflowVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetWorkflowData>>;
/** Generated Node Admin SDK operation action function for the 'GetWorkflow' Query. Allow users to pass in custom DataConnect instances. */
export function getWorkflow(vars: GetWorkflowVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetWorkflowData>>;

/** Generated Node Admin SDK operation action function for the 'GetWorkflowFile' Query. Allow users to execute without passing in DataConnect. */
export function getWorkflowFile(dc: DataConnect, vars: GetWorkflowFileVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetWorkflowFileData>>;
/** Generated Node Admin SDK operation action function for the 'GetWorkflowFile' Query. Allow users to pass in custom DataConnect instances. */
export function getWorkflowFile(vars: GetWorkflowFileVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetWorkflowFileData>>;

/** Generated Node Admin SDK operation action function for the 'ListWorkflowFilesForBranch' Query. Allow users to execute without passing in DataConnect. */
export function listWorkflowFilesForBranch(dc: DataConnect, vars: ListWorkflowFilesForBranchVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListWorkflowFilesForBranchData>>;
/** Generated Node Admin SDK operation action function for the 'ListWorkflowFilesForBranch' Query. Allow users to pass in custom DataConnect instances. */
export function listWorkflowFilesForBranch(vars: ListWorkflowFilesForBranchVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListWorkflowFilesForBranchData>>;

/** Generated Node Admin SDK operation action function for the 'GetBuildJob' Query. Allow users to execute without passing in DataConnect. */
export function getBuildJob(dc: DataConnect, vars: GetBuildJobVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetBuildJobData>>;
/** Generated Node Admin SDK operation action function for the 'GetBuildJob' Query. Allow users to pass in custom DataConnect instances. */
export function getBuildJob(vars: GetBuildJobVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetBuildJobData>>;

/** Generated Node Admin SDK operation action function for the 'GetBuildJobForTeam' Query. Allow users to execute without passing in DataConnect. */
export function getBuildJobForTeam(dc: DataConnect, vars: GetBuildJobForTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetBuildJobForTeamData>>;
/** Generated Node Admin SDK operation action function for the 'GetBuildJobForTeam' Query. Allow users to pass in custom DataConnect instances. */
export function getBuildJobForTeam(vars: GetBuildJobForTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetBuildJobForTeamData>>;

/** Generated Node Admin SDK operation action function for the 'ListBuildJobsForTeam' Query. Allow users to execute without passing in DataConnect. */
export function listBuildJobsForTeam(dc: DataConnect, vars: ListBuildJobsForTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListBuildJobsForTeamData>>;
/** Generated Node Admin SDK operation action function for the 'ListBuildJobsForTeam' Query. Allow users to pass in custom DataConnect instances. */
export function listBuildJobsForTeam(vars: ListBuildJobsForTeamVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListBuildJobsForTeamData>>;

/** Generated Node Admin SDK operation action function for the 'ListBuildJobsByWorkflowRun' Query. Allow users to execute without passing in DataConnect. */
export function listBuildJobsByWorkflowRun(dc: DataConnect, vars: ListBuildJobsByWorkflowRunVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListBuildJobsByWorkflowRunData>>;
/** Generated Node Admin SDK operation action function for the 'ListBuildJobsByWorkflowRun' Query. Allow users to pass in custom DataConnect instances. */
export function listBuildJobsByWorkflowRun(vars: ListBuildJobsByWorkflowRunVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListBuildJobsByWorkflowRunData>>;

/** Generated Node Admin SDK operation action function for the 'ListWaitingBuildJobs' Query. Allow users to execute without passing in DataConnect. */
export function listWaitingBuildJobs(dc: DataConnect, vars: ListWaitingBuildJobsVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListWaitingBuildJobsData>>;
/** Generated Node Admin SDK operation action function for the 'ListWaitingBuildJobs' Query. Allow users to pass in custom DataConnect instances. */
export function listWaitingBuildJobs(vars: ListWaitingBuildJobsVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListWaitingBuildJobsData>>;

/** Generated Node Admin SDK operation action function for the 'ListBuildLogsForRun' Query. Allow users to execute without passing in DataConnect. */
export function listBuildLogsForRun(dc: DataConnect, vars: ListBuildLogsForRunVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListBuildLogsForRunData>>;
/** Generated Node Admin SDK operation action function for the 'ListBuildLogsForRun' Query. Allow users to pass in custom DataConnect instances. */
export function listBuildLogsForRun(vars: ListBuildLogsForRunVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListBuildLogsForRunData>>;

/** Generated Node Admin SDK operation action function for the 'ListLatestBuildLogs' Query. Allow users to execute without passing in DataConnect. */
export function listLatestBuildLogs(dc: DataConnect, vars: ListLatestBuildLogsVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListLatestBuildLogsData>>;
/** Generated Node Admin SDK operation action function for the 'ListLatestBuildLogs' Query. Allow users to pass in custom DataConnect instances. */
export function listLatestBuildLogs(vars: ListLatestBuildLogsVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<ListLatestBuildLogsData>>;

