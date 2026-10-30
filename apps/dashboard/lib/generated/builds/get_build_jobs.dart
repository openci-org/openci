part of 'builds.dart';

class GetBuildJobsVariablesBuilder {
  String teamId;
  Optional<int> _offset = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _limit = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  GetBuildJobsVariablesBuilder offset(int t) {
    _offset.value = t;
    return this;
  }

  GetBuildJobsVariablesBuilder limit(int t) {
    _limit.value = t;
    return this;
  }

  GetBuildJobsVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
  });
  Deserializer<GetBuildJobsData> dataDeserializer = (dynamic json) =>
      GetBuildJobsData.fromJson(jsonDecode(json));
  Serializer<GetBuildJobsVariables> varsSerializer =
      (GetBuildJobsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetBuildJobsData, GetBuildJobsVariables>> execute({
    QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache,
  }) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetBuildJobsData, GetBuildJobsVariables> ref() {
    GetBuildJobsVariables vars = GetBuildJobsVariables(
      teamId: teamId,
      offset: _offset,
      limit: _limit,
    );
    return _dataConnect.query(
      "GetBuildJobs",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBuildJobsBuildJobs {
  final String? teamId;
  final String id;
  final String status;
  final String owner;
  final String repo;
  final String? workflowId;
  final String workflowName;
  final String workflowFileName;
  final String? commitSha;
  final String? commitMessage;
  final BigInt? pullRequestNumber;
  final String? branch;
  final String? tagName;
  final String? jobKey;
  final String? workflowJobKey;
  final String? workflowRunId;
  final String? matrix;
  final String? matrixLabel;
  final String? needs;
  final String? runsOn;
  final BigInt? runCount;
  final String? latestRunId;
  final BigInt createdAt;
  final BigInt updatedAt;
  final BigInt? completedAt;
  final String? githubBaseUrl;
  final String? failureSummary;
  final String? failureSummaryStatus;
  GetBuildJobsBuildJobs.fromJson(dynamic json)
    : teamId = json['teamId'] == null
          ? null
          : nativeFromJson<String>(json['teamId']),
      id = nativeFromJson<String>(json['id']),
      status = nativeFromJson<String>(json['status']),
      owner = nativeFromJson<String>(json['owner']),
      repo = nativeFromJson<String>(json['repo']),
      workflowId = json['workflowId'] == null
          ? null
          : nativeFromJson<String>(json['workflowId']),
      workflowName = nativeFromJson<String>(json['workflowName']),
      workflowFileName = nativeFromJson<String>(json['workflowFileName']),
      commitSha = json['commitSha'] == null
          ? null
          : nativeFromJson<String>(json['commitSha']),
      commitMessage = json['commitMessage'] == null
          ? null
          : nativeFromJson<String>(json['commitMessage']),
      pullRequestNumber = json['pullRequestNumber'] == null
          ? null
          : bigIntFromJson(json['pullRequestNumber']),
      branch = json['branch'] == null
          ? null
          : nativeFromJson<String>(json['branch']),
      tagName = json['tagName'] == null
          ? null
          : nativeFromJson<String>(json['tagName']),
      jobKey = json['jobKey'] == null
          ? null
          : nativeFromJson<String>(json['jobKey']),
      workflowJobKey = json['workflowJobKey'] == null
          ? null
          : nativeFromJson<String>(json['workflowJobKey']),
      workflowRunId = json['workflowRunId'] == null
          ? null
          : nativeFromJson<String>(json['workflowRunId']),
      matrix = json['matrix'] == null
          ? null
          : nativeFromJson<String>(json['matrix']),
      matrixLabel = json['matrixLabel'] == null
          ? null
          : nativeFromJson<String>(json['matrixLabel']),
      needs = json['needs'] == null
          ? null
          : nativeFromJson<String>(json['needs']),
      runsOn = json['runsOn'] == null
          ? null
          : nativeFromJson<String>(json['runsOn']),
      runCount = json['runCount'] == null
          ? null
          : bigIntFromJson(json['runCount']),
      latestRunId = json['latestRunId'] == null
          ? null
          : nativeFromJson<String>(json['latestRunId']),
      createdAt = bigIntFromJson(json['createdAt']),
      updatedAt = bigIntFromJson(json['updatedAt']),
      completedAt = json['completedAt'] == null
          ? null
          : bigIntFromJson(json['completedAt']),
      githubBaseUrl = json['githubBaseUrl'] == null
          ? null
          : nativeFromJson<String>(json['githubBaseUrl']),
      failureSummary = json['failureSummary'] == null
          ? null
          : nativeFromJson<String>(json['failureSummary']),
      failureSummaryStatus = json['failureSummaryStatus'] == null
          ? null
          : nativeFromJson<String>(json['failureSummaryStatus']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildJobsBuildJobs otherTyped = other as GetBuildJobsBuildJobs;
    return teamId == otherTyped.teamId &&
        id == otherTyped.id &&
        status == otherTyped.status &&
        owner == otherTyped.owner &&
        repo == otherTyped.repo &&
        workflowId == otherTyped.workflowId &&
        workflowName == otherTyped.workflowName &&
        workflowFileName == otherTyped.workflowFileName &&
        commitSha == otherTyped.commitSha &&
        commitMessage == otherTyped.commitMessage &&
        pullRequestNumber == otherTyped.pullRequestNumber &&
        branch == otherTyped.branch &&
        tagName == otherTyped.tagName &&
        jobKey == otherTyped.jobKey &&
        workflowJobKey == otherTyped.workflowJobKey &&
        workflowRunId == otherTyped.workflowRunId &&
        matrix == otherTyped.matrix &&
        matrixLabel == otherTyped.matrixLabel &&
        needs == otherTyped.needs &&
        runsOn == otherTyped.runsOn &&
        runCount == otherTyped.runCount &&
        latestRunId == otherTyped.latestRunId &&
        createdAt == otherTyped.createdAt &&
        updatedAt == otherTyped.updatedAt &&
        completedAt == otherTyped.completedAt &&
        githubBaseUrl == otherTyped.githubBaseUrl &&
        failureSummary == otherTyped.failureSummary &&
        failureSummaryStatus == otherTyped.failureSummaryStatus;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    id.hashCode,
    status.hashCode,
    owner.hashCode,
    repo.hashCode,
    workflowId.hashCode,
    workflowName.hashCode,
    workflowFileName.hashCode,
    commitSha.hashCode,
    commitMessage.hashCode,
    pullRequestNumber.hashCode,
    branch.hashCode,
    tagName.hashCode,
    jobKey.hashCode,
    workflowJobKey.hashCode,
    workflowRunId.hashCode,
    matrix.hashCode,
    matrixLabel.hashCode,
    needs.hashCode,
    runsOn.hashCode,
    runCount.hashCode,
    latestRunId.hashCode,
    createdAt.hashCode,
    updatedAt.hashCode,
    completedAt.hashCode,
    githubBaseUrl.hashCode,
    failureSummary.hashCode,
    failureSummaryStatus.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (teamId != null) {
      json['teamId'] = nativeToJson<String?>(teamId);
    }
    json['id'] = nativeToJson<String>(id);
    json['status'] = nativeToJson<String>(status);
    json['owner'] = nativeToJson<String>(owner);
    json['repo'] = nativeToJson<String>(repo);
    if (workflowId != null) {
      json['workflowId'] = nativeToJson<String?>(workflowId);
    }
    json['workflowName'] = nativeToJson<String>(workflowName);
    json['workflowFileName'] = nativeToJson<String>(workflowFileName);
    if (commitSha != null) {
      json['commitSha'] = nativeToJson<String?>(commitSha);
    }
    if (commitMessage != null) {
      json['commitMessage'] = nativeToJson<String?>(commitMessage);
    }
    if (pullRequestNumber != null) {
      json['pullRequestNumber'] = bigIntToJson(pullRequestNumber);
    }
    if (branch != null) {
      json['branch'] = nativeToJson<String?>(branch);
    }
    if (tagName != null) {
      json['tagName'] = nativeToJson<String?>(tagName);
    }
    if (jobKey != null) {
      json['jobKey'] = nativeToJson<String?>(jobKey);
    }
    if (workflowJobKey != null) {
      json['workflowJobKey'] = nativeToJson<String?>(workflowJobKey);
    }
    if (workflowRunId != null) {
      json['workflowRunId'] = nativeToJson<String?>(workflowRunId);
    }
    if (matrix != null) {
      json['matrix'] = nativeToJson<String?>(matrix);
    }
    if (matrixLabel != null) {
      json['matrixLabel'] = nativeToJson<String?>(matrixLabel);
    }
    if (needs != null) {
      json['needs'] = nativeToJson<String?>(needs);
    }
    if (runsOn != null) {
      json['runsOn'] = nativeToJson<String?>(runsOn);
    }
    if (runCount != null) {
      json['runCount'] = bigIntToJson(runCount);
    }
    if (latestRunId != null) {
      json['latestRunId'] = nativeToJson<String?>(latestRunId);
    }
    json['createdAt'] = bigIntToJson(createdAt);
    json['updatedAt'] = bigIntToJson(updatedAt);
    if (completedAt != null) {
      json['completedAt'] = bigIntToJson(completedAt);
    }
    if (githubBaseUrl != null) {
      json['githubBaseUrl'] = nativeToJson<String?>(githubBaseUrl);
    }
    if (failureSummary != null) {
      json['failureSummary'] = nativeToJson<String?>(failureSummary);
    }
    if (failureSummaryStatus != null) {
      json['failureSummaryStatus'] = nativeToJson<String?>(
        failureSummaryStatus,
      );
    }
    return json;
  }

  GetBuildJobsBuildJobs({
    this.teamId,
    required this.id,
    required this.status,
    required this.owner,
    required this.repo,
    this.workflowId,
    required this.workflowName,
    required this.workflowFileName,
    this.commitSha,
    this.commitMessage,
    this.pullRequestNumber,
    this.branch,
    this.tagName,
    this.jobKey,
    this.workflowJobKey,
    this.workflowRunId,
    this.matrix,
    this.matrixLabel,
    this.needs,
    this.runsOn,
    this.runCount,
    this.latestRunId,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.githubBaseUrl,
    this.failureSummary,
    this.failureSummaryStatus,
  });
}

@immutable
class GetBuildJobsData {
  final List<GetBuildJobsBuildJobs> buildJobs;
  GetBuildJobsData.fromJson(dynamic json)
    : buildJobs = (json['buildJobs'] as List<dynamic>)
          .map((e) => GetBuildJobsBuildJobs.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildJobsData otherTyped = other as GetBuildJobsData;
    return buildJobs == otherTyped.buildJobs;
  }

  @override
  int get hashCode => buildJobs.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildJobs'] = buildJobs.map((e) => e.toJson()).toList();
    return json;
  }

  GetBuildJobsData({
    required this.buildJobs,
  });
}

@immutable
class GetBuildJobsVariables {
  final String teamId;
  late final Optional<int> offset;
  late final Optional<int> limit;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBuildJobsVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']) {
    offset = Optional.optional(nativeFromJson, nativeToJson);
    offset.value = json['offset'] == null
        ? null
        : nativeFromJson<int>(json['offset']);

    limit = Optional.optional(nativeFromJson, nativeToJson);
    limit.value = json['limit'] == null
        ? null
        : nativeFromJson<int>(json['limit']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildJobsVariables otherTyped = other as GetBuildJobsVariables;
    return teamId == otherTyped.teamId &&
        offset == otherTyped.offset &&
        limit == otherTyped.limit;
  }

  @override
  int get hashCode =>
      Object.hashAll([teamId.hashCode, offset.hashCode, limit.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    if (offset.state == OptionalState.set) {
      json['offset'] = offset.toJson();
    }
    if (limit.state == OptionalState.set) {
      json['limit'] = limit.toJson();
    }
    return json;
  }

  GetBuildJobsVariables({
    required this.teamId,
    required this.offset,
    required this.limit,
  });
}
