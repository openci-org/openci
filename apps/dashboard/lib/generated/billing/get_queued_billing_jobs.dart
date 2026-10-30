part of 'billing.dart';

class GetQueuedBillingJobsVariablesBuilder {
  Optional<BigInt> _afterCreatedAt = Optional.optional(
    bigIntFromJson,
    bigIntToJson,
  );
  Optional<String> _afterId = Optional.optional(nativeFromJson, nativeToJson);
  Optional<List<String>> _excludedTeamIds = Optional.optional(
    listDeserializer(nativeFromJson),
    listSerializer(nativeToJson),
  );
  Optional<int> _limit = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  GetQueuedBillingJobsVariablesBuilder afterCreatedAt(BigInt t) {
    _afterCreatedAt.value = t;
    return this;
  }

  GetQueuedBillingJobsVariablesBuilder afterId(String t) {
    _afterId.value = t;
    return this;
  }

  GetQueuedBillingJobsVariablesBuilder excludedTeamIds(List<String> t) {
    _excludedTeamIds.value = t;
    return this;
  }

  GetQueuedBillingJobsVariablesBuilder limit(int t) {
    _limit.value = t;
    return this;
  }

  GetQueuedBillingJobsVariablesBuilder(
    this._dataConnect,
  );
  Deserializer<GetQueuedBillingJobsData> dataDeserializer = (dynamic json) =>
      GetQueuedBillingJobsData.fromJson(jsonDecode(json));
  Serializer<GetQueuedBillingJobsVariables> varsSerializer =
      (GetQueuedBillingJobsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetQueuedBillingJobsData, GetQueuedBillingJobsVariables>>
  execute() {
    return ref().execute();
  }

  QueryRef<GetQueuedBillingJobsData, GetQueuedBillingJobsVariables> ref() {
    GetQueuedBillingJobsVariables vars = GetQueuedBillingJobsVariables(
      afterCreatedAt: _afterCreatedAt,
      afterId: _afterId,
      excludedTeamIds: _excludedTeamIds,
      limit: _limit,
    );
    return _dataConnect.query(
      "GetQueuedBillingJobs",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetQueuedBillingJobsJobs {
  final String id;
  final String? teamId;
  final BigInt createdAt;
  GetQueuedBillingJobsJobs.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      teamId = json['teamId'] == null
          ? null
          : nativeFromJson<String>(json['teamId']),
      createdAt = bigIntFromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetQueuedBillingJobsJobs otherTyped =
        other as GetQueuedBillingJobsJobs;
    return id == otherTyped.id &&
        teamId == otherTyped.teamId &&
        createdAt == otherTyped.createdAt;
  }

  @override
  int get hashCode =>
      Object.hashAll([id.hashCode, teamId.hashCode, createdAt.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if (teamId != null) {
      json['teamId'] = nativeToJson<String?>(teamId);
    }
    json['createdAt'] = bigIntToJson(createdAt);
    return json;
  }

  GetQueuedBillingJobsJobs({
    required this.id,
    this.teamId,
    required this.createdAt,
  });
}

@immutable
class GetQueuedBillingJobsData {
  final List<GetQueuedBillingJobsJobs> jobs;
  GetQueuedBillingJobsData.fromJson(dynamic json)
    : jobs = (json['jobs'] as List<dynamic>)
          .map((e) => GetQueuedBillingJobsJobs.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetQueuedBillingJobsData otherTyped =
        other as GetQueuedBillingJobsData;
    return jobs == otherTyped.jobs;
  }

  @override
  int get hashCode => jobs.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['jobs'] = jobs.map((e) => e.toJson()).toList();
    return json;
  }

  GetQueuedBillingJobsData({
    required this.jobs,
  });
}

@immutable
class GetQueuedBillingJobsVariables {
  late final Optional<BigInt> afterCreatedAt;
  late final Optional<String> afterId;
  late final Optional<List<String>> excludedTeamIds;
  late final Optional<int> limit;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetQueuedBillingJobsVariables.fromJson(Map<String, dynamic> json) {
    afterCreatedAt = Optional.optional(bigIntFromJson, bigIntToJson);
    afterCreatedAt.value = json['afterCreatedAt'] == null
        ? null
        : bigIntFromJson(json['afterCreatedAt']);

    afterId = Optional.optional(nativeFromJson, nativeToJson);
    afterId.value = json['afterId'] == null
        ? null
        : nativeFromJson<String>(json['afterId']);

    excludedTeamIds = Optional.optional(
      listDeserializer(nativeFromJson),
      listSerializer(nativeToJson),
    );
    excludedTeamIds.value = json['excludedTeamIds'] == null
        ? null
        : (json['excludedTeamIds'] as List<dynamic>)
              .map((e) => nativeFromJson<String>(e))
              .toList();

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

    final GetQueuedBillingJobsVariables otherTyped =
        other as GetQueuedBillingJobsVariables;
    return afterCreatedAt == otherTyped.afterCreatedAt &&
        afterId == otherTyped.afterId &&
        excludedTeamIds == otherTyped.excludedTeamIds &&
        limit == otherTyped.limit;
  }

  @override
  int get hashCode => Object.hashAll([
    afterCreatedAt.hashCode,
    afterId.hashCode,
    excludedTeamIds.hashCode,
    limit.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (afterCreatedAt.state == OptionalState.set) {
      json['afterCreatedAt'] = afterCreatedAt.toJson();
    }
    if (afterId.state == OptionalState.set) {
      json['afterId'] = afterId.toJson();
    }
    if (excludedTeamIds.state == OptionalState.set) {
      json['excludedTeamIds'] = excludedTeamIds.toJson();
    }
    if (limit.state == OptionalState.set) {
      json['limit'] = limit.toJson();
    }
    return json;
  }

  GetQueuedBillingJobsVariables({
    required this.afterCreatedAt,
    required this.afterId,
    required this.excludedTeamIds,
    required this.limit,
  });
}
