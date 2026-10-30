part of 'logs.dart';

class CreateBuildStepVariablesBuilder {
  String teamId;
  String runId;
  String stepId;
  String name;
  int stepOrder;

  final FirebaseDataConnect _dataConnect;
  CreateBuildStepVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.runId,
    required this.stepId,
    required this.name,
    required this.stepOrder,
  });
  Deserializer<CreateBuildStepData> dataDeserializer = (dynamic json) =>
      CreateBuildStepData.fromJson(jsonDecode(json));
  Serializer<CreateBuildStepVariables> varsSerializer =
      (CreateBuildStepVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateBuildStepData, CreateBuildStepVariables>>
  execute() {
    return ref().execute();
  }

  MutationRef<CreateBuildStepData, CreateBuildStepVariables> ref() {
    CreateBuildStepVariables vars = CreateBuildStepVariables(
      teamId: teamId,
      runId: runId,
      stepId: stepId,
      name: name,
      stepOrder: stepOrder,
    );
    return _dataConnect.mutation(
      "CreateBuildStep",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class CreateBuildStepBuildStepInsert {
  final String runId;
  final String stepId;
  CreateBuildStepBuildStepInsert.fromJson(dynamic json)
    : runId = nativeFromJson<String>(json['runId']),
      stepId = nativeFromJson<String>(json['stepId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBuildStepBuildStepInsert otherTyped =
        other as CreateBuildStepBuildStepInsert;
    return runId == otherTyped.runId && stepId == otherTyped.stepId;
  }

  @override
  int get hashCode => Object.hashAll([runId.hashCode, stepId.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['runId'] = nativeToJson<String>(runId);
    json['stepId'] = nativeToJson<String>(stepId);
    return json;
  }

  CreateBuildStepBuildStepInsert({
    required this.runId,
    required this.stepId,
  });
}

@immutable
class CreateBuildStepData {
  final CreateBuildStepBuildStepInsert buildStep_insert;
  CreateBuildStepData.fromJson(dynamic json)
    : buildStep_insert = CreateBuildStepBuildStepInsert.fromJson(
        json['buildStep_insert'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBuildStepData otherTyped = other as CreateBuildStepData;
    return buildStep_insert == otherTyped.buildStep_insert;
  }

  @override
  int get hashCode => buildStep_insert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildStep_insert'] = buildStep_insert.toJson();
    return json;
  }

  CreateBuildStepData({
    required this.buildStep_insert,
  });
}

@immutable
class CreateBuildStepVariables {
  final String teamId;
  final String runId;
  final String stepId;
  final String name;
  final int stepOrder;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  CreateBuildStepVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      runId = nativeFromJson<String>(json['runId']),
      stepId = nativeFromJson<String>(json['stepId']),
      name = nativeFromJson<String>(json['name']),
      stepOrder = nativeFromJson<int>(json['stepOrder']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBuildStepVariables otherTyped =
        other as CreateBuildStepVariables;
    return teamId == otherTyped.teamId &&
        runId == otherTyped.runId &&
        stepId == otherTyped.stepId &&
        name == otherTyped.name &&
        stepOrder == otherTyped.stepOrder;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    runId.hashCode,
    stepId.hashCode,
    name.hashCode,
    stepOrder.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['runId'] = nativeToJson<String>(runId);
    json['stepId'] = nativeToJson<String>(stepId);
    json['name'] = nativeToJson<String>(name);
    json['stepOrder'] = nativeToJson<int>(stepOrder);
    return json;
  }

  CreateBuildStepVariables({
    required this.teamId,
    required this.runId,
    required this.stepId,
    required this.name,
    required this.stepOrder,
  });
}
