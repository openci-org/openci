part of 'logs.dart';

class GetBuildLogStateVariablesBuilder {
  String teamId;
  String jobId;
  String runId;

  final FirebaseDataConnect _dataConnect;
  GetBuildLogStateVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.jobId,
    required this.runId,
  });
  Deserializer<GetBuildLogStateData> dataDeserializer = (dynamic json) =>
      GetBuildLogStateData.fromJson(jsonDecode(json));
  Serializer<GetBuildLogStateVariables> varsSerializer =
      (GetBuildLogStateVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetBuildLogStateData, GetBuildLogStateVariables>> execute({
    QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache,
  }) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetBuildLogStateData, GetBuildLogStateVariables> ref() {
    GetBuildLogStateVariables vars = GetBuildLogStateVariables(
      teamId: teamId,
      jobId: jobId,
      runId: runId,
    );
    return _dataConnect.query(
      "GetBuildLogState",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBuildLogStateRun {
  final String id;
  final String status;
  final BigInt lastLogSequence;
  final Timestamp? logsExpireAt;
  final List<GetBuildLogStateRunAllSteps> allSteps;
  GetBuildLogStateRun.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      status = nativeFromJson<String>(json['status']),
      lastLogSequence = bigIntFromJson(json['lastLogSequence']),
      logsExpireAt = json['logsExpireAt'] == null
          ? null
          : Timestamp.fromJson(json['logsExpireAt']),
      allSteps = (json['allSteps'] as List<dynamic>)
          .map((e) => GetBuildLogStateRunAllSteps.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildLogStateRun otherTyped = other as GetBuildLogStateRun;
    return id == otherTyped.id &&
        status == otherTyped.status &&
        lastLogSequence == otherTyped.lastLogSequence &&
        logsExpireAt == otherTyped.logsExpireAt &&
        allSteps == otherTyped.allSteps;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    status.hashCode,
    lastLogSequence.hashCode,
    logsExpireAt.hashCode,
    allSteps.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['status'] = nativeToJson<String>(status);
    json['lastLogSequence'] = bigIntToJson(lastLogSequence);
    if (logsExpireAt != null) {
      json['logsExpireAt'] = logsExpireAt!.toJson();
    }
    json['allSteps'] = allSteps.map((e) => e.toJson()).toList();
    return json;
  }

  GetBuildLogStateRun({
    required this.id,
    required this.status,
    required this.lastLogSequence,
    this.logsExpireAt,
    required this.allSteps,
  });
}

@immutable
class GetBuildLogStateRunAllSteps {
  final String stepId;
  final String name;
  final String status;
  final int stepOrder;
  final BigInt durationMs;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  GetBuildLogStateRunAllSteps.fromJson(dynamic json)
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

    final GetBuildLogStateRunAllSteps otherTyped =
        other as GetBuildLogStateRunAllSteps;
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

  GetBuildLogStateRunAllSteps({
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
class GetBuildLogStateData {
  final GetBuildLogStateRun? run;
  GetBuildLogStateData.fromJson(dynamic json)
    : run = json['run'] == null
          ? null
          : GetBuildLogStateRun.fromJson(json['run']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildLogStateData otherTyped = other as GetBuildLogStateData;
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

  GetBuildLogStateData({
    this.run,
  });
}

@immutable
class GetBuildLogStateVariables {
  final String teamId;
  final String jobId;
  final String runId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBuildLogStateVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      jobId = nativeFromJson<String>(json['jobId']),
      runId = nativeFromJson<String>(json['runId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildLogStateVariables otherTyped =
        other as GetBuildLogStateVariables;
    return teamId == otherTyped.teamId &&
        jobId == otherTyped.jobId &&
        runId == otherTyped.runId;
  }

  @override
  int get hashCode =>
      Object.hashAll([teamId.hashCode, jobId.hashCode, runId.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['jobId'] = nativeToJson<String>(jobId);
    json['runId'] = nativeToJson<String>(runId);
    return json;
  }

  GetBuildLogStateVariables({
    required this.teamId,
    required this.jobId,
    required this.runId,
  });
}
