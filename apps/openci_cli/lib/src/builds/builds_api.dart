import '../dataconnect/data_connect_api.dart';

class BuildJobSummary {
  const BuildJobSummary({
    required this.id,
    required this.status,
    required this.owner,
    required this.repo,
    required this.workflowName,
    required this.workflowFileName,
    required this.retryCount,
    required this.createdAt,
    required this.updatedAt,
    this.teamId,
    this.workflowId,
    this.commitSha,
    this.commitMessage,
    this.pullRequestNumber,
    this.branch,
    this.tagName,
    this.jobKey,
    this.workflowJobKey,
    this.workflowRunId,
    this.matrixLabel,
    this.runsOn,
    this.runCount,
    this.latestRunId,
    this.completedAt,
    this.githubBaseUrl,
    this.failureSummary,
    this.failureSummaryStatus,
  });

  factory BuildJobSummary.fromJson(Map<String, dynamic> json) =>
      BuildJobSummary(
        id: json['id'] as String,
        teamId: json['teamId'] as String?,
        status: json['status'] as String,
        owner: json['owner'] as String,
        repo: json['repo'] as String,
        workflowId: json['workflowId'] as String?,
        workflowName: json['workflowName'] as String,
        workflowFileName: json['workflowFileName'] as String,
        commitSha: json['commitSha'] as String?,
        commitMessage: json['commitMessage'] as String?,
        pullRequestNumber: _parseNullableInt(json['pullRequestNumber']),
        branch: json['branch'] as String?,
        tagName: json['tagName'] as String?,
        jobKey: json['jobKey'] as String?,
        workflowJobKey: json['workflowJobKey'] as String?,
        workflowRunId: json['workflowRunId'] as String?,
        matrixLabel: json['matrixLabel'] as String?,
        runsOn: json['runsOn'] as String?,
        runCount: _parseNullableInt(json['runCount']),
        retryCount: _parseNullableInt(json['retryCount']) ?? 0,
        latestRunId: json['latestRunId'] as String?,
        createdAt: _parseUnixSecondsToIso(json['createdAt'])!,
        updatedAt: _parseUnixSecondsToIso(json['updatedAt'])!,
        completedAt: _parseUnixSecondsToIso(json['completedAt']),
        githubBaseUrl: json['githubBaseUrl'] as String?,
        failureSummary: json['failureSummary'] as String?,
        failureSummaryStatus: json['failureSummaryStatus'] as String?,
      );

  final String id;
  final String? teamId;
  final String status;
  final String owner;
  final String repo;
  final String? workflowId;
  final String workflowName;
  final String workflowFileName;
  final String? commitSha;
  final String? commitMessage;
  final int? pullRequestNumber;
  final String? branch;
  final String? tagName;
  final String? jobKey;
  final String? workflowJobKey;
  final String? workflowRunId;
  final String? matrixLabel;
  final String? runsOn;
  final int? runCount;
  final int retryCount;
  final String? latestRunId;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;
  final String? githubBaseUrl;
  final String? failureSummary;
  final String? failureSummaryStatus;

  Map<String, Object?> toJson() => {
    'id': id,
    if (teamId != null) 'teamId': teamId,
    'status': status,
    'owner': owner,
    'repo': repo,
    if (workflowId != null) 'workflowId': workflowId,
    'workflowName': workflowName,
    'workflowFileName': workflowFileName,
    if (commitSha != null) 'commitSha': commitSha,
    if (commitMessage != null) 'commitMessage': commitMessage,
    if (pullRequestNumber != null) 'pullRequestNumber': pullRequestNumber,
    if (branch != null) 'branch': branch,
    if (tagName != null) 'tagName': tagName,
    if (jobKey != null) 'jobKey': jobKey,
    if (workflowJobKey != null) 'workflowJobKey': workflowJobKey,
    if (workflowRunId != null) 'workflowRunId': workflowRunId,
    if (matrixLabel != null) 'matrixLabel': matrixLabel,
    if (runsOn != null) 'runsOn': runsOn,
    if (runCount != null) 'runCount': runCount,
    'retryCount': retryCount,
    if (latestRunId != null) 'latestRunId': latestRunId,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    if (completedAt != null) 'completedAt': completedAt,
    if (githubBaseUrl != null) 'githubBaseUrl': githubBaseUrl,
    if (failureSummary != null) 'failureSummary': failureSummary,
    if (failureSummaryStatus != null)
      'failureSummaryStatus': failureSummaryStatus,
  };
}

class BuildStepSummary {
  const BuildStepSummary({
    required this.stepId,
    required this.name,
    required this.status,
    required this.stepOrder,
    required this.durationMs,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BuildStepSummary.fromJson(Map<String, dynamic> json) =>
      BuildStepSummary(
        stepId: json['stepId'] as String,
        name: json['name'] as String,
        status: json['status'] as String,
        stepOrder: _parseInt(json['stepOrder']),
        durationMs: _parseInt(json['durationMs']),
        createdAt: json['createdAt'] as String,
        updatedAt: json['updatedAt'] as String,
      );

  final String stepId;
  final String name;
  final String status;
  final int stepOrder;
  final int durationMs;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toJson() => {
    'stepId': stepId,
    'name': name,
    'status': status,
    'stepOrder': stepOrder,
    'durationMs': durationMs,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}

class BuildLogStateSummary {
  const BuildLogStateSummary({
    required this.runId,
    required this.status,
    required this.lastLogSequence,
    required this.expired,
    required this.steps,
    this.logsExpireAt,
  });

  factory BuildLogStateSummary.fromJson(
    Map<String, dynamic> json, {
    DateTime? now,
  }) {
    final expireAt = json['logsExpireAt'] as String?;
    final parsedExpireAt = expireAt == null
        ? null
        : DateTime.tryParse(expireAt);
    final referenceNow = (now ?? DateTime.now()).toUtc();
    return BuildLogStateSummary(
      runId: json['id'] as String,
      status: json['status'] as String,
      lastLogSequence: _parseInt(json['lastLogSequence']),
      logsExpireAt: expireAt,
      expired: parsedExpireAt != null && parsedExpireAt.isBefore(referenceNow),
      steps: (json['allSteps'] as List<dynamic>? ?? const [])
          .map(
            (item) => BuildStepSummary.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final String runId;
  final String status;
  final int lastLogSequence;
  final String? logsExpireAt;
  final bool expired;
  final List<BuildStepSummary> steps;

  Map<String, Object?> toJson() => {
    'runId': runId,
    'status': status,
    'lastLogSequence': lastLogSequence,
    if (logsExpireAt != null) 'logsExpireAt': logsExpireAt,
    'expired': expired,
    'steps': steps.map((step) => step.toJson()).toList(),
  };
}

class BuildLogEntry {
  const BuildLogEntry({
    required this.logId,
    required this.sequence,
    required this.source,
    required this.stream,
    required this.message,
    required this.occurredAt,
    required this.createdAt,
    this.stepId,
  });

  factory BuildLogEntry.fromJson(Map<String, dynamic> json) => BuildLogEntry(
    logId: json['logId'] as String,
    sequence: _parseInt(json['sequence']),
    stepId: json['stepId'] as String?,
    source: json['source'] as String,
    stream: json['stream'] as String,
    message: json['message'] as String,
    occurredAt: json['occurredAt'] as String,
    createdAt: json['createdAt'] as String,
  );

  final String logId;
  final int sequence;
  final String? stepId;
  final String source;
  final String stream;
  final String message;
  final String occurredAt;
  final String createdAt;
}

class BuildLogsPage {
  const BuildLogsPage({
    required this.runId,
    required this.lastLogSequence,
    required this.expired,
    required this.entries,
    this.logsExpireAt,
  });

  factory BuildLogsPage.fromJson(Map<String, dynamic> json, {DateTime? now}) {
    final expireAt = json['logsExpireAt'] as String?;
    final parsedExpireAt = expireAt == null
        ? null
        : DateTime.tryParse(expireAt);
    final referenceNow = (now ?? DateTime.now()).toUtc();
    return BuildLogsPage(
      runId: json['id'] as String,
      lastLogSequence: _parseInt(json['lastLogSequence']),
      logsExpireAt: expireAt,
      expired: parsedExpireAt != null && parsedExpireAt.isBefore(referenceNow),
      entries: (json['logEntries'] as List<dynamic>? ?? const [])
          .map((item) => BuildLogEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String runId;
  final int lastLogSequence;
  final String? logsExpireAt;
  final bool expired;
  final List<BuildLogEntry> entries;
}

class BuildsApi {
  BuildsApi(this._dataConnect, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const int maxPageSize = 200;

  final DataConnectApi _dataConnect;
  final DateTime Function() _now;

  Future<List<BuildJobSummary>> listBuildJobs({
    required String teamId,
    int offset = 0,
    int limit = 100,
  }) async {
    final data = await _dataConnect.executeQuery(
      connector: 'builds',
      operationName: 'GetBuildJobs',
      variables: {
        'teamId': teamId,
        'offset': offset,
        'limit': limit.clamp(1, maxPageSize),
      },
    );
    final jobs = data['buildJobs'];
    if (jobs is! List<dynamic>) {
      throw const FormatException('Invalid buildJobs response');
    }
    return jobs
        .map((item) => BuildJobSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BuildJobSummary?> getBuildJob(String id) async {
    final data = await _dataConnect.executeQuery(
      connector: 'builds',
      operationName: 'GetBuildJob',
      variables: {'id': id},
    );
    final job = data['job'];
    if (job == null) return null;
    if (job is! Map<String, dynamic>) {
      throw const FormatException('Invalid build job response');
    }
    return BuildJobSummary.fromJson(job);
  }

  Future<BuildLogStateSummary> getBuildLogState({
    required String teamId,
    required String jobId,
    required String runId,
  }) async {
    final data = await _dataConnect.executeQuery(
      connector: 'logs',
      operationName: 'GetBuildLogState',
      variables: {'teamId': teamId, 'jobId': jobId, 'runId': runId},
    );
    final run = data['run'];
    if (run is! Map<String, dynamic>) {
      throw const FormatException('Invalid build log state response');
    }
    return BuildLogStateSummary.fromJson(run, now: _now());
  }

  Future<BuildLogsPage> getBuildLogs({
    required String teamId,
    required String runId,
    int afterSequence = 0,
    int limit = maxPageSize,
  }) async {
    final data = await _dataConnect.executeQuery(
      connector: 'logs',
      operationName: 'GetBuildLogs',
      variables: {
        'teamId': teamId,
        'runId': runId,
        'afterSequence': afterSequence.toString(),
        'limit': limit.clamp(1, maxPageSize),
      },
    );
    final run = data['run'];
    if (run is! Map<String, dynamic>) {
      throw const FormatException('Invalid build logs response');
    }
    return BuildLogsPage.fromJson(run, now: _now());
  }

  void dispose() => _dataConnect.dispose();
}

int _parseInt(Object? value) {
  final parsed = _parseNullableInt(value);
  if (parsed == null) {
    throw FormatException('Expected integer value, got $value');
  }
  return parsed;
}

int? _parseNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.parse(value);
  throw FormatException('Expected integer value, got $value');
}

String? _parseUnixSecondsToIso(Object? value) {
  if (value == null) return null;
  if (value is String && value.contains('T')) return value;
  final seconds = _parseInt(value);
  return DateTime.fromMillisecondsSinceEpoch(
    seconds * 1000,
    isUtc: true,
  ).toIso8601String();
}
