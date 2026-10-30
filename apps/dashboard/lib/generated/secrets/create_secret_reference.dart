part of 'secrets.dart';

class CreateSecretReferenceVariablesBuilder {
  String teamId;
  String name;
  String secretVersionPath;

  final FirebaseDataConnect _dataConnect;
  CreateSecretReferenceVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.name,
    required this.secretVersionPath,
  });
  Deserializer<CreateSecretReferenceData> dataDeserializer = (dynamic json) =>
      CreateSecretReferenceData.fromJson(jsonDecode(json));
  Serializer<CreateSecretReferenceVariables> varsSerializer =
      (CreateSecretReferenceVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<CreateSecretReferenceData, CreateSecretReferenceVariables>
  >
  execute() {
    return ref().execute();
  }

  MutationRef<CreateSecretReferenceData, CreateSecretReferenceVariables> ref() {
    CreateSecretReferenceVariables vars = CreateSecretReferenceVariables(
      teamId: teamId,
      name: name,
      secretVersionPath: secretVersionPath,
    );
    return _dataConnect.mutation(
      "CreateSecretReference",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class CreateSecretReferenceSecretReferenceInsert {
  final String teamId;
  final String name;
  CreateSecretReferenceSecretReferenceInsert.fromJson(dynamic json)
    : teamId = nativeFromJson<String>(json['teamId']),
      name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateSecretReferenceSecretReferenceInsert otherTyped =
        other as CreateSecretReferenceSecretReferenceInsert;
    return teamId == otherTyped.teamId && name == otherTyped.name;
  }

  @override
  int get hashCode => Object.hashAll([teamId.hashCode, name.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  CreateSecretReferenceSecretReferenceInsert({
    required this.teamId,
    required this.name,
  });
}

@immutable
class CreateSecretReferenceData {
  final CreateSecretReferenceSecretReferenceInsert secretReference_insert;
  CreateSecretReferenceData.fromJson(dynamic json)
    : secretReference_insert =
          CreateSecretReferenceSecretReferenceInsert.fromJson(
            json['secretReference_insert'],
          );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateSecretReferenceData otherTyped =
        other as CreateSecretReferenceData;
    return secretReference_insert == otherTyped.secretReference_insert;
  }

  @override
  int get hashCode => secretReference_insert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['secretReference_insert'] = secretReference_insert.toJson();
    return json;
  }

  CreateSecretReferenceData({
    required this.secretReference_insert,
  });
}

@immutable
class CreateSecretReferenceVariables {
  final String teamId;
  final String name;
  final String secretVersionPath;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  CreateSecretReferenceVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      name = nativeFromJson<String>(json['name']),
      secretVersionPath = nativeFromJson<String>(json['secretVersionPath']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateSecretReferenceVariables otherTyped =
        other as CreateSecretReferenceVariables;
    return teamId == otherTyped.teamId &&
        name == otherTyped.name &&
        secretVersionPath == otherTyped.secretVersionPath;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    name.hashCode,
    secretVersionPath.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['name'] = nativeToJson<String>(name);
    json['secretVersionPath'] = nativeToJson<String>(secretVersionPath);
    return json;
  }

  CreateSecretReferenceVariables({
    required this.teamId,
    required this.name,
    required this.secretVersionPath,
  });
}
