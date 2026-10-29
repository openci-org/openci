part of 'secrets.dart';

class DeleteSecretReferenceVariablesBuilder {
  String teamId;
  String name;
  String expectedSecretVersionPath;

  final FirebaseDataConnect _dataConnect;
  DeleteSecretReferenceVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.name,
    required this.expectedSecretVersionPath,
  });
  Deserializer<DeleteSecretReferenceData> dataDeserializer = (dynamic json) =>
      DeleteSecretReferenceData.fromJson(jsonDecode(json));
  Serializer<DeleteSecretReferenceVariables> varsSerializer =
      (DeleteSecretReferenceVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<DeleteSecretReferenceData, DeleteSecretReferenceVariables>
  >
  execute() {
    return ref().execute();
  }

  MutationRef<DeleteSecretReferenceData, DeleteSecretReferenceVariables> ref() {
    DeleteSecretReferenceVariables vars = DeleteSecretReferenceVariables(
      teamId: teamId,
      name: name,
      expectedSecretVersionPath: expectedSecretVersionPath,
    );
    return _dataConnect.mutation(
      "DeleteSecretReference",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class DeleteSecretReferenceData {
  final int secretReference_deleteMany;
  DeleteSecretReferenceData.fromJson(dynamic json)
    : secretReference_deleteMany = nativeFromJson<int>(
        json['secretReference_deleteMany'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSecretReferenceData otherTyped =
        other as DeleteSecretReferenceData;
    return secretReference_deleteMany == otherTyped.secretReference_deleteMany;
  }

  @override
  int get hashCode => secretReference_deleteMany.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['secretReference_deleteMany'] = nativeToJson<int>(
      secretReference_deleteMany,
    );
    return json;
  }

  DeleteSecretReferenceData({
    required this.secretReference_deleteMany,
  });
}

@immutable
class DeleteSecretReferenceVariables {
  final String teamId;
  final String name;
  final String expectedSecretVersionPath;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  DeleteSecretReferenceVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      name = nativeFromJson<String>(json['name']),
      expectedSecretVersionPath = nativeFromJson<String>(
        json['expectedSecretVersionPath'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSecretReferenceVariables otherTyped =
        other as DeleteSecretReferenceVariables;
    return teamId == otherTyped.teamId &&
        name == otherTyped.name &&
        expectedSecretVersionPath == otherTyped.expectedSecretVersionPath;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    name.hashCode,
    expectedSecretVersionPath.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['name'] = nativeToJson<String>(name);
    json['expectedSecretVersionPath'] = nativeToJson<String>(
      expectedSecretVersionPath,
    );
    return json;
  }

  DeleteSecretReferenceVariables({
    required this.teamId,
    required this.name,
    required this.expectedSecretVersionPath,
  });
}
