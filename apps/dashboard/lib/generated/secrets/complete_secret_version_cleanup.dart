part of 'secrets.dart';

class CompleteSecretVersionCleanupVariablesBuilder {
  String path;

  final FirebaseDataConnect _dataConnect;
  CompleteSecretVersionCleanupVariablesBuilder(
    this._dataConnect, {
    required this.path,
  });
  Deserializer<CompleteSecretVersionCleanupData> dataDeserializer =
      (dynamic json) =>
          CompleteSecretVersionCleanupData.fromJson(jsonDecode(json));
  Serializer<CompleteSecretVersionCleanupVariables> varsSerializer =
      (CompleteSecretVersionCleanupVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<
      CompleteSecretVersionCleanupData,
      CompleteSecretVersionCleanupVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<
    CompleteSecretVersionCleanupData,
    CompleteSecretVersionCleanupVariables
  >
  ref() {
    CompleteSecretVersionCleanupVariables vars =
        CompleteSecretVersionCleanupVariables(
          path: path,
        );
    return _dataConnect.mutation(
      "CompleteSecretVersionCleanup",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class CompleteSecretVersionCleanupSecretVersionCleanupDelete {
  final String path;
  CompleteSecretVersionCleanupSecretVersionCleanupDelete.fromJson(dynamic json)
    : path = nativeFromJson<String>(json['path']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CompleteSecretVersionCleanupSecretVersionCleanupDelete otherTyped =
        other as CompleteSecretVersionCleanupSecretVersionCleanupDelete;
    return path == otherTyped.path;
  }

  @override
  int get hashCode => path.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['path'] = nativeToJson<String>(path);
    return json;
  }

  CompleteSecretVersionCleanupSecretVersionCleanupDelete({
    required this.path,
  });
}

@immutable
class CompleteSecretVersionCleanupData {
  final CompleteSecretVersionCleanupSecretVersionCleanupDelete?
  secretVersionCleanup_delete;
  CompleteSecretVersionCleanupData.fromJson(dynamic json)
    : secretVersionCleanup_delete = json['secretVersionCleanup_delete'] == null
          ? null
          : CompleteSecretVersionCleanupSecretVersionCleanupDelete.fromJson(
              json['secretVersionCleanup_delete'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CompleteSecretVersionCleanupData otherTyped =
        other as CompleteSecretVersionCleanupData;
    return secretVersionCleanup_delete ==
        otherTyped.secretVersionCleanup_delete;
  }

  @override
  int get hashCode => secretVersionCleanup_delete.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (secretVersionCleanup_delete != null) {
      json['secretVersionCleanup_delete'] = secretVersionCleanup_delete!
          .toJson();
    }
    return json;
  }

  CompleteSecretVersionCleanupData({
    this.secretVersionCleanup_delete,
  });
}

@immutable
class CompleteSecretVersionCleanupVariables {
  final String path;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  CompleteSecretVersionCleanupVariables.fromJson(Map<String, dynamic> json)
    : path = nativeFromJson<String>(json['path']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CompleteSecretVersionCleanupVariables otherTyped =
        other as CompleteSecretVersionCleanupVariables;
    return path == otherTyped.path;
  }

  @override
  int get hashCode => path.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['path'] = nativeToJson<String>(path);
    return json;
  }

  CompleteSecretVersionCleanupVariables({
    required this.path,
  });
}
