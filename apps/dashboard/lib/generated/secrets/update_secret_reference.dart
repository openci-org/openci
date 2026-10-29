part of 'secrets.dart';

class UpdateSecretReferenceVariablesBuilder {
  String teamId;
  String name;
  String expectedSecretVersionPath;
  String secretVersionPath;

  final FirebaseDataConnect _dataConnect;
  UpdateSecretReferenceVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.name,
    required this.expectedSecretVersionPath,
    required this.secretVersionPath,
  });
  Deserializer<UpdateSecretReferenceData> dataDeserializer = (dynamic json) =>
      UpdateSecretReferenceData.fromJson(jsonDecode(json));
  Serializer<UpdateSecretReferenceVariables> varsSerializer =
      (UpdateSecretReferenceVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<UpdateSecretReferenceData, UpdateSecretReferenceVariables>
  >
  execute() {
    return ref().execute();
  }

  MutationRef<UpdateSecretReferenceData, UpdateSecretReferenceVariables> ref() {
    UpdateSecretReferenceVariables vars = UpdateSecretReferenceVariables(
      teamId: teamId,
      name: name,
      expectedSecretVersionPath: expectedSecretVersionPath,
      secretVersionPath: secretVersionPath,
    );
    return _dataConnect.mutation(
      "UpdateSecretReference",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class UpdateSecretReferenceData {
  final int secretReference_updateMany;
  UpdateSecretReferenceData.fromJson(dynamic json)
    : secretReference_updateMany = nativeFromJson<int>(
        json['secretReference_updateMany'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateSecretReferenceData otherTyped =
        other as UpdateSecretReferenceData;
    return secretReference_updateMany == otherTyped.secretReference_updateMany;
  }

  @override
  int get hashCode => secretReference_updateMany.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['secretReference_updateMany'] = nativeToJson<int>(
      secretReference_updateMany,
    );
    return json;
  }

  UpdateSecretReferenceData({
    required this.secretReference_updateMany,
  });
}

@immutable
class UpdateSecretReferenceVariables {
  final String teamId;
  final String name;
  final String expectedSecretVersionPath;
  final String secretVersionPath;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  UpdateSecretReferenceVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      name = nativeFromJson<String>(json['name']),
      expectedSecretVersionPath = nativeFromJson<String>(
        json['expectedSecretVersionPath'],
      ),
      secretVersionPath = nativeFromJson<String>(json['secretVersionPath']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateSecretReferenceVariables otherTyped =
        other as UpdateSecretReferenceVariables;
    return teamId == otherTyped.teamId &&
        name == otherTyped.name &&
        expectedSecretVersionPath == otherTyped.expectedSecretVersionPath &&
        secretVersionPath == otherTyped.secretVersionPath;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    name.hashCode,
    expectedSecretVersionPath.hashCode,
    secretVersionPath.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['name'] = nativeToJson<String>(name);
    json['expectedSecretVersionPath'] = nativeToJson<String>(
      expectedSecretVersionPath,
    );
    json['secretVersionPath'] = nativeToJson<String>(secretVersionPath);
    return json;
  }

  UpdateSecretReferenceVariables({
    required this.teamId,
    required this.name,
    required this.expectedSecretVersionPath,
    required this.secretVersionPath,
  });
}
