part of 'teams.dart';

class CreateTeamVariablesBuilder {
  String id;
  String name;

  final FirebaseDataConnect _dataConnect;
  CreateTeamVariablesBuilder(
    this._dataConnect, {
    required this.id,
    required this.name,
  });
  Deserializer<CreateTeamData> dataDeserializer = (dynamic json) =>
      CreateTeamData.fromJson(jsonDecode(json));
  Serializer<CreateTeamVariables> varsSerializer = (CreateTeamVariables vars) =>
      jsonEncode(vars.toJson());
  Future<OperationResult<CreateTeamData, CreateTeamVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateTeamData, CreateTeamVariables> ref() {
    CreateTeamVariables vars = CreateTeamVariables(
      id: id,
      name: name,
    );
    return _dataConnect.mutation(
      "CreateTeam",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class CreateTeamTeamInsert {
  final String id;
  CreateTeamTeamInsert.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateTeamTeamInsert otherTyped = other as CreateTeamTeamInsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateTeamTeamInsert({
    required this.id,
  });
}

@immutable
class CreateTeamTeamMemberInsert {
  final BigInt id;
  CreateTeamTeamMemberInsert.fromJson(dynamic json)
    : id = bigIntFromJson(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateTeamTeamMemberInsert otherTyped =
        other as CreateTeamTeamMemberInsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = bigIntToJson(id);
    return json;
  }

  CreateTeamTeamMemberInsert({
    required this.id,
  });
}

@immutable
class CreateTeamData {
  final CreateTeamTeamInsert team_insert;
  final CreateTeamTeamMemberInsert teamMember_insert;
  CreateTeamData.fromJson(dynamic json)
    : team_insert = CreateTeamTeamInsert.fromJson(json['team_insert']),
      teamMember_insert = CreateTeamTeamMemberInsert.fromJson(
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

    final CreateTeamData otherTyped = other as CreateTeamData;
    return team_insert == otherTyped.team_insert &&
        teamMember_insert == otherTyped.teamMember_insert;
  }

  @override
  int get hashCode =>
      Object.hashAll([team_insert.hashCode, teamMember_insert.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['team_insert'] = team_insert.toJson();
    json['teamMember_insert'] = teamMember_insert.toJson();
    return json;
  }

  CreateTeamData({
    required this.team_insert,
    required this.teamMember_insert,
  });
}

@immutable
class CreateTeamVariables {
  final String id;
  final String name;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  CreateTeamVariables.fromJson(Map<String, dynamic> json)
    : id = nativeFromJson<String>(json['id']),
      name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateTeamVariables otherTyped = other as CreateTeamVariables;
    return id == otherTyped.id && name == otherTyped.name;
  }

  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  CreateTeamVariables({
    required this.id,
    required this.name,
  });
}
