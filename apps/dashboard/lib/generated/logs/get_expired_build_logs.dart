part of 'logs.dart';

class GetExpiredBuildLogsVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  GetExpiredBuildLogsVariablesBuilder(
    this._dataConnect,
  );
  Deserializer<GetExpiredBuildLogsData> dataDeserializer = (dynamic json) =>
      GetExpiredBuildLogsData.fromJson(jsonDecode(json));

  Future<QueryResult<GetExpiredBuildLogsData, void>> execute({
    QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache,
  }) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetExpiredBuildLogsData, void> ref() {
    return _dataConnect.query(
      "GetExpiredBuildLogs",
      dataDeserializer,
      emptySerializer,
      null,
    );
  }
}

@immutable
class GetExpiredBuildLogsRuns {
  final String id;
  final List<GetExpiredBuildLogsRunsExpiredLogs> expiredLogs;
  GetExpiredBuildLogsRuns.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      expiredLogs = (json['expiredLogs'] as List<dynamic>)
          .map((e) => GetExpiredBuildLogsRunsExpiredLogs.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetExpiredBuildLogsRuns otherTyped = other as GetExpiredBuildLogsRuns;
    return id == otherTyped.id && expiredLogs == otherTyped.expiredLogs;
  }

  @override
  int get hashCode => Object.hashAll([id.hashCode, expiredLogs.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['expiredLogs'] = expiredLogs.map((e) => e.toJson()).toList();
    return json;
  }

  GetExpiredBuildLogsRuns({
    required this.id,
    required this.expiredLogs,
  });
}

@immutable
class GetExpiredBuildLogsRunsExpiredLogs {
  final BigInt sequence;
  GetExpiredBuildLogsRunsExpiredLogs.fromJson(dynamic json)
    : sequence = bigIntFromJson(json['sequence']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetExpiredBuildLogsRunsExpiredLogs otherTyped =
        other as GetExpiredBuildLogsRunsExpiredLogs;
    return sequence == otherTyped.sequence;
  }

  @override
  int get hashCode => sequence.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['sequence'] = bigIntToJson(sequence);
    return json;
  }

  GetExpiredBuildLogsRunsExpiredLogs({
    required this.sequence,
  });
}

@immutable
class GetExpiredBuildLogsData {
  final List<GetExpiredBuildLogsRuns> runs;
  GetExpiredBuildLogsData.fromJson(dynamic json)
    : runs = (json['runs'] as List<dynamic>)
          .map((e) => GetExpiredBuildLogsRuns.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetExpiredBuildLogsData otherTyped = other as GetExpiredBuildLogsData;
    return runs == otherTyped.runs;
  }

  @override
  int get hashCode => runs.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['runs'] = runs.map((e) => e.toJson()).toList();
    return json;
  }

  GetExpiredBuildLogsData({
    required this.runs,
  });
}
