part of 'teams.dart';

class AddTeamMemberVariablesBuilder {
  String teamId;
  String actorUid;
  String userId;

  final FirebaseDataConnect _dataConnect;
  AddTeamMemberVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.actorUid,
    required this.userId,
  });
  Deserializer<AddTeamMemberData> dataDeserializer = (dynamic json) =>
      AddTeamMemberData.fromJson(jsonDecode(json));
  Serializer<AddTeamMemberVariables> varsSerializer =
      (AddTeamMemberVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<AddTeamMemberData, AddTeamMemberVariables>> execute() {
    return ref().execute();
  }

  MutationRef<AddTeamMemberData, AddTeamMemberVariables> ref() {
    AddTeamMemberVariables vars = AddTeamMemberVariables(
      teamId: teamId,
      actorUid: actorUid,
      userId: userId,
    );
    return _dataConnect.mutation(
      "AddTeamMember",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class AddTeamMemberTeamUpdate {
  final String id;
  AddTeamMemberTeamUpdate.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final AddTeamMemberTeamUpdate otherTyped = other as AddTeamMemberTeamUpdate;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  AddTeamMemberTeamUpdate({
    required this.id,
  });
}

@immutable
class AddTeamMemberTeamMemberInsert {
  final BigInt id;
  AddTeamMemberTeamMemberInsert.fromJson(dynamic json)
    : id = bigIntFromJson(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final AddTeamMemberTeamMemberInsert otherTyped =
        other as AddTeamMemberTeamMemberInsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = bigIntToJson(id);
    return json;
  }

  AddTeamMemberTeamMemberInsert({
    required this.id,
  });
}

@immutable
class AddTeamMemberData {
  final AddTeamMemberTeamUpdate? team_update;
  final AddTeamMemberTeamMemberInsert teamMember_insert;
  AddTeamMemberData.fromJson(dynamic json)
    : team_update = json['team_update'] == null
          ? null
          : AddTeamMemberTeamUpdate.fromJson(json['team_update']),
      teamMember_insert = AddTeamMemberTeamMemberInsert.fromJson(
        json['teamMember_insert'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final AddTeamMemberData otherTyped = other as AddTeamMemberData;
    return team_update == otherTyped.team_update &&
        teamMember_insert == otherTyped.teamMember_insert;
  }

  @override
  int get hashCode =>
      Object.hashAll([team_update.hashCode, teamMember_insert.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (team_update != null) {
      json['team_update'] = team_update!.toJson();
    }
    json['teamMember_insert'] = teamMember_insert.toJson();
    return json;
  }

  AddTeamMemberData({
    this.team_update,
    required this.teamMember_insert,
  });
}

@immutable
class AddTeamMemberVariables {
  final String teamId;
  final String actorUid;
  final String userId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  AddTeamMemberVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      actorUid = nativeFromJson<String>(json['actorUid']),
      userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final AddTeamMemberVariables otherTyped = other as AddTeamMemberVariables;
    return teamId == otherTyped.teamId &&
        actorUid == otherTyped.actorUid &&
        userId == otherTyped.userId;
  }

  @override
  int get hashCode =>
      Object.hashAll([teamId.hashCode, actorUid.hashCode, userId.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['actorUid'] = nativeToJson<String>(actorUid);
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  AddTeamMemberVariables({
    required this.teamId,
    required this.actorUid,
    required this.userId,
  });
}
