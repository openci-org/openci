part of 'teams.dart';

class GetTeamMembersVariablesBuilder {
  String teamId;

  final FirebaseDataConnect _dataConnect;
  GetTeamMembersVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
  });
  Deserializer<GetTeamMembersData> dataDeserializer = (dynamic json) =>
      GetTeamMembersData.fromJson(jsonDecode(json));
  Serializer<GetTeamMembersVariables> varsSerializer =
      (GetTeamMembersVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetTeamMembersData, GetTeamMembersVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetTeamMembersData, GetTeamMembersVariables> ref() {
    GetTeamMembersVariables vars = GetTeamMembersVariables(
      teamId: teamId,
    );
    return _dataConnect.query(
      "GetTeamMembers",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetTeamMembersTeam {
  final List<GetTeamMembersTeamMembers> members;
  GetTeamMembersTeam.fromJson(dynamic json)
    : members = (json['members'] as List<dynamic>)
          .map((e) => GetTeamMembersTeamMembers.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetTeamMembersTeam otherTyped = other as GetTeamMembersTeam;
    return members == otherTyped.members;
  }

  @override
  int get hashCode => members.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['members'] = members.map((e) => e.toJson()).toList();
    return json;
  }

  GetTeamMembersTeam({
    required this.members,
  });
}

@immutable
class GetTeamMembersTeamMembers {
  final String userId;
  GetTeamMembersTeamMembers.fromJson(dynamic json)
    : userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetTeamMembersTeamMembers otherTyped =
        other as GetTeamMembersTeamMembers;
    return userId == otherTyped.userId;
  }

  @override
  int get hashCode => userId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  GetTeamMembersTeamMembers({
    required this.userId,
  });
}

@immutable
class GetTeamMembersData {
  final GetTeamMembersTeam? team;
  GetTeamMembersData.fromJson(dynamic json)
    : team = json['team'] == null
          ? null
          : GetTeamMembersTeam.fromJson(json['team']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetTeamMembersData otherTyped = other as GetTeamMembersData;
    return team == otherTyped.team;
  }

  @override
  int get hashCode => team.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (team != null) {
      json['team'] = team!.toJson();
    }
    return json;
  }

  GetTeamMembersData({
    this.team,
  });
}

@immutable
class GetTeamMembersVariables {
  final String teamId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetTeamMembersVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetTeamMembersVariables otherTyped = other as GetTeamMembersVariables;
    return teamId == otherTyped.teamId;
  }

  @override
  int get hashCode => teamId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  GetTeamMembersVariables({
    required this.teamId,
  });
}
