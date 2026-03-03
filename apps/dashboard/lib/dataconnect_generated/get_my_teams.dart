part of 'generated.dart';

class GetMyTeamsVariablesBuilder {
  String uid;

  final FirebaseDataConnect _dataConnect;
  GetMyTeamsVariablesBuilder(this._dataConnect, {required  this.uid,});
  Deserializer<GetMyTeamsData> dataDeserializer = (dynamic json)  => GetMyTeamsData.fromJson(jsonDecode(json));
  Serializer<GetMyTeamsVariables> varsSerializer = (GetMyTeamsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetMyTeamsData, GetMyTeamsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetMyTeamsData, GetMyTeamsVariables> ref() {
    GetMyTeamsVariables vars= GetMyTeamsVariables(uid: uid,);
    return _dataConnect.query("GetMyTeams", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetMyTeamsTeams {
  final String id;
  final String name;
  final List<String> members;
  final List<int> installationIds;
  final int runNumber;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  GetMyTeamsTeams.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  members = (json['members'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList(),
  installationIds = (json['installationIds'] as List<dynamic>)
        .map((e) => nativeFromJson<int>(e))
        .toList(),
  runNumber = nativeFromJson<int>(json['runNumber']),
  createdAt = Timestamp.fromJson(json['createdAt']),
  updatedAt = Timestamp.fromJson(json['updatedAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyTeamsTeams otherTyped = other as GetMyTeamsTeams;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    members == otherTyped.members && 
    installationIds == otherTyped.installationIds && 
    runNumber == otherTyped.runNumber && 
    createdAt == otherTyped.createdAt && 
    updatedAt == otherTyped.updatedAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, members.hashCode, installationIds.hashCode, runNumber.hashCode, createdAt.hashCode, updatedAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['members'] = members.map((e) => nativeToJson<String>(e)).toList();
    json['installationIds'] = installationIds.map((e) => nativeToJson<int>(e)).toList();
    json['runNumber'] = nativeToJson<int>(runNumber);
    json['createdAt'] = createdAt.toJson();
    json['updatedAt'] = updatedAt.toJson();
    return json;
  }

  GetMyTeamsTeams({
    required this.id,
    required this.name,
    required this.members,
    required this.installationIds,
    required this.runNumber,
    required this.createdAt,
    required this.updatedAt,
  });
}

@immutable
class GetMyTeamsData {
  final List<GetMyTeamsTeams> teams;
  GetMyTeamsData.fromJson(dynamic json):
  
  teams = (json['teams'] as List<dynamic>)
        .map((e) => GetMyTeamsTeams.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyTeamsData otherTyped = other as GetMyTeamsData;
    return teams == otherTyped.teams;
    
  }
  @override
  int get hashCode => teams.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teams'] = teams.map((e) => e.toJson()).toList();
    return json;
  }

  GetMyTeamsData({
    required this.teams,
  });
}

@immutable
class GetMyTeamsVariables {
  final String uid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetMyTeamsVariables.fromJson(Map<String, dynamic> json):
  
  uid = nativeFromJson<String>(json['uid']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyTeamsVariables otherTyped = other as GetMyTeamsVariables;
    return uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => uid.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  GetMyTeamsVariables({
    required this.uid,
  });
}

