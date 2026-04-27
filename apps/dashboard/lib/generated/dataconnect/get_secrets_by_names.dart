part of 'default.dart';

class GetSecretsByNamesVariablesBuilder {
  String teamId;
  List<String> names;

  final FirebaseDataConnect _dataConnect;
  GetSecretsByNamesVariablesBuilder(this._dataConnect, {required  this.teamId,required  this.names,});
  Deserializer<GetSecretsByNamesData> dataDeserializer = (dynamic json)  => GetSecretsByNamesData.fromJson(jsonDecode(json));
  Serializer<GetSecretsByNamesVariables> varsSerializer = (GetSecretsByNamesVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetSecretsByNamesData, GetSecretsByNamesVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetSecretsByNamesData, GetSecretsByNamesVariables> ref() {
    GetSecretsByNamesVariables vars= GetSecretsByNamesVariables(teamId: teamId,names: names,);
    return _dataConnect.query("GetSecretsByNames", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetSecretsByNamesSecrets {
  final String id;
  final String name;
  final String teamId;
  GetSecretsByNamesSecrets.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSecretsByNamesSecrets otherTyped = other as GetSecretsByNamesSecrets;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, teamId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  GetSecretsByNamesSecrets({
    required this.id,
    required this.name,
    required this.teamId,
  });
}

@immutable
class GetSecretsByNamesData {
  final List<GetSecretsByNamesSecrets> secrets;
  GetSecretsByNamesData.fromJson(dynamic json):
  
  secrets = (json['secrets'] as List<dynamic>)
        .map((e) => GetSecretsByNamesSecrets.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSecretsByNamesData otherTyped = other as GetSecretsByNamesData;
    return secrets == otherTyped.secrets;
    
  }
  @override
  int get hashCode => secrets.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['secrets'] = secrets.map((e) => e.toJson()).toList();
    return json;
  }

  GetSecretsByNamesData({
    required this.secrets,
  });
}

@immutable
class GetSecretsByNamesVariables {
  final String teamId;
  final List<String> names;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetSecretsByNamesVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']),
  names = (json['names'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSecretsByNamesVariables otherTyped = other as GetSecretsByNamesVariables;
    return teamId == otherTyped.teamId && 
    names == otherTyped.names;
    
  }
  @override
  int get hashCode => Object.hashAll([teamId.hashCode, names.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['names'] = names.map((e) => nativeToJson<String>(e)).toList();
    return json;
  }

  GetSecretsByNamesVariables({
    required this.teamId,
    required this.names,
  });
}

