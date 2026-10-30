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
