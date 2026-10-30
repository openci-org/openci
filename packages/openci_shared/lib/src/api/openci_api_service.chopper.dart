// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'openci_api_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$OpenCIApiService extends OpenCIApiService {
  _$OpenCIApiService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = OpenCIApiService;

  @override
  Future<Response<List<Team>>> getTeams() {
    final Uri $url = Uri.parse('/teams');
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<List<Team>, Team>($request)
        .catchError(
          (_) => Future<Response<List<Team>>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Team>> getTeamByInstallationId(int installationId) {
    final Uri $url = Uri.parse('/teams/by-installation/${installationId}');
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Team, Team>($request)
        .catchError(
          (_) => Future<Response<Team>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Map<String, dynamic>>> createTeam(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/teams');
    final $body = body;
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Map<String, dynamic>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<Map<String, dynamic>>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<void>> updateTeam(String id, Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/teams/${id}');
    final $body = body;
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<void, void>($request)
        .catchError(
          (_) => Future<Response<void>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<void>> deleteTeam(String id) {
    final Uri $url = Uri.parse('/teams/${id}');
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<void, void>($request)
        .catchError(
          (_) => Future<Response<void>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Map<String, dynamic>>> getBillingStatus(String teamId) {
    final Uri $url = Uri.parse('/teams/${teamId}/billing');
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Map<String, dynamic>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<Map<String, dynamic>>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Map<String, dynamic>>> createBillingCheckout(
    String teamId,
    String planId,
  ) {
    final Uri $url = Uri.parse('/teams/${teamId}/billing/checkout');
    final $body = <String, dynamic>{'planId': planId};
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 60000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Map<String, dynamic>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<Map<String, dynamic>>>.error(
            ChopperTimeoutException('Request timed out after 1 minute'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Map<String, dynamic>>> createBillingPortal(String teamId) {
    final Uri $url = Uri.parse('/teams/${teamId}/billing/portal');
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 60000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Map<String, dynamic>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<Map<String, dynamic>>>.error(
            ChopperTimeoutException('Request timed out after 1 minute'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Map<String, dynamic>>> startGitHubConnection(String teamId) {
    final Uri $url = Uri.parse('/teams/${teamId}/github/connect');
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Map<String, dynamic>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<Map<String, dynamic>>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<GitHubConnectionSessionResult>> getGitHubConnectionSession(
    String teamId,
    String reference,
  ) {
    final Uri $url = Uri.parse('/teams/${teamId}/github/session');
    final $body = <String, dynamic>{'reference': reference};
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<GitHubConnectionSessionResult, GitHubConnectionSessionResult>(
          $request,
        )
        .catchError(
          (_) => Future<Response<GitHubConnectionSessionResult>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<GitHubConnectionCandidatesResult>>
  getGitHubConnectionCandidates(String teamId, String reference) {
    final Uri $url = Uri.parse('/teams/${teamId}/github/candidates');
    final $body = <String, dynamic>{'reference': reference};
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 60000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<
          GitHubConnectionCandidatesResult,
          GitHubConnectionCandidatesResult
        >($request)
        .catchError(
          (_) => Future<Response<GitHubConnectionCandidatesResult>>.error(
            ChopperTimeoutException('Request timed out after 1 minute'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<GitHubConnectionConfirmationResult>> confirmGitHubConnection(
    String teamId,
    String reference,
    int installationId,
  ) {
    final Uri $url = Uri.parse('/teams/${teamId}/github/confirm');
    final $body = <String, dynamic>{
      'reference': reference,
      'installationId': installationId,
    };
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 60000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<
          GitHubConnectionConfirmationResult,
          GitHubConnectionConfirmationResult
        >($request)
        .catchError(
          (_) => Future<Response<GitHubConnectionConfirmationResult>>.error(
            ChopperTimeoutException('Request timed out after 1 minute'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Map<String, dynamic>>> getTeamMembers(String id) {
    final Uri $url = Uri.parse('/teams/${id}/members');
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 8000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Map<String, dynamic>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<Map<String, dynamic>>>.error(
            ChopperTimeoutException('Request timed out after 8 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<void>> inviteMember(String id, Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/teams/${id}/members');
    final $body = body;
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<void, void>($request)
        .catchError(
          (_) => Future<Response<void>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<List<Map<String, dynamic>>>> fetchOpenCIFiles(
    String teamId,
    String repo,
    String ref, {
    required String owner,
    required int installationId,
  }) {
    final Uri $url = Uri.parse(
      '/teams/${teamId}/repositories/${repo}/openci-files',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'ref': ref,
      'owner': owner,
      'installationId': installationId,
    };
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<List<Map<String, dynamic>>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<List<Map<String, dynamic>>>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<List<UserDevice>>> getDevices() {
    final Uri $url = Uri.parse('/devices');
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<List<UserDevice>, UserDevice>($request)
        .catchError(
          (_) => Future<Response<List<UserDevice>>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Map<String, dynamic>>> seedLocalData(
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/internal/seed');
    final $body = body;
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Map<String, dynamic>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<Map<String, dynamic>>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Map<String, dynamic>>> claimNextWebhookTask() {
    final Uri $url = Uri.parse('/webhooks/claim');
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Map<String, dynamic>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<Map<String, dynamic>>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<ChangedFilesResult>> getWebhookTaskChangedFiles(String id) {
    final Uri $url = Uri.parse('/webhooks/tasks/${id}/changed-files');
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 40000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<ChangedFilesResult, ChangedFilesResult>($request)
        .catchError(
          (_) => Future<Response<ChangedFilesResult>>.error(
            ChopperTimeoutException('Request timed out after 40 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Map<String, dynamic>>> completeWebhookTask(
    String id,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/webhooks/tasks/${id}/complete');
    final $body = body;
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 300000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Map<String, dynamic>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<Map<String, dynamic>>>.error(
            ChopperTimeoutException('Request timed out after 5 minutes'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Map<String, dynamic>>> failWebhookTask(
    String id,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/webhooks/tasks/${id}/fail');
    final $body = body;
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Map<String, dynamic>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<Map<String, dynamic>>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Map<String, dynamic>>> createBuildJob(
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/builds');
    final $body = body;
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Map<String, dynamic>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<Map<String, dynamic>>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Map<String, dynamic>>> claimNextJob(
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/worker/jobs/claim');
    final $body = body;
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Map<String, dynamic>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<Map<String, dynamic>>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Map<String, dynamic>>> startBillingExecution(
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/worker/billing/start');
    final $body = body;
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Map<String, dynamic>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<Map<String, dynamic>>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Map<String, dynamic>>> reportBillingExecution(
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/worker/billing/report');
    final $body = body;
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Map<String, dynamic>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<Map<String, dynamic>>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Map<String, dynamic>>> createRun(
    String buildJobId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/builds/${buildJobId}/runs');
    final $body = body;
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Map<String, dynamic>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<Map<String, dynamic>>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<void>> completeJob(String id, Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/builds/${id}');
    final $body = body;
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<void, void>($request)
        .catchError(
          (_) => Future<Response<void>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<void>> updateRunStatus(
    String buildJobId,
    String runId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/builds/${buildJobId}/runs/${runId}');
    final $body = body;
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<void, void>($request)
        .catchError(
          (_) => Future<Response<void>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Map<String, dynamic>>> getBuildJob(String id) {
    final Uri $url = Uri.parse('/builds/${id}');
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Map<String, dynamic>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<Map<String, dynamic>>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<void>> updateCheckRun(
    String buildJobId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/builds/${buildJobId}/check-run');
    final $body = body;
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<void, void>($request)
        .catchError(
          (_) => Future<Response<void>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<void>> handleBuildJobStatusChange(
    String buildJobId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/builds/${buildJobId}/status-change');
    final $body = body;
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<void, void>($request)
        .catchError(
          (_) => Future<Response<void>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Map<String, dynamic>>> resolveInstallationToken(
    String buildJobId,
  ) {
    final Uri $url = Uri.parse('/builds/${buildJobId}/token');
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Map<String, dynamic>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<Map<String, dynamic>>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<Map<String, dynamic>>> getJobEventPayload(String buildJobId) {
    final Uri $url = Uri.parse('/builds/${buildJobId}/event');
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<Map<String, dynamic>, Map<String, dynamic>>($request)
        .catchError(
          (_) => Future<Response<Map<String, dynamic>>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }

  @override
  Future<Response<List<CicdCommitGroup>>> getCommitGroups(
    String teamId,
    int? limit,
  ) {
    final Uri $url = Uri.parse('/builds/commits');
    final Map<String, dynamic> $params = <String, dynamic>{
      'teamId': teamId,
      'limit': limit,
    };
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<List<CicdCommitGroup>, CicdCommitGroup>($request)
        .catchError(
          (_) => Future<Response<List<CicdCommitGroup>>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }
}
