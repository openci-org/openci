part of 'default.dart';

class UpsertBuildJobFromFirestoreVariablesBuilder {
  String id;
  BuildJobStatus status;
  String owner;
  String repo;
  Optional<String> _teamId = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _workflowId = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _workflowFileName = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _workflowName = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _jobKey = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _workflowRunId = Optional.optional(nativeFromJson, nativeToJson);
  Optional<List<String>> _needs = Optional.optional(listDeserializer(nativeFromJson), listSerializer(nativeToJson));
  Optional<AnyValue> _resolvedNeeds = Optional.optional(AnyValue.fromJson, defaultSerializer);
  Optional<BigInt> _installationId = Optional.optional(bigIntFromJson, bigIntToJson);
  Optional<String> _installationToken = Optional.optional(nativeFromJson, nativeToJson);
  Optional<Timestamp> _tokenExpiresAt = Optional.optional((json) => json['tokenExpiresAt'] = Timestamp.fromJson(json['tokenExpiresAt']), defaultSerializer);
  Optional<BigInt> _checkRunId = Optional.optional(bigIntFromJson, bigIntToJson);
  Optional<String> _commitSha = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _pullRequestNumber = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _event = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _action = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _sender = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _repository = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _tagName = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _branch = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _releaseName = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _runsOn = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _runCount = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _latestRunId = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _retriedFromBuildJobId = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _retriedFromWorkflowRunId = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _githubApiBaseUrl = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _githubBaseUrl = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _failureSummaryStatus = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _failureSummary = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _failureSummaryModel = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _failureSummaryDurationMs = Optional.optional(nativeFromJson, nativeToJson);
  Optional<Timestamp> _completedAt = Optional.optional((json) => json['completedAt'] = Timestamp.fromJson(json['completedAt']), defaultSerializer);

  final FirebaseDataConnect _dataConnect;  UpsertBuildJobFromFirestoreVariablesBuilder teamId(String? t) {
   _teamId.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder workflowId(String? t) {
   _workflowId.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder workflowFileName(String? t) {
   _workflowFileName.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder workflowName(String? t) {
   _workflowName.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder jobKey(String? t) {
   _jobKey.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder workflowRunId(String? t) {
   _workflowRunId.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder needs(List<String>? t) {
   _needs.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder resolvedNeeds(AnyValue? t) {
   _resolvedNeeds.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder installationId(BigInt? t) {
   _installationId.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder installationToken(String? t) {
   _installationToken.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder tokenExpiresAt(Timestamp? t) {
   _tokenExpiresAt.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder checkRunId(BigInt? t) {
   _checkRunId.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder commitSha(String? t) {
   _commitSha.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder pullRequestNumber(int? t) {
   _pullRequestNumber.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder event(String? t) {
   _event.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder action(String? t) {
   _action.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder sender(String? t) {
   _sender.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder repository(String? t) {
   _repository.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder tagName(String? t) {
   _tagName.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder branch(String? t) {
   _branch.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder releaseName(String? t) {
   _releaseName.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder runsOn(String? t) {
   _runsOn.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder runCount(int? t) {
   _runCount.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder latestRunId(String? t) {
   _latestRunId.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder retriedFromBuildJobId(String? t) {
   _retriedFromBuildJobId.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder retriedFromWorkflowRunId(String? t) {
   _retriedFromWorkflowRunId.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder githubApiBaseUrl(String? t) {
   _githubApiBaseUrl.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder githubBaseUrl(String? t) {
   _githubBaseUrl.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder failureSummaryStatus(String? t) {
   _failureSummaryStatus.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder failureSummary(String? t) {
   _failureSummary.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder failureSummaryModel(String? t) {
   _failureSummaryModel.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder failureSummaryDurationMs(int? t) {
   _failureSummaryDurationMs.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder completedAt(Timestamp? t) {
   _completedAt.value = t;
   return this;
  }

  UpsertBuildJobFromFirestoreVariablesBuilder(this._dataConnect, {required  this.id,required  this.status,required  this.owner,required  this.repo,});
  Deserializer<UpsertBuildJobFromFirestoreData> dataDeserializer = (dynamic json)  => UpsertBuildJobFromFirestoreData.fromJson(jsonDecode(json));
  Serializer<UpsertBuildJobFromFirestoreVariables> varsSerializer = (UpsertBuildJobFromFirestoreVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertBuildJobFromFirestoreData, UpsertBuildJobFromFirestoreVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertBuildJobFromFirestoreData, UpsertBuildJobFromFirestoreVariables> ref() {
    UpsertBuildJobFromFirestoreVariables vars= UpsertBuildJobFromFirestoreVariables(id: id,status: status,owner: owner,repo: repo,teamId: _teamId,workflowId: _workflowId,workflowFileName: _workflowFileName,workflowName: _workflowName,jobKey: _jobKey,workflowRunId: _workflowRunId,needs: _needs,resolvedNeeds: _resolvedNeeds,installationId: _installationId,installationToken: _installationToken,tokenExpiresAt: _tokenExpiresAt,checkRunId: _checkRunId,commitSha: _commitSha,pullRequestNumber: _pullRequestNumber,event: _event,action: _action,sender: _sender,repository: _repository,tagName: _tagName,branch: _branch,releaseName: _releaseName,runsOn: _runsOn,runCount: _runCount,latestRunId: _latestRunId,retriedFromBuildJobId: _retriedFromBuildJobId,retriedFromWorkflowRunId: _retriedFromWorkflowRunId,githubApiBaseUrl: _githubApiBaseUrl,githubBaseUrl: _githubBaseUrl,failureSummaryStatus: _failureSummaryStatus,failureSummary: _failureSummary,failureSummaryModel: _failureSummaryModel,failureSummaryDurationMs: _failureSummaryDurationMs,completedAt: _completedAt,);
    return _dataConnect.mutation("UpsertBuildJobFromFirestore", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertBuildJobFromFirestoreBuildJobUpsert {
  final String id;
  UpsertBuildJobFromFirestoreBuildJobUpsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertBuildJobFromFirestoreBuildJobUpsert otherTyped = other as UpsertBuildJobFromFirestoreBuildJobUpsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpsertBuildJobFromFirestoreBuildJobUpsert({
    required this.id,
  });
}

@immutable
class UpsertBuildJobFromFirestoreData {
  final UpsertBuildJobFromFirestoreBuildJobUpsert buildJob_upsert;
  UpsertBuildJobFromFirestoreData.fromJson(dynamic json):
  
  buildJob_upsert = UpsertBuildJobFromFirestoreBuildJobUpsert.fromJson(json['buildJob_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertBuildJobFromFirestoreData otherTyped = other as UpsertBuildJobFromFirestoreData;
    return buildJob_upsert == otherTyped.buildJob_upsert;
    
  }
  @override
  int get hashCode => buildJob_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildJob_upsert'] = buildJob_upsert.toJson();
    return json;
  }

  UpsertBuildJobFromFirestoreData({
    required this.buildJob_upsert,
  });
}

@immutable
class UpsertBuildJobFromFirestoreVariables {
  final String id;
  final BuildJobStatus status;
  final String owner;
  final String repo;
  late final Optional<String>teamId;
  late final Optional<String>workflowId;
  late final Optional<String>workflowFileName;
  late final Optional<String>workflowName;
  late final Optional<String>jobKey;
  late final Optional<String>workflowRunId;
  late final Optional<List<String>>needs;
  late final Optional<AnyValue>resolvedNeeds;
  late final Optional<BigInt>installationId;
  late final Optional<String>installationToken;
  late final Optional<Timestamp>tokenExpiresAt;
  late final Optional<BigInt>checkRunId;
  late final Optional<String>commitSha;
  late final Optional<int>pullRequestNumber;
  late final Optional<String>event;
  late final Optional<String>action;
  late final Optional<String>sender;
  late final Optional<String>repository;
  late final Optional<String>tagName;
  late final Optional<String>branch;
  late final Optional<String>releaseName;
  late final Optional<String>runsOn;
  late final Optional<int>runCount;
  late final Optional<String>latestRunId;
  late final Optional<String>retriedFromBuildJobId;
  late final Optional<String>retriedFromWorkflowRunId;
  late final Optional<String>githubApiBaseUrl;
  late final Optional<String>githubBaseUrl;
  late final Optional<String>failureSummaryStatus;
  late final Optional<String>failureSummary;
  late final Optional<String>failureSummaryModel;
  late final Optional<int>failureSummaryDurationMs;
  late final Optional<Timestamp>completedAt;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertBuildJobFromFirestoreVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  status = BuildJobStatus.values.byName(json['status']),
  owner = nativeFromJson<String>(json['owner']),
  repo = nativeFromJson<String>(json['repo']) {
  
  
  
  
  
  
    teamId = Optional.optional(nativeFromJson, nativeToJson);
    teamId.value = json['teamId'] == null ? null : nativeFromJson<String>(json['teamId']);
  
  
    workflowId = Optional.optional(nativeFromJson, nativeToJson);
    workflowId.value = json['workflowId'] == null ? null : nativeFromJson<String>(json['workflowId']);
  
  
    workflowFileName = Optional.optional(nativeFromJson, nativeToJson);
    workflowFileName.value = json['workflowFileName'] == null ? null : nativeFromJson<String>(json['workflowFileName']);
  
  
    workflowName = Optional.optional(nativeFromJson, nativeToJson);
    workflowName.value = json['workflowName'] == null ? null : nativeFromJson<String>(json['workflowName']);
  
  
    jobKey = Optional.optional(nativeFromJson, nativeToJson);
    jobKey.value = json['jobKey'] == null ? null : nativeFromJson<String>(json['jobKey']);
  
  
    workflowRunId = Optional.optional(nativeFromJson, nativeToJson);
    workflowRunId.value = json['workflowRunId'] == null ? null : nativeFromJson<String>(json['workflowRunId']);
  
  
    needs = Optional.optional(listDeserializer(nativeFromJson), listSerializer(nativeToJson));
    needs.value = json['needs'] == null ? null : (json['needs'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList();
  
  
    resolvedNeeds = Optional.optional(AnyValue.fromJson, defaultSerializer);
    resolvedNeeds.value = json['resolvedNeeds'] == null ? null : AnyValue.fromJson(json['resolvedNeeds']);
  
  
    installationId = Optional.optional(bigIntFromJson, bigIntToJson);
    installationId.value = json['installationId'] == null ? null : bigIntFromJson(json['installationId']);
  
  
    installationToken = Optional.optional(nativeFromJson, nativeToJson);
    installationToken.value = json['installationToken'] == null ? null : nativeFromJson<String>(json['installationToken']);
  
  
    tokenExpiresAt = Optional.optional((json) => json['tokenExpiresAt'] = Timestamp.fromJson(json['tokenExpiresAt']), defaultSerializer);
    tokenExpiresAt.value = json['tokenExpiresAt'] == null ? null : Timestamp.fromJson(json['tokenExpiresAt']);
  
  
    checkRunId = Optional.optional(bigIntFromJson, bigIntToJson);
    checkRunId.value = json['checkRunId'] == null ? null : bigIntFromJson(json['checkRunId']);
  
  
    commitSha = Optional.optional(nativeFromJson, nativeToJson);
    commitSha.value = json['commitSha'] == null ? null : nativeFromJson<String>(json['commitSha']);
  
  
    pullRequestNumber = Optional.optional(nativeFromJson, nativeToJson);
    pullRequestNumber.value = json['pullRequestNumber'] == null ? null : nativeFromJson<int>(json['pullRequestNumber']);
  
  
    event = Optional.optional(nativeFromJson, nativeToJson);
    event.value = json['event'] == null ? null : nativeFromJson<String>(json['event']);
  
  
    action = Optional.optional(nativeFromJson, nativeToJson);
    action.value = json['action'] == null ? null : nativeFromJson<String>(json['action']);
  
  
    sender = Optional.optional(nativeFromJson, nativeToJson);
    sender.value = json['sender'] == null ? null : nativeFromJson<String>(json['sender']);
  
  
    repository = Optional.optional(nativeFromJson, nativeToJson);
    repository.value = json['repository'] == null ? null : nativeFromJson<String>(json['repository']);
  
  
    tagName = Optional.optional(nativeFromJson, nativeToJson);
    tagName.value = json['tagName'] == null ? null : nativeFromJson<String>(json['tagName']);
  
  
    branch = Optional.optional(nativeFromJson, nativeToJson);
    branch.value = json['branch'] == null ? null : nativeFromJson<String>(json['branch']);
  
  
    releaseName = Optional.optional(nativeFromJson, nativeToJson);
    releaseName.value = json['releaseName'] == null ? null : nativeFromJson<String>(json['releaseName']);
  
  
    runsOn = Optional.optional(nativeFromJson, nativeToJson);
    runsOn.value = json['runsOn'] == null ? null : nativeFromJson<String>(json['runsOn']);
  
  
    runCount = Optional.optional(nativeFromJson, nativeToJson);
    runCount.value = json['runCount'] == null ? null : nativeFromJson<int>(json['runCount']);
  
  
    latestRunId = Optional.optional(nativeFromJson, nativeToJson);
    latestRunId.value = json['latestRunId'] == null ? null : nativeFromJson<String>(json['latestRunId']);
  
  
    retriedFromBuildJobId = Optional.optional(nativeFromJson, nativeToJson);
    retriedFromBuildJobId.value = json['retriedFromBuildJobId'] == null ? null : nativeFromJson<String>(json['retriedFromBuildJobId']);
  
  
    retriedFromWorkflowRunId = Optional.optional(nativeFromJson, nativeToJson);
    retriedFromWorkflowRunId.value = json['retriedFromWorkflowRunId'] == null ? null : nativeFromJson<String>(json['retriedFromWorkflowRunId']);
  
  
    githubApiBaseUrl = Optional.optional(nativeFromJson, nativeToJson);
    githubApiBaseUrl.value = json['githubApiBaseUrl'] == null ? null : nativeFromJson<String>(json['githubApiBaseUrl']);
  
  
    githubBaseUrl = Optional.optional(nativeFromJson, nativeToJson);
    githubBaseUrl.value = json['githubBaseUrl'] == null ? null : nativeFromJson<String>(json['githubBaseUrl']);
  
  
    failureSummaryStatus = Optional.optional(nativeFromJson, nativeToJson);
    failureSummaryStatus.value = json['failureSummaryStatus'] == null ? null : nativeFromJson<String>(json['failureSummaryStatus']);
  
  
    failureSummary = Optional.optional(nativeFromJson, nativeToJson);
    failureSummary.value = json['failureSummary'] == null ? null : nativeFromJson<String>(json['failureSummary']);
  
  
    failureSummaryModel = Optional.optional(nativeFromJson, nativeToJson);
    failureSummaryModel.value = json['failureSummaryModel'] == null ? null : nativeFromJson<String>(json['failureSummaryModel']);
  
  
    failureSummaryDurationMs = Optional.optional(nativeFromJson, nativeToJson);
    failureSummaryDurationMs.value = json['failureSummaryDurationMs'] == null ? null : nativeFromJson<int>(json['failureSummaryDurationMs']);
  
  
    completedAt = Optional.optional((json) => json['completedAt'] = Timestamp.fromJson(json['completedAt']), defaultSerializer);
    completedAt.value = json['completedAt'] == null ? null : Timestamp.fromJson(json['completedAt']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertBuildJobFromFirestoreVariables otherTyped = other as UpsertBuildJobFromFirestoreVariables;
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
    retriedFromBuildJobId == otherTyped.retriedFromBuildJobId && 
    retriedFromWorkflowRunId == otherTyped.retriedFromWorkflowRunId && 
    githubApiBaseUrl == otherTyped.githubApiBaseUrl && 
    githubBaseUrl == otherTyped.githubBaseUrl && 
    failureSummaryStatus == otherTyped.failureSummaryStatus && 
    failureSummary == otherTyped.failureSummary && 
    failureSummaryModel == otherTyped.failureSummaryModel && 
    failureSummaryDurationMs == otherTyped.failureSummaryDurationMs && 
    completedAt == otherTyped.completedAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, status.hashCode, owner.hashCode, repo.hashCode, teamId.hashCode, workflowId.hashCode, workflowFileName.hashCode, workflowName.hashCode, jobKey.hashCode, workflowRunId.hashCode, needs.hashCode, resolvedNeeds.hashCode, installationId.hashCode, installationToken.hashCode, tokenExpiresAt.hashCode, checkRunId.hashCode, commitSha.hashCode, pullRequestNumber.hashCode, event.hashCode, action.hashCode, sender.hashCode, repository.hashCode, tagName.hashCode, branch.hashCode, releaseName.hashCode, runsOn.hashCode, runCount.hashCode, latestRunId.hashCode, retriedFromBuildJobId.hashCode, retriedFromWorkflowRunId.hashCode, githubApiBaseUrl.hashCode, githubBaseUrl.hashCode, failureSummaryStatus.hashCode, failureSummary.hashCode, failureSummaryModel.hashCode, failureSummaryDurationMs.hashCode, completedAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['status'] = 
    status.name
    ;
    json['owner'] = nativeToJson<String>(owner);
    json['repo'] = nativeToJson<String>(repo);
    if(teamId.state == OptionalState.set) {
      json['teamId'] = teamId.toJson();
    }
    if(workflowId.state == OptionalState.set) {
      json['workflowId'] = workflowId.toJson();
    }
    if(workflowFileName.state == OptionalState.set) {
      json['workflowFileName'] = workflowFileName.toJson();
    }
    if(workflowName.state == OptionalState.set) {
      json['workflowName'] = workflowName.toJson();
    }
    if(jobKey.state == OptionalState.set) {
      json['jobKey'] = jobKey.toJson();
    }
    if(workflowRunId.state == OptionalState.set) {
      json['workflowRunId'] = workflowRunId.toJson();
    }
    if(needs.state == OptionalState.set) {
      json['needs'] = needs.toJson();
    }
    if(resolvedNeeds.state == OptionalState.set) {
      json['resolvedNeeds'] = resolvedNeeds.toJson();
    }
    if(installationId.state == OptionalState.set) {
      json['installationId'] = installationId.toJson();
    }
    if(installationToken.state == OptionalState.set) {
      json['installationToken'] = installationToken.toJson();
    }
    if(tokenExpiresAt.state == OptionalState.set) {
      json['tokenExpiresAt'] = tokenExpiresAt.toJson();
    }
    if(checkRunId.state == OptionalState.set) {
      json['checkRunId'] = checkRunId.toJson();
    }
    if(commitSha.state == OptionalState.set) {
      json['commitSha'] = commitSha.toJson();
    }
    if(pullRequestNumber.state == OptionalState.set) {
      json['pullRequestNumber'] = pullRequestNumber.toJson();
    }
    if(event.state == OptionalState.set) {
      json['event'] = event.toJson();
    }
    if(action.state == OptionalState.set) {
      json['action'] = action.toJson();
    }
    if(sender.state == OptionalState.set) {
      json['sender'] = sender.toJson();
    }
    if(repository.state == OptionalState.set) {
      json['repository'] = repository.toJson();
    }
    if(tagName.state == OptionalState.set) {
      json['tagName'] = tagName.toJson();
    }
    if(branch.state == OptionalState.set) {
      json['branch'] = branch.toJson();
    }
    if(releaseName.state == OptionalState.set) {
      json['releaseName'] = releaseName.toJson();
    }
    if(runsOn.state == OptionalState.set) {
      json['runsOn'] = runsOn.toJson();
    }
    if(runCount.state == OptionalState.set) {
      json['runCount'] = runCount.toJson();
    }
    if(latestRunId.state == OptionalState.set) {
      json['latestRunId'] = latestRunId.toJson();
    }
    if(retriedFromBuildJobId.state == OptionalState.set) {
      json['retriedFromBuildJobId'] = retriedFromBuildJobId.toJson();
    }
    if(retriedFromWorkflowRunId.state == OptionalState.set) {
      json['retriedFromWorkflowRunId'] = retriedFromWorkflowRunId.toJson();
    }
    if(githubApiBaseUrl.state == OptionalState.set) {
      json['githubApiBaseUrl'] = githubApiBaseUrl.toJson();
    }
    if(githubBaseUrl.state == OptionalState.set) {
      json['githubBaseUrl'] = githubBaseUrl.toJson();
    }
    if(failureSummaryStatus.state == OptionalState.set) {
      json['failureSummaryStatus'] = failureSummaryStatus.toJson();
    }
    if(failureSummary.state == OptionalState.set) {
      json['failureSummary'] = failureSummary.toJson();
    }
    if(failureSummaryModel.state == OptionalState.set) {
      json['failureSummaryModel'] = failureSummaryModel.toJson();
    }
    if(failureSummaryDurationMs.state == OptionalState.set) {
      json['failureSummaryDurationMs'] = failureSummaryDurationMs.toJson();
    }
    if(completedAt.state == OptionalState.set) {
      json['completedAt'] = completedAt.toJson();
    }
    return json;
  }

  UpsertBuildJobFromFirestoreVariables({
    required this.id,
    required this.status,
    required this.owner,
    required this.repo,
    required this.teamId,
    required this.workflowId,
    required this.workflowFileName,
    required this.workflowName,
    required this.jobKey,
    required this.workflowRunId,
    required this.needs,
    required this.resolvedNeeds,
    required this.installationId,
    required this.installationToken,
    required this.tokenExpiresAt,
    required this.checkRunId,
    required this.commitSha,
    required this.pullRequestNumber,
    required this.event,
    required this.action,
    required this.sender,
    required this.repository,
    required this.tagName,
    required this.branch,
    required this.releaseName,
    required this.runsOn,
    required this.runCount,
    required this.latestRunId,
    required this.retriedFromBuildJobId,
    required this.retriedFromWorkflowRunId,
    required this.githubApiBaseUrl,
    required this.githubBaseUrl,
    required this.failureSummaryStatus,
    required this.failureSummary,
    required this.failureSummaryModel,
    required this.failureSummaryDurationMs,
    required this.completedAt,
  });
}

