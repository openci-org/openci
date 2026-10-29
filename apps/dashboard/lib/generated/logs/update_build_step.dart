part of 'logs.dart';

class UpdateBuildStepVariablesBuilder {
  String teamId;
  String runId;
  String stepId;
  String status;
  BigInt durationMs;

  final FirebaseDataConnect _dataConnect;
  UpdateBuildStepVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.runId,
    required this.stepId,
    required this.status,
    required this.durationMs,
  });
  Deserializer<UpdateBuildStepData> dataDeserializer = (dynamic json) =>
      UpdateBuildStepData.fromJson(jsonDecode(json));
  Serializer<UpdateBuildStepVariables> varsSerializer =
      (UpdateBuildStepVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateBuildStepData, UpdateBuildStepVariables>>
  execute() {
    return ref().execute();
  }

  MutationRef<UpdateBuildStepData, UpdateBuildStepVariables> ref() {
    UpdateBuildStepVariables vars = UpdateBuildStepVariables(
      teamId: teamId,
      runId: runId,
      stepId: stepId,
      status: status,
      durationMs: durationMs,
    );
    return _dataConnect.mutation(
      "UpdateBuildStep",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class UpdateBuildStepData {
  final int buildStep_updateMany;
  UpdateBuildStepData.fromJson(dynamic json)
    : buildStep_updateMany = nativeFromJson<int>(json['buildStep_updateMany']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateBuildStepData otherTyped = other as UpdateBuildStepData;
    return buildStep_updateMany == otherTyped.buildStep_updateMany;
  }

  @override
  int get hashCode => buildStep_updateMany.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildStep_updateMany'] = nativeToJson<int>(buildStep_updateMany);
    return json;
  }

  UpdateBuildStepData({
    required this.buildStep_updateMany,
  });
}

@immutable
class UpdateBuildStepVariables {
  final String teamId;
  final String runId;
  final String stepId;
  final String status;
  final BigInt durationMs;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  UpdateBuildStepVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      runId = nativeFromJson<String>(json['runId']),
      stepId = nativeFromJson<String>(json['stepId']),
      status = nativeFromJson<String>(json['status']),
      durationMs = bigIntFromJson(json['durationMs']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateBuildStepVariables otherTyped =
        other as UpdateBuildStepVariables;
    return teamId == otherTyped.teamId &&
        runId == otherTyped.runId &&
        stepId == otherTyped.stepId &&
        status == otherTyped.status &&
        durationMs == otherTyped.durationMs;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    runId.hashCode,
    stepId.hashCode,
    status.hashCode,
    durationMs.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['runId'] = nativeToJson<String>(runId);
    json['stepId'] = nativeToJson<String>(stepId);
    json['status'] = nativeToJson<String>(status);
    json['durationMs'] = bigIntToJson(durationMs);
    return json;
  }

  UpdateBuildStepVariables({
    required this.teamId,
    required this.runId,
    required this.stepId,
    required this.status,
    required this.durationMs,
  });
}
