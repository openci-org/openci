part of 'logs.dart';

class GetBuildStepsVariablesBuilder {
  String teamId;
  String runId;
  Optional<int> _offset = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _limit = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  GetBuildStepsVariablesBuilder offset(int t) {
    _offset.value = t;
    return this;
  }

  GetBuildStepsVariablesBuilder limit(int t) {
    _limit.value = t;
    return this;
  }

  GetBuildStepsVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.runId,
  });
  Deserializer<GetBuildStepsData> dataDeserializer = (dynamic json) =>
      GetBuildStepsData.fromJson(jsonDecode(json));
  Serializer<GetBuildStepsVariables> varsSerializer =
      (GetBuildStepsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetBuildStepsData, GetBuildStepsVariables>> execute({
    QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache,
  }) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetBuildStepsData, GetBuildStepsVariables> ref() {
    GetBuildStepsVariables vars = GetBuildStepsVariables(
      teamId: teamId,
      runId: runId,
      offset: _offset,
      limit: _limit,
    );
    return _dataConnect.query(
      "GetBuildSteps",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBuildStepsRun {
  final String id;
  final List<GetBuildStepsRunStepSummaries> stepSummaries;
  GetBuildStepsRun.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      stepSummaries = (json['stepSummaries'] as List<dynamic>)
          .map((e) => GetBuildStepsRunStepSummaries.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildStepsRun otherTyped = other as GetBuildStepsRun;
    return id == otherTyped.id && stepSummaries == otherTyped.stepSummaries;
  }

  @override
  int get hashCode => Object.hashAll([id.hashCode, stepSummaries.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['stepSummaries'] = stepSummaries.map((e) => e.toJson()).toList();
    return json;
  }

  GetBuildStepsRun({
    required this.id,
    required this.stepSummaries,
  });
}

@immutable
class GetBuildStepsRunStepSummaries {
  final String stepId;
  final String name;
  final String status;
  final int stepOrder;
  final BigInt durationMs;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  GetBuildStepsRunStepSummaries.fromJson(dynamic json)
    : stepId = nativeFromJson<String>(json['stepId']),
      name = nativeFromJson<String>(json['name']),
      status = nativeFromJson<String>(json['status']),
      stepOrder = nativeFromJson<int>(json['stepOrder']),
      durationMs = bigIntFromJson(json['durationMs']),
      createdAt = Timestamp.fromJson(json['createdAt']),
      updatedAt = Timestamp.fromJson(json['updatedAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildStepsRunStepSummaries otherTyped =
        other as GetBuildStepsRunStepSummaries;
    return stepId == otherTyped.stepId &&
        name == otherTyped.name &&
        status == otherTyped.status &&
        stepOrder == otherTyped.stepOrder &&
        durationMs == otherTyped.durationMs &&
        createdAt == otherTyped.createdAt &&
        updatedAt == otherTyped.updatedAt;
  }

  @override
  int get hashCode => Object.hashAll([
    stepId.hashCode,
    name.hashCode,
    status.hashCode,
    stepOrder.hashCode,
    durationMs.hashCode,
    createdAt.hashCode,
    updatedAt.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['stepId'] = nativeToJson<String>(stepId);
    json['name'] = nativeToJson<String>(name);
    json['status'] = nativeToJson<String>(status);
    json['stepOrder'] = nativeToJson<int>(stepOrder);
    json['durationMs'] = bigIntToJson(durationMs);
    json['createdAt'] = createdAt.toJson();
    json['updatedAt'] = updatedAt.toJson();
    return json;
  }

  GetBuildStepsRunStepSummaries({
    required this.stepId,
    required this.name,
    required this.status,
    required this.stepOrder,
    required this.durationMs,
    required this.createdAt,
    required this.updatedAt,
  });
}

@immutable
class GetBuildStepsData {
  final GetBuildStepsRun? run;
  GetBuildStepsData.fromJson(dynamic json)
    : run = json['run'] == null ? null : GetBuildStepsRun.fromJson(json['run']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildStepsData otherTyped = other as GetBuildStepsData;
    return run == otherTyped.run;
  }

  @override
  int get hashCode => run.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (run != null) {
      json['run'] = run!.toJson();
    }
    return json;
  }

  GetBuildStepsData({
    this.run,
  });
}

@immutable
class GetBuildStepsVariables {
  final String teamId;
  final String runId;
  late final Optional<int> offset;
  late final Optional<int> limit;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBuildStepsVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      runId = nativeFromJson<String>(json['runId']) {
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

    final GetBuildStepsVariables otherTyped = other as GetBuildStepsVariables;
    return teamId == otherTyped.teamId &&
        runId == otherTyped.runId &&
        offset == otherTyped.offset &&
        limit == otherTyped.limit;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    runId.hashCode,
    offset.hashCode,
    limit.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['runId'] = nativeToJson<String>(runId);
    if (offset.state == OptionalState.set) {
      json['offset'] = offset.toJson();
    }
    if (limit.state == OptionalState.set) {
      json['limit'] = limit.toJson();
    }
    return json;
  }

  GetBuildStepsVariables({
    required this.teamId,
    required this.runId,
    required this.offset,
    required this.limit,
  });
}
