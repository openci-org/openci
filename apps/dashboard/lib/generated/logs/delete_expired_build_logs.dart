part of 'logs.dart';

class DeleteExpiredBuildLogsVariablesBuilder {
  String runId;
  BigInt throughSequence;

  final FirebaseDataConnect _dataConnect;
  DeleteExpiredBuildLogsVariablesBuilder(
    this._dataConnect, {
    required this.runId,
    required this.throughSequence,
  });
  Deserializer<DeleteExpiredBuildLogsData> dataDeserializer = (dynamic json) =>
      DeleteExpiredBuildLogsData.fromJson(jsonDecode(json));
  Serializer<DeleteExpiredBuildLogsVariables> varsSerializer =
      (DeleteExpiredBuildLogsVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<DeleteExpiredBuildLogsData, DeleteExpiredBuildLogsVariables>
  >
  execute() {
    return ref().execute();
  }

  MutationRef<DeleteExpiredBuildLogsData, DeleteExpiredBuildLogsVariables>
  ref() {
    DeleteExpiredBuildLogsVariables vars = DeleteExpiredBuildLogsVariables(
      runId: runId,
      throughSequence: throughSequence,
    );
    return _dataConnect.mutation(
      "DeleteExpiredBuildLogs",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class DeleteExpiredBuildLogsData {
  final int buildLog_deleteMany;
  DeleteExpiredBuildLogsData.fromJson(dynamic json)
    : buildLog_deleteMany = nativeFromJson<int>(json['buildLog_deleteMany']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteExpiredBuildLogsData otherTyped =
        other as DeleteExpiredBuildLogsData;
    return buildLog_deleteMany == otherTyped.buildLog_deleteMany;
  }

  @override
  int get hashCode => buildLog_deleteMany.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildLog_deleteMany'] = nativeToJson<int>(buildLog_deleteMany);
    return json;
  }

  DeleteExpiredBuildLogsData({
    required this.buildLog_deleteMany,
  });
}

@immutable
class DeleteExpiredBuildLogsVariables {
  final String runId;
  final BigInt throughSequence;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  DeleteExpiredBuildLogsVariables.fromJson(Map<String, dynamic> json)
    : runId = nativeFromJson<String>(json['runId']),
      throughSequence = bigIntFromJson(json['throughSequence']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteExpiredBuildLogsVariables otherTyped =
        other as DeleteExpiredBuildLogsVariables;
    return runId == otherTyped.runId &&
        throughSequence == otherTyped.throughSequence;
  }

  @override
  int get hashCode =>
      Object.hashAll([runId.hashCode, throughSequence.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['runId'] = nativeToJson<String>(runId);
    json['throughSequence'] = bigIntToJson(throughSequence);
    return json;
  }

  DeleteExpiredBuildLogsVariables({
    required this.runId,
    required this.throughSequence,
  });
}
