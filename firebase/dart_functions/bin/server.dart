import 'dart:io';

import 'package:dart_functions/ai/ai_workflow_handler.dart';
import 'package:dart_functions/asc/asc_list_apps.dart';
import 'package:dart_functions/asc/asc_list_builds.dart';
import 'package:dart_functions/asc/asc_requests.dart';
import 'package:dart_functions/asc/asc_submit_for_review.dart';
import 'package:dart_functions/asc/asc_submit_to_testflight.dart';
import 'package:dart_functions/build_job/build_job_status_handler.dart';
import 'package:dart_functions/build_job/generate_failure_summary.dart';
import 'package:dart_functions/build_job/cancel_build_job.dart';
import 'package:dart_functions/build_job/check_run_handler.dart';
import 'package:dart_functions/build_job/retry_handlers.dart';
import 'package:dart_functions/github/github_callable_handlers.dart';
import 'package:dart_functions/github/github_setup.dart';
import 'package:dart_functions/github/github_webhook_handler.dart';
import 'package:dart_functions/secrets/secrets_handlers.dart';
import 'package:dart_functions/team/process_invitations.dart';
import 'package:dart_functions/team/team_handlers.dart';
import 'package:dart_functions/util/sentry_init.dart';
import 'package:firebase_functions/firebase_functions.dart';

Future<void> main(List<String> args) async {
  try {
    await initSentry();
  } catch (e) {
    stderr.writeln('Warning: Sentry initialization failed: $e');
  }

  await fireUp(args, (firebase) {
    // -----------------------------------------------------------------------
    // HTTP Request handlers
    // -----------------------------------------------------------------------

    firebase.https.onRequest(
      handleGitHubWebhook,
      name: 'githubWebhook',
      options: const HttpsOptions(
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
    );

    firebase.https.onRequest(
      handleGitHubSetup,
      name: 'githubSetup',
      options: const HttpsOptions(
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
    );

    // -----------------------------------------------------------------------
    // ASC (App Store Connect) callable functions
    // -----------------------------------------------------------------------

    firebase.https.onCallWithData<TeamRequest, Map<String, dynamic>>(
      handleAscListApps,
      fromJson: TeamRequest.fromJson,
      name: 'ascListApps',
      options: const CallableOptions(
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
    );

    firebase.https.onCallWithData<ListBuildsRequest, Map<String, dynamic>>(
      handleAscListBuilds,
      fromJson: ListBuildsRequest.fromJson,
      name: 'ascListBuilds',
      options: const CallableOptions(
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
    );

    firebase.https
        .onCallWithData<SubmitToTestFlightRequest, Map<String, dynamic>>(
          handleAscSubmitToTestFlight,
          fromJson: SubmitToTestFlightRequest.fromJson,
          name: 'ascSubmitToTestFlight',
          options: const CallableOptions(
            region: DeployOption(SupportedRegion.asiaNortheast1),
          ),
        );

    firebase.https.onCallWithData<SubmitForReviewRequest, Map<String, dynamic>>(
      handleAscSubmitForReview,
      fromJson: SubmitForReviewRequest.fromJson,
      name: 'ascSubmitForReview',
      options: const CallableOptions(
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
    );

    // -----------------------------------------------------------------------
    // Build job callable functions
    // -----------------------------------------------------------------------

    firebase.https.onCallWithData<CancelBuildJobRequest, Map<String, dynamic>>(
      handleCancelBuildJob,
      fromJson: CancelBuildJobRequest.fromJson,
      name: 'cancelBuildJob',
      options: const CallableOptions(
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
    );

    firebase.https
        .onCallWithData<BuildJobStatusChangeRequest, Map<String, dynamic>>(
          handleBuildJobStatusChange,
          fromJson: BuildJobStatusChangeRequest.fromJson,
          name: 'buildJobStatusChange',
          options: const CallableOptions(
            region: DeployOption(SupportedRegion.asiaNortheast1),
          ),
        );

    firebase.https
        .onCallWithData<GenerateFailureSummaryRequest, Map<String, dynamic>>(
          handleGenerateFailureSummary,
          fromJson: GenerateFailureSummaryRequest.fromJson,
          name: 'generateFailureSummary',
          options: const CallableOptions(
            region: DeployOption(SupportedRegion.asiaNortheast1),
            timeoutSeconds: DeployOption(120),
          ),
        );

    firebase.https.onCallWithData<CheckRunUpdateRequest, Map<String, dynamic>>(
      handleCheckRunUpdate,
      fromJson: CheckRunUpdateRequest.fromJson,
      name: 'checkRunUpdate',
      options: const CallableOptions(
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
    );

    firebase.https.onCallWithData<RetryBuildJobRequest, Map<String, dynamic>>(
      handleRetryBuildJob,
      fromJson: RetryBuildJobRequest.fromJson,
      name: 'retryBuildJob',
      options: const CallableOptions(
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
    );

    firebase.https
        .onCallWithData<RetryWorkflowRunRequest, Map<String, dynamic>>(
          handleRetryWorkflowRun,
          fromJson: RetryWorkflowRunRequest.fromJson,
          name: 'retryWorkflowRun',
          options: const CallableOptions(
            region: DeployOption(SupportedRegion.asiaNortheast1),
          ),
        );

    // -----------------------------------------------------------------------
    // Secret management callable functions
    // -----------------------------------------------------------------------

    firebase.https.onCallWithData<CreateSecretRequest, Map<String, dynamic>>(
      handleCreateSecret,
      fromJson: CreateSecretRequest.fromJson,
      name: 'createSecretV1',
      options: const CallableOptions(
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
    );

    firebase.https.onCallWithData<DeleteSecretRequest, Map<String, dynamic>>(
      handleDeleteSecret,
      fromJson: DeleteSecretRequest.fromJson,
      name: 'deleteSecretV1',
      options: const CallableOptions(
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
    );

    firebase.https.onCallWithData<UpdateSecretRequest, Map<String, dynamic>>(
      handleUpdateSecret,
      fromJson: UpdateSecretRequest.fromJson,
      name: 'updateSecretV1',
      options: const CallableOptions(
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
    );

    firebase.https
        .onCallWithData<GenerateCertificateKeyRequest, Map<String, dynamic>>(
          handleGenerateCertificateKey,
          fromJson: GenerateCertificateKeyRequest.fromJson,
          name: 'generateCertificateKeyV1',
          options: const CallableOptions(
            region: DeployOption(SupportedRegion.asiaNortheast1),
          ),
        );

    firebase.https.onCallWithData<SetupAscApiKeyRequest, Map<String, dynamic>>(
      handleSetupAscApiKey,
      fromJson: SetupAscApiKeyRequest.fromJson,
      name: 'setupAscApiKeyV1',
      options: const CallableOptions(
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
    );

    // -----------------------------------------------------------------------
    // Team management callable functions
    // -----------------------------------------------------------------------

    firebase.https.onCallWithData<GetTeamMembersRequest, Map<String, dynamic>>(
      handleGetTeamMembers,
      fromJson: GetTeamMembersRequest.fromJson,
      name: 'getTeamMembers',
      options: const CallableOptions(
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
    );

    firebase.https
        .onCallWithData<InviteTeamMemberRequest, Map<String, dynamic>>(
          handleInviteTeamMember,
          fromJson: InviteTeamMemberRequest.fromJson,
          name: 'inviteTeamMember',
          options: const CallableOptions(
            region: DeployOption(SupportedRegion.asiaNortheast1),
          ),
        );

    firebase.https
        .onCallWithData<AcceptInvitationRequest, Map<String, dynamic>>(
          handleAcceptInvitation,
          fromJson: AcceptInvitationRequest.fromJson,
          name: 'acceptInvitation',
          options: const CallableOptions(
            region: DeployOption(SupportedRegion.asiaNortheast1),
          ),
        );

    firebase.https.onCall(
      handleProcessInvitationsOnSignUp,
      name: 'processInvitationsOnSignUp',
      options: const CallableOptions(
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
    );

    // -----------------------------------------------------------------------
    // GitHub callable functions
    // -----------------------------------------------------------------------

    firebase.https.onCallWithData<TeamIdRequest, Map<String, dynamic>>(
      handleListRepositories,
      fromJson: TeamIdRequest.fromJson,
      name: 'listRepositories',
      options: const CallableOptions(
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
    );

    firebase.https.onCallWithData<RepoRequest, Map<String, dynamic>>(
      handleListBranches,
      fromJson: RepoRequest.fromJson,
      name: 'listBranches',
      options: const CallableOptions(
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
    );

    firebase.https.onCallWithData<RepoRequest, Map<String, dynamic>>(
      handleListDirectories,
      fromJson: RepoRequest.fromJson,
      name: 'listDirectories',
      options: const CallableOptions(
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
    );

    firebase.https
        .onCallWithData<ListWorkflowFilesRequest, Map<String, dynamic>>(
          handleListWorkflowFiles,
          fromJson: ListWorkflowFilesRequest.fromJson,
          name: 'listWorkflowFiles',
          options: const CallableOptions(
            region: DeployOption(SupportedRegion.asiaNortheast1),
          ),
        );

    firebase.https
        .onCallWithData<SearchGitHubActionsRequest, Map<String, dynamic>>(
          handleSearchGitHubActions,
          fromJson: SearchGitHubActionsRequest.fromJson,
          name: 'searchGitHubActions',
          options: const CallableOptions(
            region: DeployOption(SupportedRegion.asiaNortheast1),
          ),
        );

    firebase.https
        .onCallWithData<CreateWorkflowFileRequest, Map<String, dynamic>>(
          handleCreateWorkflowFile,
          fromJson: CreateWorkflowFileRequest.fromJson,
          name: 'createWorkflowFile',
          options: const CallableOptions(
            region: DeployOption(SupportedRegion.asiaNortheast1),
          ),
        );

    firebase.https
        .onCallWithData<SyncWorkflowFilesRequest, Map<String, dynamic>>(
          handleSyncWorkflowFiles,
          fromJson: SyncWorkflowFilesRequest.fromJson,
          name: 'syncWorkflowFiles',
          options: const CallableOptions(
            region: DeployOption(SupportedRegion.asiaNortheast1),
          ),
        );

    // -----------------------------------------------------------------------
    // AI callable functions
    // -----------------------------------------------------------------------

    firebase.https
        .onCallWithData<GenerateAiWorkflowRequest, Map<String, dynamic>>(
          handleGenerateAiWorkflow,
          fromJson: GenerateAiWorkflowRequest.fromJson,
          name: 'generateAiWorkflowResponse',
          options: const CallableOptions(
            region: DeployOption(SupportedRegion.asiaNortheast1),
            timeoutSeconds: DeployOption(60),
          ),
        );
  });
}
