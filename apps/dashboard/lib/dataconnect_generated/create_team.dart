part of 'generated.dart';

class CreateTeamVariablesBuilder {
  String teamName;
  String uid;

  final FirebaseDataConnect _dataConnect;
  CreateTeamVariablesBuilder(this._dataConnect, {required  this.teamName,required  this.uid,});
  Deserializer<CreateTeamData> dataDeserializer = (dynamic json)  => CreateTeamData.fromJson(jsonDecode(json));
  Serializer<CreateTeamVariables> varsSerializer = (CreateTeamVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateTeamData, CreateTeamVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateTeamData, CreateTeamVariables> ref() {
    CreateTeamVariables vars= CreateTeamVariables(teamName: teamName,uid: uid,);
    return _dataConnect.mutation("CreateTeam", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateTeamTeamInsert {
  final String id;
  CreateTeamTeamInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
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
class CreateTeamData {
  final CreateTeamTeamInsert team_insert;
  CreateTeamData.fromJson(dynamic json):
  
  team_insert = CreateTeamTeamInsert.fromJson(json['team_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateTeamData otherTyped = other as CreateTeamData;
    return team_insert == otherTyped.team_insert;
    
  }
  @override
  int get hashCode => team_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['team_insert'] = team_insert.toJson();
    return json;
  }

  CreateTeamData({
    required this.team_insert,
  });
}

@immutable
class CreateTeamVariables {
  final String teamName;
  final String uid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateTeamVariables.fromJson(Map<String, dynamic> json):
  
  teamName = nativeFromJson<String>(json['teamName']),
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateTeamVariables otherTyped = other as CreateTeamVariables;
    return teamName == otherTyped.teamName && 
    uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => Object.hashAll([teamName.hashCode, uid.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamName'] = nativeToJson<String>(teamName);
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  CreateTeamVariables({
    required this.teamName,
    required this.uid,
  });
}

