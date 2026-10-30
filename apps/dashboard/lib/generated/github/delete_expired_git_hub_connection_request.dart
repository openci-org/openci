part of 'github.dart';

class DeleteExpiredGitHubConnectionRequestVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteExpiredGitHubConnectionRequestVariablesBuilder(
    this._dataConnect, {
    required this.id,
  });
  Deserializer<DeleteExpiredGitHubConnectionRequestData> dataDeserializer =
      (dynamic json) =>
          DeleteExpiredGitHubConnectionRequestData.fromJson(jsonDecode(json));
  Serializer<DeleteExpiredGitHubConnectionRequestVariables> varsSerializer =
      (DeleteExpiredGitHubConnectionRequestVariables vars) =>
          jsonEncode(vars.toJson());
  Future<
    OperationResult<
      DeleteExpiredGitHubConnectionRequestData,
      DeleteExpiredGitHubConnectionRequestVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<
    DeleteExpiredGitHubConnectionRequestData,
    DeleteExpiredGitHubConnectionRequestVariables
  >
  ref() {
    DeleteExpiredGitHubConnectionRequestVariables vars =
        DeleteExpiredGitHubConnectionRequestVariables(
          id: id,
        );
    return _dataConnect.mutation(
      "DeleteExpiredGitHubConnectionRequest",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class DeleteExpiredGitHubConnectionRequestData {
  final int gitHubConnectionRequest_deleteMany;
  DeleteExpiredGitHubConnectionRequestData.fromJson(dynamic json)
    : gitHubConnectionRequest_deleteMany = nativeFromJson<int>(
        json['gitHubConnectionRequest_deleteMany'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteExpiredGitHubConnectionRequestData otherTyped =
        other as DeleteExpiredGitHubConnectionRequestData;
    return gitHubConnectionRequest_deleteMany ==
        otherTyped.gitHubConnectionRequest_deleteMany;
  }

  @override
  int get hashCode => gitHubConnectionRequest_deleteMany.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['gitHubConnectionRequest_deleteMany'] = nativeToJson<int>(
      gitHubConnectionRequest_deleteMany,
    );
    return json;
  }

  DeleteExpiredGitHubConnectionRequestData({
    required this.gitHubConnectionRequest_deleteMany,
  });
}

@immutable
class DeleteExpiredGitHubConnectionRequestVariables {
  final String id;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  DeleteExpiredGitHubConnectionRequestVariables.fromJson(
    Map<String, dynamic> json,
  ) : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteExpiredGitHubConnectionRequestVariables otherTyped =
        other as DeleteExpiredGitHubConnectionRequestVariables;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteExpiredGitHubConnectionRequestVariables({
    required this.id,
  });
}
