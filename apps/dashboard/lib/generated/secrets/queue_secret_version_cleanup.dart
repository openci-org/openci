part of 'secrets.dart';

class QueueSecretVersionCleanupVariablesBuilder {
  String path;

  final FirebaseDataConnect _dataConnect;
  QueueSecretVersionCleanupVariablesBuilder(
    this._dataConnect, {
    required this.path,
  });
  Deserializer<QueueSecretVersionCleanupData> dataDeserializer =
      (dynamic json) =>
          QueueSecretVersionCleanupData.fromJson(jsonDecode(json));
  Serializer<QueueSecretVersionCleanupVariables> varsSerializer =
      (QueueSecretVersionCleanupVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<
      QueueSecretVersionCleanupData,
      QueueSecretVersionCleanupVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<QueueSecretVersionCleanupData, QueueSecretVersionCleanupVariables>
  ref() {
    QueueSecretVersionCleanupVariables vars =
        QueueSecretVersionCleanupVariables(
          path: path,
        );
    return _dataConnect.mutation(
      "QueueSecretVersionCleanup",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class QueueSecretVersionCleanupSecretVersionCleanupUpsert {
  final String path;
  QueueSecretVersionCleanupSecretVersionCleanupUpsert.fromJson(dynamic json)
    : path = nativeFromJson<String>(json['path']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final QueueSecretVersionCleanupSecretVersionCleanupUpsert otherTyped =
        other as QueueSecretVersionCleanupSecretVersionCleanupUpsert;
    return path == otherTyped.path;
  }

  @override
  int get hashCode => path.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['path'] = nativeToJson<String>(path);
    return json;
  }

  QueueSecretVersionCleanupSecretVersionCleanupUpsert({
    required this.path,
  });
}

@immutable
class QueueSecretVersionCleanupData {
  final QueueSecretVersionCleanupSecretVersionCleanupUpsert
  secretVersionCleanup_upsert;
  QueueSecretVersionCleanupData.fromJson(dynamic json)
    : secretVersionCleanup_upsert =
          QueueSecretVersionCleanupSecretVersionCleanupUpsert.fromJson(
            json['secretVersionCleanup_upsert'],
          );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final QueueSecretVersionCleanupData otherTyped =
        other as QueueSecretVersionCleanupData;
    return secretVersionCleanup_upsert ==
        otherTyped.secretVersionCleanup_upsert;
  }

  @override
  int get hashCode => secretVersionCleanup_upsert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['secretVersionCleanup_upsert'] = secretVersionCleanup_upsert.toJson();
    return json;
  }

  QueueSecretVersionCleanupData({
    required this.secretVersionCleanup_upsert,
  });
}

@immutable
class QueueSecretVersionCleanupVariables {
  final String path;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  QueueSecretVersionCleanupVariables.fromJson(Map<String, dynamic> json)
    : path = nativeFromJson<String>(json['path']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final QueueSecretVersionCleanupVariables otherTyped =
        other as QueueSecretVersionCleanupVariables;
    return path == otherTyped.path;
  }

  @override
  int get hashCode => path.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['path'] = nativeToJson<String>(path);
    return json;
  }

  QueueSecretVersionCleanupVariables({
    required this.path,
  });
}
