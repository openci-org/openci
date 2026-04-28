part of 'default.dart';

class GetBuildJobVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetBuildJobVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<GetBuildJobData> dataDeserializer = (dynamic json)  => GetBuildJobData.fromJson(jsonDecode(json));
  Serializer<GetBuildJobVariables> varsSerializer = (GetBuildJobVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetBuildJobData, GetBuildJobVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetBuildJobData, GetBuildJobVariables> ref() {
    GetBuildJobVariables vars= GetBuildJobVariables(id: id,);
    return _dataConnect.query("GetBuildJob", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetBuildJobBuildJob {
  final String id;
  final EnumValue<BuildJobStatus> status;
  final String owner;
  final String repo;
  final String? teamId;
  final String? workflowId;
  final String? workflowFileName;
  final String? workflowName;
  final String? jobKey;
  final String? workflowRunId;
  final List<String>? needs;
  final AnyValue? resolvedNeeds;
  final BigInt? installationId;
  final Timestamp? tokenExpiresAt;
  final BigInt? checkRunId;
  final String? commitSha;
  final int? pullRequestNumber;
  final String? event;
  final String? action;
  final String? sender;
  final String? repository;
  final String? tagName;
  final String? branch;
  final String? releaseName;
  final String? runsOn;
  final int? runCount;
  final String? latestRunId;
  final String? githubApiBaseUrl;
  final String? githubBaseUrl;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final Timestamp? completedAt;
  final String? failureSummaryStatus;
  final String? failureSummary;
  final String? failureSummaryModel;
  final int? failureSummaryDurationMs;
  GetBuildJobBuildJob.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  status = buildJobStatusDeserializer(json['status']),
  owner = nativeFromJson<String>(json['owner']),
  repo = nativeFromJson<String>(json['repo']),
  teamId = json['teamId'] == null ? null : nativeFromJson<String>(json['teamId']),
  workflowId = json['workflowId'] == null ? null : nativeFromJson<String>(json['workflowId']),
  workflowFileName = json['workflowFileName'] == null ? null : nativeFromJson<String>(json['workflowFileName']),
  workflowName = json['workflowName'] == null ? null : nativeFromJson<String>(json['workflowName']),
  jobKey = json['jobKey'] == null ? null : nativeFromJson<String>(json['jobKey']),
  workflowRunId = json['workflowRunId'] == null ? null : nativeFromJson<String>(json['workflowRunId']),
  needs = json['needs'] == null ? null : (json['needs'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList(),
  resolvedNeeds = json['resolvedNeeds'] == null ? null : AnyValue.fromJson(json['resolvedNeeds']),
  installationId = json['installationId'] == null ? null : bigIntFromJson(json['installationId']),
  tokenExpiresAt = json['tokenExpiresAt'] == null ? null : Timestamp.fromJson(json['tokenExpiresAt']),
  checkRunId = json['checkRunId'] == null ? null : bigIntFromJson(json['checkRunId']),
  commitSha = json['commitSha'] == null ? null : nativeFromJson<String>(json['commitSha']),
  pullRequestNumber = json['pullRequestNumber'] == null ? null : nativeFromJson<int>(json['pullRequestNumber']),
  event = json['event'] == null ? null : nativeFromJson<String>(json['event']),
  action = json['action'] == null ? null : nativeFromJson<String>(json['action']),
  sender = json['sender'] == null ? null : nativeFromJson<String>(json['sender']),
  repository = json['repository'] == null ? null : nativeFromJson<String>(json['repository']),
  tagName = json['tagName'] == null ? null : nativeFromJson<String>(json['tagName']),
  branch = json['branch'] == null ? null : nativeFromJson<String>(json['branch']),
  releaseName = json['releaseName'] == null ? null : nativeFromJson<String>(json['releaseName']),
  runsOn = json['runsOn'] == null ? null : nativeFromJson<String>(json['runsOn']),
  runCount = json['runCount'] == null ? null : nativeFromJson<int>(json['runCount']),
  latestRunId = json['latestRunId'] == null ? null : nativeFromJson<String>(json['latestRunId']),
  githubApiBaseUrl = json['githubApiBaseUrl'] == null ? null : nativeFromJson<String>(json['githubApiBaseUrl']),
  githubBaseUrl = json['githubBaseUrl'] == null ? null : nativeFromJson<String>(json['githubBaseUrl']),
  createdAt = Timestamp.fromJson(json['createdAt']),
  updatedAt = Timestamp.fromJson(json['updatedAt']),
  completedAt = json['completedAt'] == null ? null : Timestamp.fromJson(json['completedAt']),
  failureSummaryStatus = json['failureSummaryStatus'] == null ? null : nativeFromJson<String>(json['failureSummaryStatus']),
  failureSummary = json['failureSummary'] == null ? null : nativeFromJson<String>(json['failureSummary']),
  failureSummaryModel = json['failureSummaryModel'] == null ? null : nativeFromJson<String>(json['failureSummaryModel']),
  failureSummaryDurationMs = json['failureSummaryDurationMs'] == null ? null : nativeFromJson<int>(json['failureSummaryDurationMs']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildJobBuildJob otherTyped = other as GetBuildJobBuildJob;
    return id == otherTyped.id && 
    status == otherTyped.status && 
    owner == otherTyped.owner && 
    repo == otherTyped.repo && 
    teamId == otherTyped.teamId && 
    workflowId == otherTyped.workflowId && 
    workflowFileName == otherTyped.workflowFileName && 
    workflowName == otherTyped.workflowName && 
    jobKey == otherTyped.jobKey && 
    workflowRunId == otherTyped.workflowRunId && 
    needs == otherTyped.needs && 
    resolvedNeeds == otherTyped.resolvedNeeds && 
    installationId == otherTyped.installationId && 
    tokenExpiresAt == otherTyped.tokenExpiresAt && 
    checkRunId == otherTyped.checkRunId && 
    commitSha == otherTyped.commitSha && 
    pullRequestNumber == otherTyped.pullRequestNumber && 
    event == otherTyped.event && 
    action == otherTyped.action && 
    sender == otherTyped.sender && 
    repository == otherTyped.repository && 
    tagName == otherTyped.tagName && 
    branch == otherTyped.branch && 
    releaseName == otherTyped.releaseName && 
    runsOn == otherTyped.runsOn && 
    runCount == otherTyped.runCount && 
    latestRunId == otherTyped.latestRunId && 
    githubApiBaseUrl == otherTyped.githubApiBaseUrl && 
    githubBaseUrl == otherTyped.githubBaseUrl && 
    createdAt == otherTyped.createdAt && 
    updatedAt == otherTyped.updatedAt && 
    completedAt == otherTyped.completedAt && 
    failureSummaryStatus == otherTyped.failureSummaryStatus && 
    failureSummary == otherTyped.failureSummary && 
    failureSummaryModel == otherTyped.failureSummaryModel && 
    failureSummaryDurationMs == otherTyped.failureSummaryDurationMs;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, status.hashCode, owner.hashCode, repo.hashCode, teamId.hashCode, workflowId.hashCode, workflowFileName.hashCode, workflowName.hashCode, jobKey.hashCode, workflowRunId.hashCode, needs.hashCode, resolvedNeeds.hashCode, installationId.hashCode, tokenExpiresAt.hashCode, checkRunId.hashCode, commitSha.hashCode, pullRequestNumber.hashCode, event.hashCode, action.hashCode, sender.hashCode, repository.hashCode, tagName.hashCode, branch.hashCode, releaseName.hashCode, runsOn.hashCode, runCount.hashCode, latestRunId.hashCode, githubApiBaseUrl.hashCode, githubBaseUrl.hashCode, createdAt.hashCode, updatedAt.hashCode, completedAt.hashCode, failureSummaryStatus.hashCode, failureSummary.hashCode, failureSummaryModel.hashCode, failureSummaryDurationMs.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['status'] = 
    buildJobStatusSerializer(status)
    ;
    json['owner'] = nativeToJson<String>(owner);
    json['repo'] = nativeToJson<String>(repo);
    if (teamId != null) {
      json['teamId'] = nativeToJson<String?>(teamId);
    }
    if (workflowId != null) {
      json['workflowId'] = nativeToJson<String?>(workflowId);
    }
    if (workflowFileName != null) {
      json['workflowFileName'] = nativeToJson<String?>(workflowFileName);
    }
    if (workflowName != null) {
      json['workflowName'] = nativeToJson<String?>(workflowName);
    }
    if (jobKey != null) {
      json['jobKey'] = nativeToJson<String?>(jobKey);
    }
    if (workflowRunId != null) {
      json['workflowRunId'] = nativeToJson<String?>(workflowRunId);
    }
    if (needs != null) {
      json['needs'] = needs?.map((e) => nativeToJson<String>(e)).toList();
    }
    if (resolvedNeeds != null) {
      json['resolvedNeeds'] = resolvedNeeds!.toJson();
    }
    if (installationId != null) {
      json['installationId'] = bigIntToJson(installationId);
    }
    if (tokenExpiresAt != null) {
      json['tokenExpiresAt'] = tokenExpiresAt!.toJson();
    }
    if (checkRunId != null) {
      json['checkRunId'] = bigIntToJson(checkRunId);
    }
    if (commitSha != null) {
      json['commitSha'] = nativeToJson<String?>(commitSha);
    }
    if (pullRequestNumber != null) {
      json['pullRequestNumber'] = nativeToJson<int?>(pullRequestNumber);
    }
    if (event != null) {
      json['event'] = nativeToJson<String?>(event);
    }
    if (action != null) {
      json['action'] = nativeToJson<String?>(action);
    }
    if (sender != null) {
      json['sender'] = nativeToJson<String?>(sender);
    }
    if (repository != null) {
      json['repository'] = nativeToJson<String?>(repository);
    }
    if (tagName != null) {
      json['tagName'] = nativeToJson<String?>(tagName);
    }
    if (branch != null) {
      json['branch'] = nativeToJson<String?>(branch);
    }
    if (releaseName != null) {
      json['releaseName'] = nativeToJson<String?>(releaseName);
    }
    if (runsOn != null) {
      json['runsOn'] = nativeToJson<String?>(runsOn);
    }
    if (runCount != null) {
      json['runCount'] = nativeToJson<int?>(runCount);
    }
    if (latestRunId != null) {
      json['latestRunId'] = nativeToJson<String?>(latestRunId);
    }
    if (githubApiBaseUrl != null) {
      json['githubApiBaseUrl'] = nativeToJson<String?>(githubApiBaseUrl);
    }
    if (githubBaseUrl != null) {
      json['githubBaseUrl'] = nativeToJson<String?>(githubBaseUrl);
    }
    json['createdAt'] = createdAt.toJson();
    json['updatedAt'] = updatedAt.toJson();
    if (completedAt != null) {
      json['completedAt'] = completedAt!.toJson();
    }
    if (failureSummaryStatus != null) {
      json['failureSummaryStatus'] = nativeToJson<String?>(failureSummaryStatus);
    }
    if (failureSummary != null) {
      json['failureSummary'] = nativeToJson<String?>(failureSummary);
    }
    if (failureSummaryModel != null) {
      json['failureSummaryModel'] = nativeToJson<String?>(failureSummaryModel);
    }
    if (failureSummaryDurationMs != null) {
      json['failureSummaryDurationMs'] = nativeToJson<int?>(failureSummaryDurationMs);
    }
    return json;
  }

  GetBuildJobBuildJob({
    required this.id,
    required this.status,
    required this.owner,
    required this.repo,
    this.teamId,
    this.workflowId,
    this.workflowFileName,
    this.workflowName,
    this.jobKey,
    this.workflowRunId,
    this.needs,
    this.resolvedNeeds,
    this.installationId,
    this.tokenExpiresAt,
    this.checkRunId,
    this.commitSha,
    this.pullRequestNumber,
    this.event,
    this.action,
    this.sender,
    this.repository,
    this.tagName,
    this.branch,
    this.releaseName,
    this.runsOn,
    this.runCount,
    this.latestRunId,
    this.githubApiBaseUrl,
    this.githubBaseUrl,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.failureSummaryStatus,
    this.failureSummary,
    this.failureSummaryModel,
    this.failureSummaryDurationMs,
  });
}

@immutable
class GetBuildJobData {
  final GetBuildJobBuildJob? buildJob;
  GetBuildJobData.fromJson(dynamic json):
  
  buildJob = json['buildJob'] == null ? null : GetBuildJobBuildJob.fromJson(json['buildJob']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildJobData otherTyped = other as GetBuildJobData;
    return buildJob == otherTyped.buildJob;
    
  }
  @override
  int get hashCode => buildJob.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (buildJob != null) {
      json['buildJob'] = buildJob!.toJson();
    }
    return json;
  }

  GetBuildJobData({
    this.buildJob,
  });
}

@immutable
class GetBuildJobVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetBuildJobVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildJobVariables otherTyped = other as GetBuildJobVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetBuildJobVariables({
    required this.id,
  });
}

