part of 'github.dart';

class GetGitHubConnectionContextVariablesBuilder {
  String teamId;
  String userId;

  final FirebaseDataConnect _dataConnect;
  GetGitHubConnectionContextVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.userId,
  });
  Deserializer<GetGitHubConnectionContextData> dataDeserializer =
      (dynamic json) =>
          GetGitHubConnectionContextData.fromJson(jsonDecode(json));
  Serializer<GetGitHubConnectionContextVariables> varsSerializer =
      (GetGitHubConnectionContextVariables vars) => jsonEncode(vars.toJson());
  Future<
    QueryResult<
      GetGitHubConnectionContextData,
      GetGitHubConnectionContextVariables
    >
  >
  execute() {
    return ref().execute();
  }

  QueryRef<GetGitHubConnectionContextData, GetGitHubConnectionContextVariables>
  ref() {
    GetGitHubConnectionContextVariables vars =
        GetGitHubConnectionContextVariables(
          teamId: teamId,
          userId: userId,
        );
    return _dataConnect.query(
      "GetGitHubConnectionContext",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetGitHubConnectionContextTeamMember {
  final BigInt id;
  GetGitHubConnectionContextTeamMember.fromJson(dynamic json)
    : id = bigIntFromJson(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetGitHubConnectionContextTeamMember otherTyped =
        other as GetGitHubConnectionContextTeamMember;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = bigIntToJson(id);
    return json;
  }

  GetGitHubConnectionContextTeamMember({
    required this.id,
  });
}

@immutable
class GetGitHubConnectionContextData {
  final GetGitHubConnectionContextTeamMember? teamMember;
  GetGitHubConnectionContextData.fromJson(dynamic json)
    : teamMember = json['teamMember'] == null
          ? null
          : GetGitHubConnectionContextTeamMember.fromJson(json['teamMember']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetGitHubConnectionContextData otherTyped =
        other as GetGitHubConnectionContextData;
    return teamMember == otherTyped.teamMember;
  }

  @override
  int get hashCode => teamMember.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (teamMember != null) {
      json['teamMember'] = teamMember!.toJson();
    }
    return json;
  }

  GetGitHubConnectionContextData({
    this.teamMember,
  });
}

@immutable
class GetGitHubConnectionContextVariables {
  final String teamId;
  final String userId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetGitHubConnectionContextVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetGitHubConnectionContextVariables otherTyped =
        other as GetGitHubConnectionContextVariables;
    return teamId == otherTyped.teamId && userId == otherTyped.userId;
  }

  @override
  int get hashCode => Object.hashAll([teamId.hashCode, userId.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  GetGitHubConnectionContextVariables({
    required this.teamId,
    required this.userId,
  });
}
