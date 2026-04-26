library openci_dataconnect;

import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

part 'create_invitation.dart';

part 'reinvite_invitation.dart';

part 'accept_invitation.dart';

part 'expire_invitation.dart';

part 'accept_invitation_and_join_team.dart';

part 'link_git_hub_installation.dart';

part 'upsert_user_profile.dart';

part 'update_current_user_selected_team.dart';

part 'update_current_user_notification_preference.dart';

part 'update_current_user_fcm_tokens.dart';

part 'add_current_user_fcm_token.dart';

part 'update_current_user_repository_selection.dart';

part 'update_current_user_selected_branch.dart';

part 'upsert_user_from_firestore.dart';

part 'upsert_team_from_firestore.dart';

part 'create_team_for_current_user.dart';

part 'update_team_name.dart';

part 'update_team_ai_enabled.dart';

part 'delete_team.dart';

part 'upsert_team_member_from_firestore.dart';

part 'update_user_fcm_tokens.dart';

part 'add_team_member.dart';

part 'create_secret_metadata.dart';

part 'upsert_secret_metadata_from_firestore.dart';

part 'upsert_environment_variable_from_firestore.dart';

part 'create_environment_variable.dart';

part 'update_environment_variable.dart';

part 'delete_environment_variable.dart';

part 'upsert_invitation_from_firestore.dart';

part 'update_secret_metadata.dart';

part 'delete_secret_metadata.dart';

part 'update_workflow_secret_keys.dart';

part 'upsert_workflow_from_firestore.dart';

part 'create_workflow.dart';

part 'update_workflow_name.dart';

part 'update_workflow_config.dart';

part 'update_workflow_steps.dart';

part 'delete_workflow.dart';

part 'upsert_workflow_file.dart';

part 'delete_workflow_file.dart';

part 'update_workflow_file_enabled.dart';

part 'create_build_job.dart';

part 'upsert_build_job_from_firestore.dart';

part 'upsert_build_run_from_firestore.dart';

part 'upsert_build_log_from_firestore.dart';

part 'claim_queued_build_job.dart';

part 'create_build_run_for_worker.dart';

part 'update_build_run_status_for_worker.dart';

part 'append_build_log_for_worker.dart';

part 'complete_build_job_for_worker.dart';

part 'update_environment_variable_value_for_worker.dart';

part 'update_build_job_status.dart';

part 'update_build_job_failure_summary.dart';

part 'get_invitation_by_token.dart';

part 'list_my_pending_invitations.dart';

part 'get_current_user.dart';

part 'list_my_teams.dart';

part 'list_team_pending_invitations.dart';

part 'find_existing_pending_invitation.dart';

part 'get_team_for_member.dart';

part 'list_team_members.dart';

part 'list_team_notification_users.dart';

part 'get_team_by_id.dart';

part 'find_team_by_installation.dart';

part 'get_secrets_by_names.dart';

part 'get_secrets_by_names_for_team.dart';

part 'find_secret_by_name.dart';

part 'get_secret_for_team.dart';

part 'list_secrets_for_team.dart';

part 'list_environment_variables_for_team.dart';

part 'list_worker_environment_variables.dart';

part 'list_worker_secrets.dart';

part 'list_workflows_for_team.dart';

part 'get_workflow.dart';

part 'get_workflow_file.dart';

part 'list_workflow_files_for_branch.dart';

part 'get_build_job.dart';

part 'get_build_job_for_team.dart';

part 'list_build_jobs_for_team.dart';

part 'list_build_jobs_by_workflow_run.dart';

part 'list_waiting_build_jobs.dart';

part 'list_build_logs_for_run.dart';

part 'list_latest_build_logs.dart';

String bigIntToJson(BigInt value) {
  return value.toString();
}

BigInt bigIntFromJson(dynamic value) {
  return BigInt.parse(value);
}

enum InvitationStatus {
  PENDING,

  ACCEPTED,

  EXPIRED,
}

String invitationStatusSerializer(EnumValue<InvitationStatus> e) {
  return e.stringValue;
}

EnumValue<InvitationStatus> invitationStatusDeserializer(dynamic data) {
  switch (data) {
    case 'PENDING':
      return const Known(InvitationStatus.PENDING);

    case 'ACCEPTED':
      return const Known(InvitationStatus.ACCEPTED);

    case 'EXPIRED':
      return const Known(InvitationStatus.EXPIRED);

    default:
      return Unknown(data);
  }
}

String enumSerializer(Enum e) {
  return e.name;
}

/// A sealed class representing either a known enum value or an unknown string value.
@immutable
sealed class EnumValue<T extends Enum> {
  const EnumValue();

  /// The string representation of the value.
  String get stringValue;
  @override
  String toString() {
    return "EnumValue($stringValue)";
  }
}

/// Represents a known, valid enum value.
class Known<T extends Enum> extends EnumValue<T> {
  /// The actual enum value.
  final T value;

  const Known(this.value);

  @override
  String get stringValue => value.name;

  @override
  String toString() {
    return "Known($stringValue)";
  }
}

/// Represents an unknown or unrecognized enum value.
class Unknown extends EnumValue<Never> {
  /// The raw string value that couldn't be mapped to a known enum.
  @override
  final String stringValue;

  const Unknown(this.stringValue);
  @override
  String toString() {
    return "Unknown($stringValue)";
  }
}

class DefaultConnector {
  CreateInvitationVariablesBuilder createInvitation({
    required String email,
    required String teamId,
    required String teamNameSnapshot,
    required String token,
    required Timestamp expiresAt,
  }) {
    return CreateInvitationVariablesBuilder(
      dataConnect,
      email: email,
      teamId: teamId,
      teamNameSnapshot: teamNameSnapshot,
      token: token,
      expiresAt: expiresAt,
    );
  }

  ReinviteInvitationVariablesBuilder reinviteInvitation({
    required String id,
    required String teamId,
    required String token,
    required Timestamp expiresAt,
  }) {
    return ReinviteInvitationVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
      token: token,
      expiresAt: expiresAt,
    );
  }

  AcceptInvitationVariablesBuilder acceptInvitation({
    required String id,
  }) {
    return AcceptInvitationVariablesBuilder(
      dataConnect,
      id: id,
    );
  }

  ExpireInvitationVariablesBuilder expireInvitation({
    required String id,
  }) {
    return ExpireInvitationVariablesBuilder(
      dataConnect,
      id: id,
    );
  }

  AcceptInvitationAndJoinTeamVariablesBuilder acceptInvitationAndJoinTeam({
    required String id,
    required String teamId,
  }) {
    return AcceptInvitationAndJoinTeamVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
    );
  }

  LinkGitHubInstallationVariablesBuilder linkGitHubInstallation({
    required String teamId,
    required int installationId,
  }) {
    return LinkGitHubInstallationVariablesBuilder(
      dataConnect,
      teamId: teamId,
      installationId: installationId,
    );
  }

  UpsertUserProfileVariablesBuilder upsertUserProfile({
    required String id,
    required String email,
  }) {
    return UpsertUserProfileVariablesBuilder(
      dataConnect,
      id: id,
      email: email,
    );
  }

  UpdateCurrentUserSelectedTeamVariablesBuilder updateCurrentUserSelectedTeam({
    required String teamId,
  }) {
    return UpdateCurrentUserSelectedTeamVariablesBuilder(
      dataConnect,
      teamId: teamId,
    );
  }

  UpdateCurrentUserNotificationPreferenceVariablesBuilder
  updateCurrentUserNotificationPreference({
    required String notificationPreference,
  }) {
    return UpdateCurrentUserNotificationPreferenceVariablesBuilder(
      dataConnect,
      notificationPreference: notificationPreference,
    );
  }

  UpdateCurrentUserFcmTokensVariablesBuilder updateCurrentUserFcmTokens({
    required List<String> fcmTokens,
  }) {
    return UpdateCurrentUserFcmTokensVariablesBuilder(
      dataConnect,
      fcmTokens: fcmTokens,
    );
  }

  AddCurrentUserFcmTokenVariablesBuilder addCurrentUserFcmToken({
    required String token,
  }) {
    return AddCurrentUserFcmTokenVariablesBuilder(
      dataConnect,
      token: token,
    );
  }

  UpdateCurrentUserRepositorySelectionVariablesBuilder
  updateCurrentUserRepositorySelection({
    required String repository,
    required String branch,
  }) {
    return UpdateCurrentUserRepositorySelectionVariablesBuilder(
      dataConnect,
      repository: repository,
      branch: branch,
    );
  }

  UpdateCurrentUserSelectedBranchVariablesBuilder
  updateCurrentUserSelectedBranch({
    required String branch,
  }) {
    return UpdateCurrentUserSelectedBranchVariablesBuilder(
      dataConnect,
      branch: branch,
    );
  }

  UpsertUserFromFirestoreVariablesBuilder upsertUserFromFirestore({
    required String id,
    required String email,
  }) {
    return UpsertUserFromFirestoreVariablesBuilder(
      dataConnect,
      id: id,
      email: email,
    );
  }

  UpsertTeamFromFirestoreVariablesBuilder upsertTeamFromFirestore({
    required String id,
    required String name,
  }) {
    return UpsertTeamFromFirestoreVariablesBuilder(
      dataConnect,
      id: id,
      name: name,
    );
  }

  CreateTeamForCurrentUserVariablesBuilder createTeamForCurrentUser({
    required String id,
    required String name,
  }) {
    return CreateTeamForCurrentUserVariablesBuilder(
      dataConnect,
      id: id,
      name: name,
    );
  }

  UpdateTeamNameVariablesBuilder updateTeamName({
    required String teamId,
    required String name,
  }) {
    return UpdateTeamNameVariablesBuilder(
      dataConnect,
      teamId: teamId,
      name: name,
    );
  }

  UpdateTeamAiEnabledVariablesBuilder updateTeamAiEnabled({
    required String teamId,
    required bool aiEnabled,
  }) {
    return UpdateTeamAiEnabledVariablesBuilder(
      dataConnect,
      teamId: teamId,
      aiEnabled: aiEnabled,
    );
  }

  DeleteTeamVariablesBuilder deleteTeam({
    required String teamId,
  }) {
    return DeleteTeamVariablesBuilder(
      dataConnect,
      teamId: teamId,
    );
  }

  UpsertTeamMemberFromFirestoreVariablesBuilder upsertTeamMemberFromFirestore({
    required String teamId,
    required String userId,
    required String email,
  }) {
    return UpsertTeamMemberFromFirestoreVariablesBuilder(
      dataConnect,
      teamId: teamId,
      userId: userId,
      email: email,
    );
  }

  UpdateUserFcmTokensVariablesBuilder updateUserFcmTokens({
    required String id,
    required List<String> fcmTokens,
  }) {
    return UpdateUserFcmTokensVariablesBuilder(
      dataConnect,
      id: id,
      fcmTokens: fcmTokens,
    );
  }

  AddTeamMemberVariablesBuilder addTeamMember({
    required String teamId,
    required String userId,
    required String email,
  }) {
    return AddTeamMemberVariablesBuilder(
      dataConnect,
      teamId: teamId,
      userId: userId,
      email: email,
    );
  }

  CreateSecretMetadataVariablesBuilder createSecretMetadata({
    required String id,
    required String name,
    required String teamId,
    required String pathToSecret,
  }) {
    return CreateSecretMetadataVariablesBuilder(
      dataConnect,
      id: id,
      name: name,
      teamId: teamId,
      pathToSecret: pathToSecret,
    );
  }

  UpsertSecretMetadataFromFirestoreVariablesBuilder
  upsertSecretMetadataFromFirestore({
    required String id,
    required String name,
    required String teamId,
  }) {
    return UpsertSecretMetadataFromFirestoreVariablesBuilder(
      dataConnect,
      id: id,
      name: name,
      teamId: teamId,
    );
  }

  UpsertEnvironmentVariableFromFirestoreVariablesBuilder
  upsertEnvironmentVariableFromFirestore({
    required String id,
    required String envKey,
    required String value,
    required String teamId,
  }) {
    return UpsertEnvironmentVariableFromFirestoreVariablesBuilder(
      dataConnect,
      id: id,
      envKey: envKey,
      value: value,
      teamId: teamId,
    );
  }

  CreateEnvironmentVariableVariablesBuilder createEnvironmentVariable({
    required String id,
    required String envKey,
    required String value,
    required String teamId,
  }) {
    return CreateEnvironmentVariableVariablesBuilder(
      dataConnect,
      id: id,
      envKey: envKey,
      value: value,
      teamId: teamId,
    );
  }

  UpdateEnvironmentVariableVariablesBuilder updateEnvironmentVariable({
    required String id,
    required String teamId,
    required String envKey,
    required String value,
  }) {
    return UpdateEnvironmentVariableVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
      envKey: envKey,
      value: value,
    );
  }

  DeleteEnvironmentVariableVariablesBuilder deleteEnvironmentVariable({
    required String id,
    required String teamId,
  }) {
    return DeleteEnvironmentVariableVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
    );
  }

  UpsertInvitationFromFirestoreVariablesBuilder upsertInvitationFromFirestore({
    required String id,
    required String email,
    required String teamId,
    required String teamNameSnapshot,
    required String token,
    required InvitationStatus status,
    required Timestamp expiresAt,
  }) {
    return UpsertInvitationFromFirestoreVariablesBuilder(
      dataConnect,
      id: id,
      email: email,
      teamId: teamId,
      teamNameSnapshot: teamNameSnapshot,
      token: token,
      status: status,
      expiresAt: expiresAt,
    );
  }

  UpdateSecretMetadataVariablesBuilder updateSecretMetadata({
    required String id,
    required String name,
  }) {
    return UpdateSecretMetadataVariablesBuilder(
      dataConnect,
      id: id,
      name: name,
    );
  }

  DeleteSecretMetadataVariablesBuilder deleteSecretMetadata({
    required String id,
  }) {
    return DeleteSecretMetadataVariablesBuilder(
      dataConnect,
      id: id,
    );
  }

  UpdateWorkflowSecretKeysVariablesBuilder updateWorkflowSecretKeys({
    required String id,
    required dynamic workflowSteps,
  }) {
    return UpdateWorkflowSecretKeysVariablesBuilder(
      dataConnect,
      id: id,
      workflowSteps: workflowSteps,
    );
  }

  UpsertWorkflowFromFirestoreVariablesBuilder upsertWorkflowFromFirestore({
    required String id,
    required String teamId,
  }) {
    return UpsertWorkflowFromFirestoreVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
    );
  }

  CreateWorkflowVariablesBuilder createWorkflow({
    required String id,
    required String teamId,
    required String name,
    required dynamic workflowConfig,
    required dynamic workflowSteps,
    required bool isEditing,
  }) {
    return CreateWorkflowVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
      name: name,
      workflowConfig: workflowConfig,
      workflowSteps: workflowSteps,
      isEditing: isEditing,
    );
  }

  UpdateWorkflowNameVariablesBuilder updateWorkflowName({
    required String id,
    required String teamId,
    required String name,
  }) {
    return UpdateWorkflowNameVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
      name: name,
    );
  }

  UpdateWorkflowConfigVariablesBuilder updateWorkflowConfig({
    required String id,
    required String teamId,
    required dynamic workflowConfig,
  }) {
    return UpdateWorkflowConfigVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
      workflowConfig: workflowConfig,
    );
  }

  UpdateWorkflowStepsVariablesBuilder updateWorkflowSteps({
    required String id,
    required String teamId,
    required dynamic workflowSteps,
  }) {
    return UpdateWorkflowStepsVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
      workflowSteps: workflowSteps,
    );
  }

  DeleteWorkflowVariablesBuilder deleteWorkflow({
    required String id,
    required String teamId,
  }) {
    return DeleteWorkflowVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
    );
  }

  UpsertWorkflowFileVariablesBuilder upsertWorkflowFile({
    required String id,
    required String teamId,
    required String repository,
    required String branch,
    required String fileName,
    required String filePath,
    required String content,
  }) {
    return UpsertWorkflowFileVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
      repository: repository,
      branch: branch,
      fileName: fileName,
      filePath: filePath,
      content: content,
    );
  }

  DeleteWorkflowFileVariablesBuilder deleteWorkflowFile({
    required String id,
  }) {
    return DeleteWorkflowFileVariablesBuilder(
      dataConnect,
      id: id,
    );
  }

  UpdateWorkflowFileEnabledVariablesBuilder updateWorkflowFileEnabled({
    required String id,
    required String teamId,
    required bool enabled,
  }) {
    return UpdateWorkflowFileEnabledVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
      enabled: enabled,
    );
  }

  CreateBuildJobVariablesBuilder createBuildJob({
    required String id,
    required String status,
    required String owner,
    required String repo,
  }) {
    return CreateBuildJobVariablesBuilder(
      dataConnect,
      id: id,
      status: status,
      owner: owner,
      repo: repo,
    );
  }

  UpsertBuildJobFromFirestoreVariablesBuilder upsertBuildJobFromFirestore({
    required String id,
    required String status,
    required String owner,
    required String repo,
  }) {
    return UpsertBuildJobFromFirestoreVariablesBuilder(
      dataConnect,
      id: id,
      status: status,
      owner: owner,
      repo: repo,
    );
  }

  UpsertBuildRunFromFirestoreVariablesBuilder upsertBuildRunFromFirestore({
    required String buildJobId,
    required String id,
  }) {
    return UpsertBuildRunFromFirestoreVariablesBuilder(
      dataConnect,
      buildJobId: buildJobId,
      id: id,
    );
  }

  UpsertBuildLogFromFirestoreVariablesBuilder upsertBuildLogFromFirestore({
    required String buildJobId,
    required String runId,
    required String id,
    required String message,
    required Timestamp timestamp,
  }) {
    return UpsertBuildLogFromFirestoreVariablesBuilder(
      dataConnect,
      buildJobId: buildJobId,
      runId: runId,
      id: id,
      message: message,
      timestamp: timestamp,
    );
  }

  ClaimQueuedBuildJobVariablesBuilder claimQueuedBuildJob({
    required String runsOnPattern,
  }) {
    return ClaimQueuedBuildJobVariablesBuilder(
      dataConnect,
      runsOnPattern: runsOnPattern,
    );
  }

  CreateBuildRunForWorkerVariablesBuilder createBuildRunForWorker({
    required String buildJobId,
    required String id,
  }) {
    return CreateBuildRunForWorkerVariablesBuilder(
      dataConnect,
      buildJobId: buildJobId,
      id: id,
    );
  }

  UpdateBuildRunStatusForWorkerVariablesBuilder updateBuildRunStatusForWorker({
    required String buildJobId,
    required String runId,
    required String status,
  }) {
    return UpdateBuildRunStatusForWorkerVariablesBuilder(
      dataConnect,
      buildJobId: buildJobId,
      runId: runId,
      status: status,
    );
  }

  AppendBuildLogForWorkerVariablesBuilder appendBuildLogForWorker({
    required String buildJobId,
    required String runId,
    required String id,
    required String message,
    required String level,
    required Timestamp timestamp,
  }) {
    return AppendBuildLogForWorkerVariablesBuilder(
      dataConnect,
      buildJobId: buildJobId,
      runId: runId,
      id: id,
      message: message,
      level: level,
      timestamp: timestamp,
    );
  }

  CompleteBuildJobForWorkerVariablesBuilder completeBuildJobForWorker({
    required String id,
    required String status,
    required Timestamp completedAt,
  }) {
    return CompleteBuildJobForWorkerVariablesBuilder(
      dataConnect,
      id: id,
      status: status,
      completedAt: completedAt,
    );
  }

  UpdateEnvironmentVariableValueForWorkerVariablesBuilder
  updateEnvironmentVariableValueForWorker({
    required String id,
    required String value,
  }) {
    return UpdateEnvironmentVariableValueForWorkerVariablesBuilder(
      dataConnect,
      id: id,
      value: value,
    );
  }

  UpdateBuildJobStatusVariablesBuilder updateBuildJobStatus({
    required String id,
    required String status,
  }) {
    return UpdateBuildJobStatusVariablesBuilder(
      dataConnect,
      id: id,
      status: status,
    );
  }

  UpdateBuildJobFailureSummaryVariablesBuilder updateBuildJobFailureSummary({
    required String id,
    required String failureSummaryStatus,
  }) {
    return UpdateBuildJobFailureSummaryVariablesBuilder(
      dataConnect,
      id: id,
      failureSummaryStatus: failureSummaryStatus,
    );
  }

  GetInvitationByTokenVariablesBuilder getInvitationByToken({
    required String token,
  }) {
    return GetInvitationByTokenVariablesBuilder(
      dataConnect,
      token: token,
    );
  }

  ListMyPendingInvitationsVariablesBuilder listMyPendingInvitations() {
    return ListMyPendingInvitationsVariablesBuilder(
      dataConnect,
    );
  }

  GetCurrentUserVariablesBuilder getCurrentUser() {
    return GetCurrentUserVariablesBuilder(
      dataConnect,
    );
  }

  ListMyTeamsVariablesBuilder listMyTeams() {
    return ListMyTeamsVariablesBuilder(
      dataConnect,
    );
  }

  ListTeamPendingInvitationsVariablesBuilder listTeamPendingInvitations({
    required String teamId,
  }) {
    return ListTeamPendingInvitationsVariablesBuilder(
      dataConnect,
      teamId: teamId,
    );
  }

  FindExistingPendingInvitationVariablesBuilder findExistingPendingInvitation({
    required String email,
    required String teamId,
  }) {
    return FindExistingPendingInvitationVariablesBuilder(
      dataConnect,
      email: email,
      teamId: teamId,
    );
  }

  GetTeamForMemberVariablesBuilder getTeamForMember({
    required String teamId,
  }) {
    return GetTeamForMemberVariablesBuilder(
      dataConnect,
      teamId: teamId,
    );
  }

  ListTeamMembersVariablesBuilder listTeamMembers({
    required String teamId,
  }) {
    return ListTeamMembersVariablesBuilder(
      dataConnect,
      teamId: teamId,
    );
  }

  ListTeamNotificationUsersVariablesBuilder listTeamNotificationUsers({
    required String teamId,
  }) {
    return ListTeamNotificationUsersVariablesBuilder(
      dataConnect,
      teamId: teamId,
    );
  }

  GetTeamByIdVariablesBuilder getTeamById({
    required String teamId,
  }) {
    return GetTeamByIdVariablesBuilder(
      dataConnect,
      teamId: teamId,
    );
  }

  FindTeamByInstallationVariablesBuilder findTeamByInstallation({
    required int installationId,
  }) {
    return FindTeamByInstallationVariablesBuilder(
      dataConnect,
      installationId: installationId,
    );
  }

  GetSecretsByNamesVariablesBuilder getSecretsByNames({
    required String teamId,
    required List<String> names,
  }) {
    return GetSecretsByNamesVariablesBuilder(
      dataConnect,
      teamId: teamId,
      names: names,
    );
  }

  GetSecretsByNamesForTeamVariablesBuilder getSecretsByNamesForTeam({
    required String teamId,
    required List<String> names,
  }) {
    return GetSecretsByNamesForTeamVariablesBuilder(
      dataConnect,
      teamId: teamId,
      names: names,
    );
  }

  FindSecretByNameVariablesBuilder findSecretByName({
    required String teamId,
    required String name,
  }) {
    return FindSecretByNameVariablesBuilder(
      dataConnect,
      teamId: teamId,
      name: name,
    );
  }

  GetSecretForTeamVariablesBuilder getSecretForTeam({
    required String id,
    required String teamId,
  }) {
    return GetSecretForTeamVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
    );
  }

  ListSecretsForTeamVariablesBuilder listSecretsForTeam({
    required String teamId,
  }) {
    return ListSecretsForTeamVariablesBuilder(
      dataConnect,
      teamId: teamId,
    );
  }

  ListEnvironmentVariablesForTeamVariablesBuilder
  listEnvironmentVariablesForTeam({
    required String teamId,
  }) {
    return ListEnvironmentVariablesForTeamVariablesBuilder(
      dataConnect,
      teamId: teamId,
    );
  }

  ListWorkerEnvironmentVariablesVariablesBuilder
  listWorkerEnvironmentVariables({
    required String teamId,
  }) {
    return ListWorkerEnvironmentVariablesVariablesBuilder(
      dataConnect,
      teamId: teamId,
    );
  }

  ListWorkerSecretsVariablesBuilder listWorkerSecrets({
    required String teamId,
  }) {
    return ListWorkerSecretsVariablesBuilder(
      dataConnect,
      teamId: teamId,
    );
  }

  ListWorkflowsForTeamVariablesBuilder listWorkflowsForTeam({
    required String teamId,
  }) {
    return ListWorkflowsForTeamVariablesBuilder(
      dataConnect,
      teamId: teamId,
    );
  }

  GetWorkflowVariablesBuilder getWorkflow({
    required String id,
    required String teamId,
  }) {
    return GetWorkflowVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
    );
  }

  GetWorkflowFileVariablesBuilder getWorkflowFile({
    required String id,
  }) {
    return GetWorkflowFileVariablesBuilder(
      dataConnect,
      id: id,
    );
  }

  ListWorkflowFilesForBranchVariablesBuilder listWorkflowFilesForBranch({
    required String teamId,
    required String repository,
    required String branch,
  }) {
    return ListWorkflowFilesForBranchVariablesBuilder(
      dataConnect,
      teamId: teamId,
      repository: repository,
      branch: branch,
    );
  }

  GetBuildJobVariablesBuilder getBuildJob({
    required String id,
  }) {
    return GetBuildJobVariablesBuilder(
      dataConnect,
      id: id,
    );
  }

  GetBuildJobForTeamVariablesBuilder getBuildJobForTeam({
    required String id,
    required String teamId,
  }) {
    return GetBuildJobForTeamVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
    );
  }

  ListBuildJobsForTeamVariablesBuilder listBuildJobsForTeam({
    required String teamId,
    required int limit,
  }) {
    return ListBuildJobsForTeamVariablesBuilder(
      dataConnect,
      teamId: teamId,
      limit: limit,
    );
  }

  ListBuildJobsByWorkflowRunVariablesBuilder listBuildJobsByWorkflowRun({
    required String workflowRunId,
  }) {
    return ListBuildJobsByWorkflowRunVariablesBuilder(
      dataConnect,
      workflowRunId: workflowRunId,
    );
  }

  ListWaitingBuildJobsVariablesBuilder listWaitingBuildJobs({
    required String workflowRunId,
  }) {
    return ListWaitingBuildJobsVariablesBuilder(
      dataConnect,
      workflowRunId: workflowRunId,
    );
  }

  ListBuildLogsForRunVariablesBuilder listBuildLogsForRun({
    required String buildJobId,
    required String runId,
    required String teamId,
  }) {
    return ListBuildLogsForRunVariablesBuilder(
      dataConnect,
      buildJobId: buildJobId,
      runId: runId,
      teamId: teamId,
    );
  }

  ListLatestBuildLogsVariablesBuilder listLatestBuildLogs({
    required String buildJobId,
    required String runId,
    required int limit,
  }) {
    return ListLatestBuildLogsVariablesBuilder(
      dataConnect,
      buildJobId: buildJobId,
      runId: runId,
      limit: limit,
    );
  }

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'asia-northeast1',
    'default',
    'openci-b1b91-3-service',
  );

  DefaultConnector({required this.dataConnect});
  static DefaultConnector get instance {
    return DefaultConnector(
      dataConnect: FirebaseDataConnect.instanceFor(
        connectorConfig: connectorConfig,

        sdkType: CallerSDKType.generated,
      ),
    );
  }

  FirebaseDataConnect dataConnect;
}
