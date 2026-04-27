part of 'default.dart';

class ListBuildJobsByWorkflowRunVariablesBuilder {
  String workflowRunId;

  final FirebaseDataConnect _dataConnect;
  ListBuildJobsByWorkflowRunVariablesBuilder(this._dataConnect, {required  this.workflowRunId,});
  Deserializer<ListBuildJobsByWorkflowRunData> dataDeserializer = (dynamic json)  => ListBuildJobsByWorkflowRunData.fromJson(jsonDecode(json));
  Serializer<ListBuildJobsByWorkflowRunVariables> varsSerializer = (ListBuildJobsByWorkflowRunVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListBuildJobsByWorkflowRunData, ListBuildJobsByWorkflowRunVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListBuildJobsByWorkflowRunData, ListBuildJobsByWorkflowRunVariables> ref() {
    ListBuildJobsByWorkflowRunVariables vars= ListBuildJobsByWorkflowRunVariables(workflowRunId: workflowRunId,);
    return _dataConnect.query("ListBuildJobsByWorkflowRun", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListBuildJobsByWorkflowRunBuildJobs {
  final String id;
  final String status;
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
  final String? installationToken;
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
  ListBuildJobsByWorkflowRunBuildJobs.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  status = nativeFromJson<String>(json['status']),
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
  installationToken = json['installationToken'] == null ? null : nativeFromJson<String>(json['installationToken']),
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
  completedAt = json['completedAt'] == null ? null : Timestamp.fromJson(json['completedAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListBuildJobsByWorkflowRunBuildJobs otherTyped = other as ListBuildJobsByWorkflowRunBuildJobs;
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
    installationToken == otherTyped.installationToken && 
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
    completedAt == otherTyped.completedAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, status.hashCode, owner.hashCode, repo.hashCode, teamId.hashCode, workflowId.hashCode, workflowFileName.hashCode, workflowName.hashCode, jobKey.hashCode, workflowRunId.hashCode, needs.hashCode, resolvedNeeds.hashCode, installationId.hashCode, installationToken.hashCode, tokenExpiresAt.hashCode, checkRunId.hashCode, commitSha.hashCode, pullRequestNumber.hashCode, event.hashCode, action.hashCode, sender.hashCode, repository.hashCode, tagName.hashCode, branch.hashCode, releaseName.hashCode, runsOn.hashCode, runCount.hashCode, latestRunId.hashCode, githubApiBaseUrl.hashCode, githubBaseUrl.hashCode, createdAt.hashCode, updatedAt.hashCode, completedAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['status'] = nativeToJson<String>(status);
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
    if (installationToken != null) {
      json['installationToken'] = nativeToJson<String?>(installationToken);
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
    return json;
  }

  ListBuildJobsByWorkflowRunBuildJobs({
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
    this.installationToken,
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
  });
}

@immutable
class ListBuildJobsByWorkflowRunData {
  final List<ListBuildJobsByWorkflowRunBuildJobs> buildJobs;
  ListBuildJobsByWorkflowRunData.fromJson(dynamic json):
  
  buildJobs = (json['buildJobs'] as List<dynamic>)
        .map((e) => ListBuildJobsByWorkflowRunBuildJobs.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListBuildJobsByWorkflowRunData otherTyped = other as ListBuildJobsByWorkflowRunData;
    return buildJobs == otherTyped.buildJobs;
    
  }
  @override
  int get hashCode => buildJobs.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildJobs'] = buildJobs.map((e) => e.toJson()).toList();
    return json;
  }

  ListBuildJobsByWorkflowRunData({
    required this.buildJobs,
  });
}

@immutable
class ListBuildJobsByWorkflowRunVariables {
  final String workflowRunId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListBuildJobsByWorkflowRunVariables.fromJson(Map<String, dynamic> json):
  
  workflowRunId = nativeFromJson<String>(json['workflowRunId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListBuildJobsByWorkflowRunVariables otherTyped = other as ListBuildJobsByWorkflowRunVariables;
    return workflowRunId == otherTyped.workflowRunId;
    
  }
  @override
  int get hashCode => workflowRunId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['workflowRunId'] = nativeToJson<String>(workflowRunId);
    return json;
  }

  ListBuildJobsByWorkflowRunVariables({
    required this.workflowRunId,
  });
}

