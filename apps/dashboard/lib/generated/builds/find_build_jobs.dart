part of 'builds.dart';

class FindBuildJobsVariablesBuilder {
  String teamId;
  String githubBaseUrl;
  String owner;
  String repo;
  Optional<BigInt> _pullRequestNumber = Optional.optional(
    bigIntFromJson,
    bigIntToJson,
  );
  Optional<String> _commitSha = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _limit = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _offset = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  FindBuildJobsVariablesBuilder pullRequestNumber(BigInt t) {
    _pullRequestNumber.value = t;
    return this;
  }

  FindBuildJobsVariablesBuilder commitSha(String t) {
    _commitSha.value = t;
    return this;
  }

  FindBuildJobsVariablesBuilder limit(int t) {
    _limit.value = t;
    return this;
  }

  FindBuildJobsVariablesBuilder offset(int t) {
    _offset.value = t;
    return this;
  }

  FindBuildJobsVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.githubBaseUrl,
    required this.owner,
    required this.repo,
  });
  Deserializer<FindBuildJobsData> dataDeserializer = (dynamic json) =>
      FindBuildJobsData.fromJson(jsonDecode(json));
  Serializer<FindBuildJobsVariables> varsSerializer =
      (FindBuildJobsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<FindBuildJobsData, FindBuildJobsVariables>> execute({
    QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache,
  }) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<FindBuildJobsData, FindBuildJobsVariables> ref() {
    FindBuildJobsVariables vars = FindBuildJobsVariables(
      teamId: teamId,
      githubBaseUrl: githubBaseUrl,
      owner: owner,
      repo: repo,
      pullRequestNumber: _pullRequestNumber,
      commitSha: _commitSha,
      limit: _limit,
      offset: _offset,
    );
    return _dataConnect.query(
      "FindBuildJobs",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class FindBuildJobsData {
  final List<AnyValue>? jobs;
  FindBuildJobsData.fromJson(dynamic json)
    : jobs = json['jobs'] == null
          ? null
          : (json['jobs'] as List<dynamic>)
                .map((e) => AnyValue.fromJson(e))
                .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final FindBuildJobsData otherTyped = other as FindBuildJobsData;
    return jobs == otherTyped.jobs;
  }

  @override
  int get hashCode => jobs.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (jobs != null) {
      json['jobs'] = jobs?.map((e) => e!.toJson()).toList();
    }
    return json;
  }

  FindBuildJobsData({
    this.jobs,
  });
}

@immutable
class FindBuildJobsVariables {
  final String teamId;
  final String githubBaseUrl;
  final String owner;
  final String repo;
  late final Optional<BigInt> pullRequestNumber;
  late final Optional<String> commitSha;
  late final Optional<int> limit;
  late final Optional<int> offset;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  FindBuildJobsVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      githubBaseUrl = nativeFromJson<String>(json['githubBaseUrl']),
      owner = nativeFromJson<String>(json['owner']),
      repo = nativeFromJson<String>(json['repo']) {
    pullRequestNumber = Optional.optional(bigIntFromJson, bigIntToJson);
    pullRequestNumber.value = json['pullRequestNumber'] == null
        ? null
        : bigIntFromJson(json['pullRequestNumber']);

    commitSha = Optional.optional(nativeFromJson, nativeToJson);
    commitSha.value = json['commitSha'] == null
        ? null
        : nativeFromJson<String>(json['commitSha']);

    limit = Optional.optional(nativeFromJson, nativeToJson);
    limit.value = json['limit'] == null
        ? null
        : nativeFromJson<int>(json['limit']);

    offset = Optional.optional(nativeFromJson, nativeToJson);
    offset.value = json['offset'] == null
        ? null
        : nativeFromJson<int>(json['offset']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final FindBuildJobsVariables otherTyped = other as FindBuildJobsVariables;
    return teamId == otherTyped.teamId &&
        githubBaseUrl == otherTyped.githubBaseUrl &&
        owner == otherTyped.owner &&
        repo == otherTyped.repo &&
        pullRequestNumber == otherTyped.pullRequestNumber &&
        commitSha == otherTyped.commitSha &&
        limit == otherTyped.limit &&
        offset == otherTyped.offset;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    githubBaseUrl.hashCode,
    owner.hashCode,
    repo.hashCode,
    pullRequestNumber.hashCode,
    commitSha.hashCode,
    limit.hashCode,
    offset.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['githubBaseUrl'] = nativeToJson<String>(githubBaseUrl);
    json['owner'] = nativeToJson<String>(owner);
    json['repo'] = nativeToJson<String>(repo);
    if (pullRequestNumber.state == OptionalState.set) {
      json['pullRequestNumber'] = pullRequestNumber.toJson();
    }
    if (commitSha.state == OptionalState.set) {
      json['commitSha'] = commitSha.toJson();
    }
    if (limit.state == OptionalState.set) {
      json['limit'] = limit.toJson();
    }
    if (offset.state == OptionalState.set) {
      json['offset'] = offset.toJson();
    }
    return json;
  }

  FindBuildJobsVariables({
    required this.teamId,
    required this.githubBaseUrl,
    required this.owner,
    required this.repo,
    required this.pullRequestNumber,
    required this.commitSha,
    required this.limit,
    required this.offset,
  });
}
