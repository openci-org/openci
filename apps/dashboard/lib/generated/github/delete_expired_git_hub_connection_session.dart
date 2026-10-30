part of 'github.dart';

class DeleteExpiredGitHubConnectionSessionVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteExpiredGitHubConnectionSessionVariablesBuilder(
    this._dataConnect, {
    required this.id,
  });
  Deserializer<DeleteExpiredGitHubConnectionSessionData> dataDeserializer =
      (dynamic json) =>
          DeleteExpiredGitHubConnectionSessionData.fromJson(jsonDecode(json));
  Serializer<DeleteExpiredGitHubConnectionSessionVariables> varsSerializer =
      (DeleteExpiredGitHubConnectionSessionVariables vars) =>
          jsonEncode(vars.toJson());
  Future<
    OperationResult<
      DeleteExpiredGitHubConnectionSessionData,
      DeleteExpiredGitHubConnectionSessionVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<
    DeleteExpiredGitHubConnectionSessionData,
    DeleteExpiredGitHubConnectionSessionVariables
  >
  ref() {
    DeleteExpiredGitHubConnectionSessionVariables vars =
        DeleteExpiredGitHubConnectionSessionVariables(
          id: id,
        );
    return _dataConnect.mutation(
      "DeleteExpiredGitHubConnectionSession",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class DeleteExpiredGitHubConnectionSessionData {
  final int gitHubConnectionSession_deleteMany;
  DeleteExpiredGitHubConnectionSessionData.fromJson(dynamic json)
    : gitHubConnectionSession_deleteMany = nativeFromJson<int>(
        json['gitHubConnectionSession_deleteMany'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteExpiredGitHubConnectionSessionData otherTyped =
        other as DeleteExpiredGitHubConnectionSessionData;
    return gitHubConnectionSession_deleteMany ==
        otherTyped.gitHubConnectionSession_deleteMany;
  }

  @override
  int get hashCode => gitHubConnectionSession_deleteMany.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['gitHubConnectionSession_deleteMany'] = nativeToJson<int>(
      gitHubConnectionSession_deleteMany,
    );
    return json;
  }

  DeleteExpiredGitHubConnectionSessionData({
    required this.gitHubConnectionSession_deleteMany,
  });
}

@immutable
class DeleteExpiredGitHubConnectionSessionVariables {
  final String id;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  DeleteExpiredGitHubConnectionSessionVariables.fromJson(
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

    final DeleteExpiredGitHubConnectionSessionVariables otherTyped =
        other as DeleteExpiredGitHubConnectionSessionVariables;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteExpiredGitHubConnectionSessionVariables({
    required this.id,
  });
}
