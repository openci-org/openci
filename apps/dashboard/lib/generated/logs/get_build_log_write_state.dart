part of 'logs.dart';

class GetBuildLogWriteStateVariablesBuilder {
  String teamId;
  String runId;
  List<String> logIds;

  final FirebaseDataConnect _dataConnect;
  GetBuildLogWriteStateVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.runId,
    required this.logIds,
  });
  Deserializer<GetBuildLogWriteStateData> dataDeserializer = (dynamic json) =>
      GetBuildLogWriteStateData.fromJson(jsonDecode(json));
  Serializer<GetBuildLogWriteStateVariables> varsSerializer =
      (GetBuildLogWriteStateVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetBuildLogWriteStateData, GetBuildLogWriteStateVariables>>
  execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetBuildLogWriteStateData, GetBuildLogWriteStateVariables> ref() {
    GetBuildLogWriteStateVariables vars = GetBuildLogWriteStateVariables(
      teamId: teamId,
      runId: runId,
      logIds: logIds,
    );
    return _dataConnect.query(
      "GetBuildLogWriteState",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBuildLogWriteStateRun {
  final String id;
  final BigInt lastLogSequence;
  final Timestamp? logsExpireAt;
  final List<GetBuildLogWriteStateRunLogs> logs;
  GetBuildLogWriteStateRun.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      lastLogSequence = bigIntFromJson(json['lastLogSequence']),
      logsExpireAt = json['logsExpireAt'] == null
          ? null
          : Timestamp.fromJson(json['logsExpireAt']),
      logs = (json['logs'] as List<dynamic>)
          .map((e) => GetBuildLogWriteStateRunLogs.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildLogWriteStateRun otherTyped =
        other as GetBuildLogWriteStateRun;
    return id == otherTyped.id &&
        lastLogSequence == otherTyped.lastLogSequence &&
        logsExpireAt == otherTyped.logsExpireAt &&
        logs == otherTyped.logs;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    lastLogSequence.hashCode,
    logsExpireAt.hashCode,
    logs.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['lastLogSequence'] = bigIntToJson(lastLogSequence);
    if (logsExpireAt != null) {
      json['logsExpireAt'] = logsExpireAt!.toJson();
    }
    json['logs'] = logs.map((e) => e.toJson()).toList();
    return json;
  }

  GetBuildLogWriteStateRun({
    required this.id,
    required this.lastLogSequence,
    this.logsExpireAt,
    required this.logs,
  });
}

@immutable
class GetBuildLogWriteStateRunLogs {
  final String logId;
  final BigInt sequence;
  final String? stepId;
  final String source;
  final String stream;
  final String message;
  final Timestamp occurredAt;
  final Timestamp createdAt;
  GetBuildLogWriteStateRunLogs.fromJson(dynamic json)
    : logId = nativeFromJson<String>(json['logId']),
      sequence = bigIntFromJson(json['sequence']),
      stepId = json['stepId'] == null
          ? null
          : nativeFromJson<String>(json['stepId']),
      source = nativeFromJson<String>(json['source']),
      stream = nativeFromJson<String>(json['stream']),
      message = nativeFromJson<String>(json['message']),
      occurredAt = Timestamp.fromJson(json['occurredAt']),
      createdAt = Timestamp.fromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildLogWriteStateRunLogs otherTyped =
        other as GetBuildLogWriteStateRunLogs;
    return logId == otherTyped.logId &&
        sequence == otherTyped.sequence &&
        stepId == otherTyped.stepId &&
        source == otherTyped.source &&
        stream == otherTyped.stream &&
        message == otherTyped.message &&
        occurredAt == otherTyped.occurredAt &&
        createdAt == otherTyped.createdAt;
  }

  @override
  int get hashCode => Object.hashAll([
    logId.hashCode,
    sequence.hashCode,
    stepId.hashCode,
    source.hashCode,
    stream.hashCode,
    message.hashCode,
    occurredAt.hashCode,
    createdAt.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['logId'] = nativeToJson<String>(logId);
    json['sequence'] = bigIntToJson(sequence);
    if (stepId != null) {
      json['stepId'] = nativeToJson<String?>(stepId);
    }
    json['source'] = nativeToJson<String>(source);
    json['stream'] = nativeToJson<String>(stream);
    json['message'] = nativeToJson<String>(message);
    json['occurredAt'] = occurredAt.toJson();
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  GetBuildLogWriteStateRunLogs({
    required this.logId,
    required this.sequence,
    this.stepId,
    required this.source,
    required this.stream,
    required this.message,
    required this.occurredAt,
    required this.createdAt,
  });
}

@immutable
class GetBuildLogWriteStateData {
  final GetBuildLogWriteStateRun? run;
  GetBuildLogWriteStateData.fromJson(dynamic json)
    : run = json['run'] == null
          ? null
          : GetBuildLogWriteStateRun.fromJson(json['run']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildLogWriteStateData otherTyped =
        other as GetBuildLogWriteStateData;
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

  GetBuildLogWriteStateData({
    this.run,
  });
}

@immutable
class GetBuildLogWriteStateVariables {
  final String teamId;
  final String runId;
  final List<String> logIds;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBuildLogWriteStateVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      runId = nativeFromJson<String>(json['runId']),
      logIds = (json['logIds'] as List<dynamic>)
          .map((e) => nativeFromJson<String>(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildLogWriteStateVariables otherTyped =
        other as GetBuildLogWriteStateVariables;
    return teamId == otherTyped.teamId &&
        runId == otherTyped.runId &&
        logIds == otherTyped.logIds;
  }

  @override
  int get hashCode =>
      Object.hashAll([teamId.hashCode, runId.hashCode, logIds.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['runId'] = nativeToJson<String>(runId);
    json['logIds'] = logIds.map((e) => nativeToJson<String>(e)).toList();
    return json;
  }

  GetBuildLogWriteStateVariables({
    required this.teamId,
    required this.runId,
    required this.logIds,
  });
}
