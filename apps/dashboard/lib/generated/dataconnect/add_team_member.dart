part of 'default.dart';

class AddTeamMemberVariablesBuilder {
  String teamId;

  final FirebaseDataConnect _dataConnect;
  AddTeamMemberVariablesBuilder(this._dataConnect, {required  this.teamId,});
  Deserializer<AddTeamMemberData> dataDeserializer = (dynamic json)  => AddTeamMemberData.fromJson(jsonDecode(json));
  Serializer<AddTeamMemberVariables> varsSerializer = (AddTeamMemberVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<AddTeamMemberData, AddTeamMemberVariables>> execute() {
    return ref().execute();
  }

  MutationRef<AddTeamMemberData, AddTeamMemberVariables> ref() {
    AddTeamMemberVariables vars= AddTeamMemberVariables(teamId: teamId,);
    return _dataConnect.mutation("AddTeamMember", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class AddTeamMemberTeamMemberUpsert {
  final String teamId;
  final String userId;
  AddTeamMemberTeamMemberUpsert.fromJson(dynamic json):
  
  teamId = nativeFromJson<String>(json['teamId']),
  userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddTeamMemberTeamMemberUpsert otherTyped = other as AddTeamMemberTeamMemberUpsert;
    return teamId == otherTyped.teamId && 
    userId == otherTyped.userId;
    
  }
  @override
  int get hashCode => Object.hashAll([teamId.hashCode, userId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  AddTeamMemberTeamMemberUpsert({
    required this.teamId,
    required this.userId,
  });
}

@immutable
class AddTeamMemberData {
  final AddTeamMemberTeamMemberUpsert teamMember_upsert;
  AddTeamMemberData.fromJson(dynamic json):
  
  teamMember_upsert = AddTeamMemberTeamMemberUpsert.fromJson(json['teamMember_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddTeamMemberData otherTyped = other as AddTeamMemberData;
    return teamMember_upsert == otherTyped.teamMember_upsert;
    
  }
  @override
  int get hashCode => teamMember_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamMember_upsert'] = teamMember_upsert.toJson();
    return json;
  }

  AddTeamMemberData({
    required this.teamMember_upsert,
  });
}

@immutable
class AddTeamMemberVariables {
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  AddTeamMemberVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddTeamMemberVariables otherTyped = other as AddTeamMemberVariables;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  AddTeamMemberVariables({
    required this.teamId,
  });
}

