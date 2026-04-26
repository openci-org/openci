part of 'default.dart';

class CreateTeamForCurrentUserVariablesBuilder {
  String id;
  String name;

  final FirebaseDataConnect _dataConnect;
  CreateTeamForCurrentUserVariablesBuilder(this._dataConnect, {required  this.id,required  this.name,});
  Deserializer<CreateTeamForCurrentUserData> dataDeserializer = (dynamic json)  => CreateTeamForCurrentUserData.fromJson(jsonDecode(json));
  Serializer<CreateTeamForCurrentUserVariables> varsSerializer = (CreateTeamForCurrentUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateTeamForCurrentUserData, CreateTeamForCurrentUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateTeamForCurrentUserData, CreateTeamForCurrentUserVariables> ref() {
    CreateTeamForCurrentUserVariables vars= CreateTeamForCurrentUserVariables(id: id,name: name,);
    return _dataConnect.mutation("CreateTeamForCurrentUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateTeamForCurrentUserData {
  final int? createTeam;
  CreateTeamForCurrentUserData.fromJson(dynamic json):
  
  createTeam = json['createTeam'] == null ? null : nativeFromJson<int>(json['createTeam']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateTeamForCurrentUserData otherTyped = other as CreateTeamForCurrentUserData;
    return createTeam == otherTyped.createTeam;
    
  }
  @override
  int get hashCode => createTeam.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (createTeam != null) {
      json['createTeam'] = nativeToJson<int?>(createTeam);
    }
    return json;
  }

  CreateTeamForCurrentUserData({
    this.createTeam,
  });
}

@immutable
class CreateTeamForCurrentUserVariables {
  final String id;
  final String name;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateTeamForCurrentUserVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateTeamForCurrentUserVariables otherTyped = other as CreateTeamForCurrentUserVariables;
    return id == otherTyped.id && 
    name == otherTyped.name;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  CreateTeamForCurrentUserVariables({
    required this.id,
    required this.name,
  });
}

