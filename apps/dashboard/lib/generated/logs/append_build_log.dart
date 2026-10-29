part of 'logs.dart';

class AppendBuildLogVariablesBuilder {
  String teamId;
  String runId;
  Optional<String> _stepId = Optional.optional(nativeFromJson, nativeToJson);
  BigInt expectedLastSequence;
  BigInt sequence;
  String logId;
  String source;
  String stream;
  String message;
  Timestamp occurredAt;

  final FirebaseDataConnect _dataConnect;
  AppendBuildLogVariablesBuilder stepId(String? t) {
    _stepId.value = t;
    return this;
  }

  AppendBuildLogVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.runId,
    required this.expectedLastSequence,
    required this.sequence,
    required this.logId,
    required this.source,
    required this.stream,
    required this.message,
    required this.occurredAt,
  });
  Deserializer<AppendBuildLogData> dataDeserializer = (dynamic json) =>
      AppendBuildLogData.fromJson(jsonDecode(json));
  Serializer<AppendBuildLogVariables> varsSerializer =
      (AppendBuildLogVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<AppendBuildLogData, AppendBuildLogVariables>>
  execute() {
    return ref().execute();
  }

  MutationRef<AppendBuildLogData, AppendBuildLogVariables> ref() {
    AppendBuildLogVariables vars = AppendBuildLogVariables(
      teamId: teamId,
      runId: runId,
      stepId: _stepId,
      expectedLastSequence: expectedLastSequence,
      sequence: sequence,
      logId: logId,
      source: source,
      stream: stream,
      message: message,
      occurredAt: occurredAt,
    );
    return _dataConnect.mutation(
      "AppendBuildLog",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class AppendBuildLogBuildLogInsert {
  final String runId;
  final BigInt sequence;
  AppendBuildLogBuildLogInsert.fromJson(dynamic json)
    : runId = nativeFromJson<String>(json['runId']),
      sequence = bigIntFromJson(json['sequence']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final AppendBuildLogBuildLogInsert otherTyped =
        other as AppendBuildLogBuildLogInsert;
    return runId == otherTyped.runId && sequence == otherTyped.sequence;
  }

  @override
  int get hashCode => Object.hashAll([runId.hashCode, sequence.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['runId'] = nativeToJson<String>(runId);
    json['sequence'] = bigIntToJson(sequence);
    return json;
  }

  AppendBuildLogBuildLogInsert({
    required this.runId,
    required this.sequence,
  });
}

@immutable
class AppendBuildLogData {
  final int buildRun_updateMany;
  final AppendBuildLogBuildLogInsert buildLog_insert;
  AppendBuildLogData.fromJson(dynamic json)
    : buildRun_updateMany = nativeFromJson<int>(json['buildRun_updateMany']),
      buildLog_insert = AppendBuildLogBuildLogInsert.fromJson(
        json['buildLog_insert'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final AppendBuildLogData otherTyped = other as AppendBuildLogData;
    return buildRun_updateMany == otherTyped.buildRun_updateMany &&
        buildLog_insert == otherTyped.buildLog_insert;
  }

  @override
  int get hashCode =>
      Object.hashAll([buildRun_updateMany.hashCode, buildLog_insert.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildRun_updateMany'] = nativeToJson<int>(buildRun_updateMany);
    json['buildLog_insert'] = buildLog_insert.toJson();
    return json;
  }

  AppendBuildLogData({
    required this.buildRun_updateMany,
    required this.buildLog_insert,
  });
}

@immutable
class AppendBuildLogVariables {
  final String teamId;
  final String runId;
  late final Optional<String> stepId;
  final BigInt expectedLastSequence;
  final BigInt sequence;
  final String logId;
  final String source;
  final String stream;
  final String message;
  final Timestamp occurredAt;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  AppendBuildLogVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      runId = nativeFromJson<String>(json['runId']),
      expectedLastSequence = bigIntFromJson(json['expectedLastSequence']),
      sequence = bigIntFromJson(json['sequence']),
      logId = nativeFromJson<String>(json['logId']),
      source = nativeFromJson<String>(json['source']),
      stream = nativeFromJson<String>(json['stream']),
      message = nativeFromJson<String>(json['message']),
      occurredAt = Timestamp.fromJson(json['occurredAt']) {
    stepId = Optional.optional(nativeFromJson, nativeToJson);
    stepId.value = json['stepId'] == null
        ? null
        : nativeFromJson<String>(json['stepId']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final AppendBuildLogVariables otherTyped = other as AppendBuildLogVariables;
    return teamId == otherTyped.teamId &&
        runId == otherTyped.runId &&
        stepId == otherTyped.stepId &&
        expectedLastSequence == otherTyped.expectedLastSequence &&
        sequence == otherTyped.sequence &&
        logId == otherTyped.logId &&
        source == otherTyped.source &&
        stream == otherTyped.stream &&
        message == otherTyped.message &&
        occurredAt == otherTyped.occurredAt;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    runId.hashCode,
    stepId.hashCode,
    expectedLastSequence.hashCode,
    sequence.hashCode,
    logId.hashCode,
    source.hashCode,
    stream.hashCode,
    message.hashCode,
    occurredAt.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['runId'] = nativeToJson<String>(runId);
    if (stepId.state == OptionalState.set) {
      json['stepId'] = stepId.toJson();
    }
    json['expectedLastSequence'] = bigIntToJson(expectedLastSequence);
    json['sequence'] = bigIntToJson(sequence);
    json['logId'] = nativeToJson<String>(logId);
    json['source'] = nativeToJson<String>(source);
    json['stream'] = nativeToJson<String>(stream);
    json['message'] = nativeToJson<String>(message);
    json['occurredAt'] = occurredAt.toJson();
    return json;
  }

  AppendBuildLogVariables({
    required this.teamId,
    required this.runId,
    required this.stepId,
    required this.expectedLastSequence,
    required this.sequence,
    required this.logId,
    required this.source,
    required this.stream,
    required this.message,
    required this.occurredAt,
  });
}
