part of 'logs.dart';

class GetBuildLogsVariablesBuilder {
  String teamId;
  String runId;
  Optional<BigInt> _afterSequence = Optional.optional(
    bigIntFromJson,
    bigIntToJson,
  );
  Optional<int> _limit = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  GetBuildLogsVariablesBuilder afterSequence(BigInt t) {
    _afterSequence.value = t;
    return this;
  }

  GetBuildLogsVariablesBuilder limit(int t) {
    _limit.value = t;
    return this;
  }

  GetBuildLogsVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.runId,
  });
  Deserializer<GetBuildLogsData> dataDeserializer = (dynamic json) =>
      GetBuildLogsData.fromJson(jsonDecode(json));
  Serializer<GetBuildLogsVariables> varsSerializer =
      (GetBuildLogsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetBuildLogsData, GetBuildLogsVariables>> execute({
    QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache,
  }) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetBuildLogsData, GetBuildLogsVariables> ref() {
    GetBuildLogsVariables vars = GetBuildLogsVariables(
      teamId: teamId,
      runId: runId,
      afterSequence: _afterSequence,
      limit: _limit,
    );
    return _dataConnect.query(
      "GetBuildLogs",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBuildLogsRun {
  final String id;
  final BigInt lastLogSequence;
  final Timestamp? logsExpireAt;
  final List<GetBuildLogsRunLogEntries> logEntries;
  GetBuildLogsRun.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      lastLogSequence = bigIntFromJson(json['lastLogSequence']),
      logsExpireAt = json['logsExpireAt'] == null
          ? null
          : Timestamp.fromJson(json['logsExpireAt']),
      logEntries = (json['logEntries'] as List<dynamic>)
          .map((e) => GetBuildLogsRunLogEntries.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildLogsRun otherTyped = other as GetBuildLogsRun;
    return id == otherTyped.id &&
        lastLogSequence == otherTyped.lastLogSequence &&
        logsExpireAt == otherTyped.logsExpireAt &&
        logEntries == otherTyped.logEntries;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    lastLogSequence.hashCode,
    logsExpireAt.hashCode,
    logEntries.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['lastLogSequence'] = bigIntToJson(lastLogSequence);
    if (logsExpireAt != null) {
      json['logsExpireAt'] = logsExpireAt!.toJson();
    }
    json['logEntries'] = logEntries.map((e) => e.toJson()).toList();
    return json;
  }

  GetBuildLogsRun({
    required this.id,
    required this.lastLogSequence,
    this.logsExpireAt,
    required this.logEntries,
  });
}

@immutable
class GetBuildLogsRunLogEntries {
  final String logId;
  final BigInt sequence;
  final String? stepId;
  final String source;
  final String stream;
  final String message;
  final Timestamp occurredAt;
  final Timestamp createdAt;
  GetBuildLogsRunLogEntries.fromJson(dynamic json)
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

    final GetBuildLogsRunLogEntries otherTyped =
        other as GetBuildLogsRunLogEntries;
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

  GetBuildLogsRunLogEntries({
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
class GetBuildLogsData {
  final GetBuildLogsRun? run;
  GetBuildLogsData.fromJson(dynamic json)
    : run = json['run'] == null ? null : GetBuildLogsRun.fromJson(json['run']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBuildLogsData otherTyped = other as GetBuildLogsData;
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

  GetBuildLogsData({
    this.run,
  });
}

@immutable
class GetBuildLogsVariables {
  final String teamId;
  final String runId;
  late final Optional<BigInt> afterSequence;
  late final Optional<int> limit;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBuildLogsVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      runId = nativeFromJson<String>(json['runId']) {
    afterSequence = Optional.optional(bigIntFromJson, bigIntToJson);
    afterSequence.value = json['afterSequence'] == null
        ? null
        : bigIntFromJson(json['afterSequence']);

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

    final GetBuildLogsVariables otherTyped = other as GetBuildLogsVariables;
    return teamId == otherTyped.teamId &&
        runId == otherTyped.runId &&
        afterSequence == otherTyped.afterSequence &&
        limit == otherTyped.limit;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    runId.hashCode,
    afterSequence.hashCode,
    limit.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['runId'] = nativeToJson<String>(runId);
    if (afterSequence.state == OptionalState.set) {
      json['afterSequence'] = afterSequence.toJson();
    }
    if (limit.state == OptionalState.set) {
      json['limit'] = limit.toJson();
    }
    return json;
  }

  GetBuildLogsVariables({
    required this.teamId,
    required this.runId,
    required this.afterSequence,
    required this.limit,
  });
}
