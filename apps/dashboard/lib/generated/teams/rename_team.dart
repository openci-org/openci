part of 'teams.dart';

class RenameTeamVariablesBuilder {
  String teamId;
  String name;

  final FirebaseDataConnect _dataConnect;
  RenameTeamVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.name,
  });
  Deserializer<RenameTeamData> dataDeserializer = (dynamic json) =>
      RenameTeamData.fromJson(jsonDecode(json));
  Serializer<RenameTeamVariables> varsSerializer = (RenameTeamVariables vars) =>
      jsonEncode(vars.toJson());
  Future<OperationResult<RenameTeamData, RenameTeamVariables>> execute() {
    return ref().execute();
  }

  MutationRef<RenameTeamData, RenameTeamVariables> ref() {
    RenameTeamVariables vars = RenameTeamVariables(
      teamId: teamId,
      name: name,
    );
    return _dataConnect.mutation(
      "RenameTeam",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class RenameTeamTeamUpdate {
  final String id;
  RenameTeamTeamUpdate.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RenameTeamTeamUpdate otherTyped = other as RenameTeamTeamUpdate;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  RenameTeamTeamUpdate({
    required this.id,
  });
}

@immutable
class RenameTeamData {
  final RenameTeamTeamUpdate? team_update;
  RenameTeamData.fromJson(dynamic json)
    : team_update = json['team_update'] == null
          ? null
          : RenameTeamTeamUpdate.fromJson(json['team_update']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RenameTeamData otherTyped = other as RenameTeamData;
    return team_update == otherTyped.team_update;
  }

  @override
  int get hashCode => team_update.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (team_update != null) {
      json['team_update'] = team_update!.toJson();
    }
    return json;
  }

  RenameTeamData({
    this.team_update,
  });
}

@immutable
class RenameTeamVariables {
  final String teamId;
  final String name;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  RenameTeamVariables.fromJson(Map<String, dynamic> json)
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

    final RenameTeamVariables otherTyped = other as RenameTeamVariables;
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

  RenameTeamVariables({
    required this.teamId,
    required this.name,
  });
}
