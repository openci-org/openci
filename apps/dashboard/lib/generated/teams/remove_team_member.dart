part of 'teams.dart';

class RemoveTeamMemberVariablesBuilder {
  String teamId;
  String userId;

  final FirebaseDataConnect _dataConnect;
  RemoveTeamMemberVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.userId,
  });
  Deserializer<RemoveTeamMemberData> dataDeserializer = (dynamic json) =>
      RemoveTeamMemberData.fromJson(jsonDecode(json));
  Serializer<RemoveTeamMemberVariables> varsSerializer =
      (RemoveTeamMemberVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<RemoveTeamMemberData, RemoveTeamMemberVariables>>
  execute() {
    return ref().execute();
  }

  MutationRef<RemoveTeamMemberData, RemoveTeamMemberVariables> ref() {
    RemoveTeamMemberVariables vars = RemoveTeamMemberVariables(
      teamId: teamId,
      userId: userId,
    );
    return _dataConnect.mutation(
      "RemoveTeamMember",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class RemoveTeamMemberTeamUpdate {
  final String id;
  RemoveTeamMemberTeamUpdate.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RemoveTeamMemberTeamUpdate otherTyped =
        other as RemoveTeamMemberTeamUpdate;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  RemoveTeamMemberTeamUpdate({
    required this.id,
  });
}

@immutable
class RemoveTeamMemberTeamMemberDelete {
  final BigInt id;
  RemoveTeamMemberTeamMemberDelete.fromJson(dynamic json)
    : id = bigIntFromJson(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RemoveTeamMemberTeamMemberDelete otherTyped =
        other as RemoveTeamMemberTeamMemberDelete;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = bigIntToJson(id);
    return json;
  }

  RemoveTeamMemberTeamMemberDelete({
    required this.id,
  });
}

@immutable
class RemoveTeamMemberData {
  final RemoveTeamMemberTeamUpdate? team_update;
  final RemoveTeamMemberTeamMemberDelete? teamMember_delete;
  RemoveTeamMemberData.fromJson(dynamic json)
    : team_update = json['team_update'] == null
          ? null
          : RemoveTeamMemberTeamUpdate.fromJson(json['team_update']),
      teamMember_delete = json['teamMember_delete'] == null
          ? null
          : RemoveTeamMemberTeamMemberDelete.fromJson(
              json['teamMember_delete'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RemoveTeamMemberData otherTyped = other as RemoveTeamMemberData;
    return team_update == otherTyped.team_update &&
        teamMember_delete == otherTyped.teamMember_delete;
  }

  @override
  int get hashCode =>
      Object.hashAll([team_update.hashCode, teamMember_delete.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (team_update != null) {
      json['team_update'] = team_update!.toJson();
    }
    if (teamMember_delete != null) {
      json['teamMember_delete'] = teamMember_delete!.toJson();
    }
    return json;
  }

  RemoveTeamMemberData({
    this.team_update,
    this.teamMember_delete,
  });
}

@immutable
class RemoveTeamMemberVariables {
  final String teamId;
  final String userId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  RemoveTeamMemberVariables.fromJson(Map<String, dynamic> json)
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

    final RemoveTeamMemberVariables otherTyped =
        other as RemoveTeamMemberVariables;
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

  RemoveTeamMemberVariables({
    required this.teamId,
    required this.userId,
  });
}
