part of 'logs.dart';

class GetBuildStepWriteStateVariablesBuilder {
  String teamId;
  String runId;
  String stepId;

  final FirebaseDataConnect _dataConnect;
  GetBuildStepWriteStateVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.runId,
    required this.stepId,
  });
  Deserializer<GetBuildStepWriteStateData> dataDeserializer = (dynamic json) =>
      GetBuildStepWriteStateData.fromJson(jsonDecode(json));
  Serializer<GetBuildStepWriteStateVariables> varsSerializer =
      (GetBuildStepWriteStateVariables vars) => jsonEncode(vars.toJson());
  Future<
    QueryResult<GetBuildStepWriteStateData, GetBuildStepWriteStateVariables>
  >
  execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetBuildStepWriteStateData, GetBuildStepWriteStateVariables> ref() {
    GetBuildStepWriteStateVariables vars = GetBuildStepWriteStateVariables(
      teamId: teamId,
      runId: runId,
      stepId: stepId,
    );
    return _dataConnect.query(
      "GetBuildStepWriteState",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBuildStepWriteStateRun {
  final String id;
  final List<GetBuildStepWriteStateRunSteps> steps;
  GetBuildStepWriteStateRun.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      steps = (json['steps'] as List<dynamic>)
          .map((e) => GetBuildStepWriteStateRunSteps.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildStepWriteStateRun otherTyped =
        other as GetBuildStepWriteStateRun;
    return id == otherTyped.id && steps == otherTyped.steps;
  }

  @override
  int get hashCode => Object.hashAll([id.hashCode, steps.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['steps'] = steps.map((e) => e.toJson()).toList();
    return json;
  }

  GetBuildStepWriteStateRun({
    required this.id,
    required this.steps,
  });
}

@immutable
class GetBuildStepWriteStateRunSteps {
  final String stepId;
  final String name;
  final String status;
  final int stepOrder;
  final BigInt durationMs;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  GetBuildStepWriteStateRunSteps.fromJson(dynamic json)
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

    final GetBuildStepWriteStateRunSteps otherTyped =
        other as GetBuildStepWriteStateRunSteps;
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

  GetBuildStepWriteStateRunSteps({
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
class GetBuildStepWriteStateData {
  final GetBuildStepWriteStateRun? run;
  GetBuildStepWriteStateData.fromJson(dynamic json)
    : run = json['run'] == null
          ? null
          : GetBuildStepWriteStateRun.fromJson(json['run']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildStepWriteStateData otherTyped =
        other as GetBuildStepWriteStateData;
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

  GetBuildStepWriteStateData({
    this.run,
  });
}

@immutable
class GetBuildStepWriteStateVariables {
  final String teamId;
  final String runId;
  final String stepId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBuildStepWriteStateVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      runId = nativeFromJson<String>(json['runId']),
      stepId = nativeFromJson<String>(json['stepId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildStepWriteStateVariables otherTyped =
        other as GetBuildStepWriteStateVariables;
    return teamId == otherTyped.teamId &&
        runId == otherTyped.runId &&
        stepId == otherTyped.stepId;
  }

  @override
  int get hashCode =>
      Object.hashAll([teamId.hashCode, runId.hashCode, stepId.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['runId'] = nativeToJson<String>(runId);
    json['stepId'] = nativeToJson<String>(stepId);
    return json;
  }

  GetBuildStepWriteStateVariables({
    required this.teamId,
    required this.runId,
    required this.stepId,
  });
}
