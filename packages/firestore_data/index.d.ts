export const connectorConfig: {
  connector: string;
  serviceId: string;
  location: string;
};

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

export type TimestampString = string;
export type UUIDString = string;
export type Int64String = string;
export type DateString = string;

export interface ExecuteOperationResponse<TData = Record<string, unknown>> {
  data: TData;
}

export interface OperationOptions {
  impersonate?: {
    authClaims?: Record<string, unknown>;
  };
}

export type AnyVars = Record<string, unknown>;
export type AnyData = Record<string, unknown>;

type Operation<TVars extends AnyVars = AnyVars, TData extends AnyData = AnyData> = (
  vars?: TVars,
  options?: OperationOptions,
) => Promise<ExecuteOperationResponse<TData>>;

export interface TeamData extends Record<string, unknown> {
  id: string;
  name: string;
  members?: string[] | null;
  installationIds?: number[] | null;
  aiEnabled?: boolean | null;
  githubApiBaseUrl?: string | null;
  githubBaseUrl?: string | null;
}

export interface BuildJobData extends Record<string, unknown> {
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
  installationId?: string | number | null;
  installationToken?: string | null;
  tokenExpiresAt?: string | null;
  checkRunId?: string | number | null;
  commitSha?: string | null;
  pullRequestNumber?: number | null;
  tagName?: string | null;
  branch?: string | null;
  runsOn?: string | null;
  githubApiBaseUrl?: string | null;
  githubBaseUrl?: string | null;
  runCount?: number | null;
  latestRunId?: string | null;
  createdAt?: string | null;
  updatedAt?: string | null;
  completedAt?: string | null;
}

export interface UserData extends Record<string, unknown> {
  id: string;
  email?: string | null;
  displayName?: string | null;
  photoUrl?: string | null;
  notificationPreference?: string | null;
  fcmTokens?: string[] | null;
}

export interface SecretData extends Record<string, unknown> {
  id: string;
  name: string;
  teamId: string;
  pathToSecret?: string | null;
}

export interface EnvironmentVariableData extends Record<string, unknown> {
  id: string;
  key: string;
  value: string;
  autoIncrement?: boolean | null;
}

export interface BuildLogData extends Record<string, unknown> {
  id: string;
  message: string;
  level?: string | null;
  timestamp?: string | null;
  stackTrace?: string | null;
}

export interface WorkflowData extends Record<string, unknown> {
  id: string;
  teamId: string;
  name?: string | null;
  workflowConfig?: unknown;
  workflowSteps?: unknown;
  isEditing?: boolean | null;
}

export interface WorkflowFileData extends Record<string, unknown> {
  id: string;
  teamId: string;
  repository: string;
  branch: string;
  fileName: string;
  filePath: string;
  content: string;
  enabled?: boolean | null;
}

export interface InvitationData extends Record<string, unknown> {
  id: string;
  email: string;
  status: InvitationStatus | string;
  expiresAt: string;
  teamNameSnapshot: string;
  team: TeamData;
}

export const getTeamById: Operation<{ teamId: string }, { team?: TeamData | null }>;
export const getTeamForMember: Operation<{ teamId: string }, { team?: TeamData | null }>;
export const findTeamByInstallation: Operation<{ installationId: number }, { teams: TeamData[] }>;
export const linkGitHubInstallation: Operation<{ teamId: string; installationId: number }>;
export const listTeamMembers: Operation<{ teamId: string }, { teamMembers: Array<{ userId: string; user: UserData }> }>;
export const listTeamNotificationUsers: Operation<{ teamId: string }, { teamMembers: Array<{ userId: string; user: UserData }> }>;
export const addTeamMember: Operation<{ teamId: string; userId: string; email: string }>;

export const createInvitation: Operation;
export const reinviteInvitation: Operation;
export const findExistingPendingInvitation: Operation<{ email: string; teamId: string }, { invitations: InvitationData[] }>;
export const getInvitationByToken: Operation<{ token: string }, { invitations: InvitationData[] }>;
export const listMyPendingInvitations: Operation<AnyVars, { invitations: InvitationData[] }>;
export const expireInvitation: Operation<{ id: string }>;
export const acceptInvitationAndJoinTeam: Operation<{ id: string; teamId: string }>;

export const listWorkflowFilesForBranch: Operation<AnyVars, { workflowFiles: WorkflowFileData[] }>;
export const getWorkflowFile: Operation<{ id: string }, { workflowFile?: WorkflowFileData | null }>;
export const upsertWorkflowFile: Operation;
export const deleteWorkflowFile: Operation<{ id: string }>;

export const createBuildJob: Operation<AnyVars, { buildJob_insert: { id: string } }>;
export const getBuildJob: Operation<{ id: string }, { buildJob?: BuildJobData | null }>;
export const updateBuildJobStatus: Operation<{ id: string; status: BuildJobStatus }>;
export const listBuildJobsByWorkflowRun: Operation<{ workflowRunId: string }, { buildJobs: BuildJobData[] }>;
export const listWaitingBuildJobs: Operation<{ workflowRunId: string }, { buildJobs: BuildJobData[] }>;
export const claimQueuedBuildJob: Operation<{ runsOnPattern: string }, { job?: BuildJobData | null }>;
export const createBuildRunForWorker: Operation<{ buildJobId: string; id: string }>;
export const appendBuildLogForWorker: Operation;
export const updateBuildRunStatusForWorker: Operation;
export const completeBuildJobForWorker: Operation<{ id: string; status: BuildJobStatus; completedAt: string }>;
export const listLatestBuildLogs: Operation<AnyVars, { buildLogs: BuildLogData[] }>;
export const updateBuildJobFailureSummary: Operation;

export const updateUserFcmTokens: Operation<{ id: string; fcmTokens: string[] }>;
export const findSecretByNameForTeam: Operation<{ teamId: string; name: string }, { secrets: SecretData[] }>;
export const getSecretsByNamesForTeam: Operation<{ teamId: string; names: string[] }, { secrets: SecretData[] }>;
export const listWorkerSecrets: Operation<{ teamId: string }, { secrets: SecretData[] }>;
export const createSecretMetadata: Operation;
export const getSecretPathForTeam: Operation<{ id: string; teamId: string }, { secret?: SecretData | null }>;
export const updateSecretMetadata: Operation;
export const deleteSecretMetadata: Operation<{ id: string }>;

export const listWorkflowsForTeam: Operation<{ teamId: string }, { workflows: WorkflowData[] }>;
export const updateWorkflowSecretKeys: Operation<{ id: string; workflowSteps: unknown }>;
export const listWorkerEnvironmentVariables: Operation<{ teamId: string }, { environmentVariables: EnvironmentVariableData[] }>;
export const updateEnvironmentVariableValueForWorker: Operation<{ id: string; value: string }>;
