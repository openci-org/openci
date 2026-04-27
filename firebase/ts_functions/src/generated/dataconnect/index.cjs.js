const { validateAdminArgs } = require('firebase-admin/data-connect');

const InvitationStatus = {
  PENDING: "PENDING",
  ACCEPTED: "ACCEPTED",
  EXPIRED: "EXPIRED",
}
exports.InvitationStatus = InvitationStatus;

const connectorConfig = {
  connector: 'default',
  serviceId: 'openci-dmis-a6d69-service',
  location: 'asia-northeast1'
};
exports.connectorConfig = connectorConfig;

function getInvitationByToken(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetInvitationByToken', inputVars, inputOpts);
}
exports.getInvitationByToken = getInvitationByToken;

function listMyPendingInvitations(dcOrOptions, options) {
  const { dc: dcInstance, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrOptions, options, undefined);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListMyPendingInvitations', undefined, inputOpts);
}
exports.listMyPendingInvitations = listMyPendingInvitations;

function getCurrentUser(dcOrOptions, options) {
  const { dc: dcInstance, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrOptions, options, undefined);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetCurrentUser', undefined, inputOpts);
}
exports.getCurrentUser = getCurrentUser;

function listMyTeams(dcOrOptions, options) {
  const { dc: dcInstance, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrOptions, options, undefined);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListMyTeams', undefined, inputOpts);
}
exports.listMyTeams = listMyTeams;

function listTeamPendingInvitations(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListTeamPendingInvitations', inputVars, inputOpts);
}
exports.listTeamPendingInvitations = listTeamPendingInvitations;

function findExistingPendingInvitation(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('FindExistingPendingInvitation', inputVars, inputOpts);
}
exports.findExistingPendingInvitation = findExistingPendingInvitation;

function getTeamForMember(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetTeamForMember', inputVars, inputOpts);
}
exports.getTeamForMember = getTeamForMember;

function listTeamMembers(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListTeamMembers', inputVars, inputOpts);
}
exports.listTeamMembers = listTeamMembers;

function listTeamNotificationUsers(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListTeamNotificationUsers', inputVars, inputOpts);
}
exports.listTeamNotificationUsers = listTeamNotificationUsers;

function getTeamById(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetTeamById', inputVars, inputOpts);
}
exports.getTeamById = getTeamById;

function findTeamByInstallation(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('FindTeamByInstallation', inputVars, inputOpts);
}
exports.findTeamByInstallation = findTeamByInstallation;

function getSecretsByNames(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetSecretsByNames', inputVars, inputOpts);
}
exports.getSecretsByNames = getSecretsByNames;

function getSecretsByNamesForTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetSecretsByNamesForTeam', inputVars, inputOpts);
}
exports.getSecretsByNamesForTeam = getSecretsByNamesForTeam;

function findSecretByName(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('FindSecretByName', inputVars, inputOpts);
}
exports.findSecretByName = findSecretByName;

function getSecretForTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetSecretForTeam', inputVars, inputOpts);
}
exports.getSecretForTeam = getSecretForTeam;

function getSecretPathForTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetSecretPathForTeam', inputVars, inputOpts);
}
exports.getSecretPathForTeam = getSecretPathForTeam;

function listSecretsForTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListSecretsForTeam', inputVars, inputOpts);
}
exports.listSecretsForTeam = listSecretsForTeam;

function listEnvironmentVariablesForTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListEnvironmentVariablesForTeam', inputVars, inputOpts);
}
exports.listEnvironmentVariablesForTeam = listEnvironmentVariablesForTeam;

function listWorkerEnvironmentVariables(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListWorkerEnvironmentVariables', inputVars, inputOpts);
}
exports.listWorkerEnvironmentVariables = listWorkerEnvironmentVariables;

function listWorkerSecrets(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListWorkerSecrets', inputVars, inputOpts);
}
exports.listWorkerSecrets = listWorkerSecrets;

function listWorkflowsForTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListWorkflowsForTeam', inputVars, inputOpts);
}
exports.listWorkflowsForTeam = listWorkflowsForTeam;

function getWorkflow(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetWorkflow', inputVars, inputOpts);
}
exports.getWorkflow = getWorkflow;

function getWorkflowFile(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetWorkflowFile', inputVars, inputOpts);
}
exports.getWorkflowFile = getWorkflowFile;

function listWorkflowFilesForBranch(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListWorkflowFilesForBranch', inputVars, inputOpts);
}
exports.listWorkflowFilesForBranch = listWorkflowFilesForBranch;

function getBuildJob(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetBuildJob', inputVars, inputOpts);
}
exports.getBuildJob = getBuildJob;

function getBuildJobForTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetBuildJobForTeam', inputVars, inputOpts);
}
exports.getBuildJobForTeam = getBuildJobForTeam;

function listBuildJobsForTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListBuildJobsForTeam', inputVars, inputOpts);
}
exports.listBuildJobsForTeam = listBuildJobsForTeam;

function listBuildJobsByWorkflowRun(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListBuildJobsByWorkflowRun', inputVars, inputOpts);
}
exports.listBuildJobsByWorkflowRun = listBuildJobsByWorkflowRun;

function listWaitingBuildJobs(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListWaitingBuildJobs', inputVars, inputOpts);
}
exports.listWaitingBuildJobs = listWaitingBuildJobs;

function listBuildLogsForRun(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListBuildLogsForRun', inputVars, inputOpts);
}
exports.listBuildLogsForRun = listBuildLogsForRun;

function listLatestBuildLogs(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListLatestBuildLogs', inputVars, inputOpts);
}
exports.listLatestBuildLogs = listLatestBuildLogs;

function createInvitation(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('CreateInvitation', inputVars, inputOpts);
}
exports.createInvitation = createInvitation;

function reinviteInvitation(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('ReinviteInvitation', inputVars, inputOpts);
}
exports.reinviteInvitation = reinviteInvitation;

function acceptInvitation(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('AcceptInvitation', inputVars, inputOpts);
}
exports.acceptInvitation = acceptInvitation;

function expireInvitation(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('ExpireInvitation', inputVars, inputOpts);
}
exports.expireInvitation = expireInvitation;

function acceptInvitationAndJoinTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('AcceptInvitationAndJoinTeam', inputVars, inputOpts);
}
exports.acceptInvitationAndJoinTeam = acceptInvitationAndJoinTeam;

function linkGitHubInstallation(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('LinkGitHubInstallation', inputVars, inputOpts);
}
exports.linkGitHubInstallation = linkGitHubInstallation;

function upsertUserProfile(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpsertUserProfile', inputVars, inputOpts);
}
exports.upsertUserProfile = upsertUserProfile;

function updateCurrentUserSelectedTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateCurrentUserSelectedTeam', inputVars, inputOpts);
}
exports.updateCurrentUserSelectedTeam = updateCurrentUserSelectedTeam;

function updateCurrentUserNotificationPreference(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateCurrentUserNotificationPreference', inputVars, inputOpts);
}
exports.updateCurrentUserNotificationPreference = updateCurrentUserNotificationPreference;

function updateCurrentUserFcmTokens(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateCurrentUserFcmTokens', inputVars, inputOpts);
}
exports.updateCurrentUserFcmTokens = updateCurrentUserFcmTokens;

function addCurrentUserFcmToken(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('AddCurrentUserFcmToken', inputVars, inputOpts);
}
exports.addCurrentUserFcmToken = addCurrentUserFcmToken;

function updateCurrentUserRepositorySelection(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateCurrentUserRepositorySelection', inputVars, inputOpts);
}
exports.updateCurrentUserRepositorySelection = updateCurrentUserRepositorySelection;

function updateCurrentUserSelectedBranch(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateCurrentUserSelectedBranch', inputVars, inputOpts);
}
exports.updateCurrentUserSelectedBranch = updateCurrentUserSelectedBranch;

function upsertUserFromFirestore(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpsertUserFromFirestore', inputVars, inputOpts);
}
exports.upsertUserFromFirestore = upsertUserFromFirestore;

function upsertTeamFromFirestore(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpsertTeamFromFirestore', inputVars, inputOpts);
}
exports.upsertTeamFromFirestore = upsertTeamFromFirestore;

function createTeamForCurrentUser(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('CreateTeamForCurrentUser', inputVars, inputOpts);
}
exports.createTeamForCurrentUser = createTeamForCurrentUser;

function updateTeamName(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateTeamName', inputVars, inputOpts);
}
exports.updateTeamName = updateTeamName;

function updateTeamAiEnabled(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateTeamAiEnabled', inputVars, inputOpts);
}
exports.updateTeamAiEnabled = updateTeamAiEnabled;

function updateTeamGitHubSettings(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateTeamGitHubSettings', inputVars, inputOpts);
}
exports.updateTeamGitHubSettings = updateTeamGitHubSettings;

function deleteTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('DeleteTeam', inputVars, inputOpts);
}
exports.deleteTeam = deleteTeam;

function upsertTeamMemberFromFirestore(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpsertTeamMemberFromFirestore', inputVars, inputOpts);
}
exports.upsertTeamMemberFromFirestore = upsertTeamMemberFromFirestore;

function updateUserFcmTokens(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateUserFcmTokens', inputVars, inputOpts);
}
exports.updateUserFcmTokens = updateUserFcmTokens;

function addTeamMember(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('AddTeamMember', inputVars, inputOpts);
}
exports.addTeamMember = addTeamMember;

function createSecretMetadata(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('CreateSecretMetadata', inputVars, inputOpts);
}
exports.createSecretMetadata = createSecretMetadata;

function upsertSecretMetadataFromFirestore(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpsertSecretMetadataFromFirestore', inputVars, inputOpts);
}
exports.upsertSecretMetadataFromFirestore = upsertSecretMetadataFromFirestore;

function upsertEnvironmentVariableFromFirestore(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpsertEnvironmentVariableFromFirestore', inputVars, inputOpts);
}
exports.upsertEnvironmentVariableFromFirestore = upsertEnvironmentVariableFromFirestore;

function createEnvironmentVariable(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('CreateEnvironmentVariable', inputVars, inputOpts);
}
exports.createEnvironmentVariable = createEnvironmentVariable;

function updateEnvironmentVariable(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateEnvironmentVariable', inputVars, inputOpts);
}
exports.updateEnvironmentVariable = updateEnvironmentVariable;

function deleteEnvironmentVariable(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('DeleteEnvironmentVariable', inputVars, inputOpts);
}
exports.deleteEnvironmentVariable = deleteEnvironmentVariable;

function upsertInvitationFromFirestore(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpsertInvitationFromFirestore', inputVars, inputOpts);
}
exports.upsertInvitationFromFirestore = upsertInvitationFromFirestore;

function updateSecretMetadata(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateSecretMetadata', inputVars, inputOpts);
}
exports.updateSecretMetadata = updateSecretMetadata;

function deleteSecretMetadata(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('DeleteSecretMetadata', inputVars, inputOpts);
}
exports.deleteSecretMetadata = deleteSecretMetadata;

function updateWorkflowSecretKeys(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateWorkflowSecretKeys', inputVars, inputOpts);
}
exports.updateWorkflowSecretKeys = updateWorkflowSecretKeys;

function upsertWorkflowFromFirestore(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpsertWorkflowFromFirestore', inputVars, inputOpts);
}
exports.upsertWorkflowFromFirestore = upsertWorkflowFromFirestore;

function createWorkflow(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('CreateWorkflow', inputVars, inputOpts);
}
exports.createWorkflow = createWorkflow;

function updateWorkflowName(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateWorkflowName', inputVars, inputOpts);
}
exports.updateWorkflowName = updateWorkflowName;

function updateWorkflowConfig(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateWorkflowConfig', inputVars, inputOpts);
}
exports.updateWorkflowConfig = updateWorkflowConfig;

function updateWorkflowSteps(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateWorkflowSteps', inputVars, inputOpts);
}
exports.updateWorkflowSteps = updateWorkflowSteps;

function deleteWorkflow(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('DeleteWorkflow', inputVars, inputOpts);
}
exports.deleteWorkflow = deleteWorkflow;

function upsertWorkflowFile(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpsertWorkflowFile', inputVars, inputOpts);
}
exports.upsertWorkflowFile = upsertWorkflowFile;

function deleteWorkflowFile(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('DeleteWorkflowFile', inputVars, inputOpts);
}
exports.deleteWorkflowFile = deleteWorkflowFile;

function updateWorkflowFileEnabled(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateWorkflowFileEnabled', inputVars, inputOpts);
}
exports.updateWorkflowFileEnabled = updateWorkflowFileEnabled;

function createBuildJob(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('CreateBuildJob', inputVars, inputOpts);
}
exports.createBuildJob = createBuildJob;

function upsertBuildJobFromFirestore(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpsertBuildJobFromFirestore', inputVars, inputOpts);
}
exports.upsertBuildJobFromFirestore = upsertBuildJobFromFirestore;

function upsertBuildRunFromFirestore(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpsertBuildRunFromFirestore', inputVars, inputOpts);
}
exports.upsertBuildRunFromFirestore = upsertBuildRunFromFirestore;

function upsertBuildLogFromFirestore(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpsertBuildLogFromFirestore', inputVars, inputOpts);
}
exports.upsertBuildLogFromFirestore = upsertBuildLogFromFirestore;

function claimQueuedBuildJob(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('ClaimQueuedBuildJob', inputVars, inputOpts);
}
exports.claimQueuedBuildJob = claimQueuedBuildJob;

function createBuildRunForWorker(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('CreateBuildRunForWorker', inputVars, inputOpts);
}
exports.createBuildRunForWorker = createBuildRunForWorker;

function updateBuildRunStatusForWorker(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateBuildRunStatusForWorker', inputVars, inputOpts);
}
exports.updateBuildRunStatusForWorker = updateBuildRunStatusForWorker;

function appendBuildLogForWorker(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('AppendBuildLogForWorker', inputVars, inputOpts);
}
exports.appendBuildLogForWorker = appendBuildLogForWorker;

function completeBuildJobForWorker(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('CompleteBuildJobForWorker', inputVars, inputOpts);
}
exports.completeBuildJobForWorker = completeBuildJobForWorker;

function updateEnvironmentVariableValueForWorker(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateEnvironmentVariableValueForWorker', inputVars, inputOpts);
}
exports.updateEnvironmentVariableValueForWorker = updateEnvironmentVariableValueForWorker;

function updateBuildJobStatus(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateBuildJobStatus', inputVars, inputOpts);
}
exports.updateBuildJobStatus = updateBuildJobStatus;

function updateBuildJobFailureSummary(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation('UpdateBuildJobFailureSummary', inputVars, inputOpts);
}
exports.updateBuildJobFailureSummary = updateBuildJobFailureSummary;

function getTeamForMember(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetTeamForMember', inputVars, inputOpts);
}
exports.getTeamForMember = getTeamForMember;

function listTeamMembers(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListTeamMembers', inputVars, inputOpts);
}
exports.listTeamMembers = listTeamMembers;

function listTeamNotificationUsers(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListTeamNotificationUsers', inputVars, inputOpts);
}
exports.listTeamNotificationUsers = listTeamNotificationUsers;

function getTeamById(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetTeamById', inputVars, inputOpts);
}
exports.getTeamById = getTeamById;

function findTeamByInstallation(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('FindTeamByInstallation', inputVars, inputOpts);
}
exports.findTeamByInstallation = findTeamByInstallation;

function getSecretsByNames(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetSecretsByNames', inputVars, inputOpts);
}
exports.getSecretsByNames = getSecretsByNames;

function getSecretsByNamesForTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetSecretsByNamesForTeam', inputVars, inputOpts);
}
exports.getSecretsByNamesForTeam = getSecretsByNamesForTeam;

function findSecretByName(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('FindSecretByName', inputVars, inputOpts);
}
exports.findSecretByName = findSecretByName;

function getSecretForTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetSecretForTeam', inputVars, inputOpts);
}
exports.getSecretForTeam = getSecretForTeam;

function listSecretsForTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListSecretsForTeam', inputVars, inputOpts);
}
exports.listSecretsForTeam = listSecretsForTeam;

function listEnvironmentVariablesForTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListEnvironmentVariablesForTeam', inputVars, inputOpts);
}
exports.listEnvironmentVariablesForTeam = listEnvironmentVariablesForTeam;

function listWorkerEnvironmentVariables(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListWorkerEnvironmentVariables', inputVars, inputOpts);
}
exports.listWorkerEnvironmentVariables = listWorkerEnvironmentVariables;

function listWorkerSecrets(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListWorkerSecrets', inputVars, inputOpts);
}
exports.listWorkerSecrets = listWorkerSecrets;

function listWorkflowsForTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListWorkflowsForTeam', inputVars, inputOpts);
}
exports.listWorkflowsForTeam = listWorkflowsForTeam;

function getWorkflow(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetWorkflow', inputVars, inputOpts);
}
exports.getWorkflow = getWorkflow;

function getWorkflowFile(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetWorkflowFile', inputVars, inputOpts);
}
exports.getWorkflowFile = getWorkflowFile;

function listWorkflowFilesForBranch(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListWorkflowFilesForBranch', inputVars, inputOpts);
}
exports.listWorkflowFilesForBranch = listWorkflowFilesForBranch;

function getBuildJob(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetBuildJob', inputVars, inputOpts);
}
exports.getBuildJob = getBuildJob;

function getBuildJobForTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('GetBuildJobForTeam', inputVars, inputOpts);
}
exports.getBuildJobForTeam = getBuildJobForTeam;

function listBuildJobsForTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListBuildJobsForTeam', inputVars, inputOpts);
}
exports.listBuildJobsForTeam = listBuildJobsForTeam;

function listBuildJobsByWorkflowRun(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListBuildJobsByWorkflowRun', inputVars, inputOpts);
}
exports.listBuildJobsByWorkflowRun = listBuildJobsByWorkflowRun;

function listWaitingBuildJobs(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListWaitingBuildJobs', inputVars, inputOpts);
}
exports.listWaitingBuildJobs = listWaitingBuildJobs;

function listBuildLogsForRun(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListBuildLogsForRun', inputVars, inputOpts);
}
exports.listBuildLogsForRun = listBuildLogsForRun;

function listLatestBuildLogs(dcOrVarsOrOptions, varsOrOptions, options) {
  const { dc: dcInstance, vars: inputVars, options: inputOpts} = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery('ListLatestBuildLogs', inputVars, inputOpts);
}
exports.listLatestBuildLogs = listLatestBuildLogs;

