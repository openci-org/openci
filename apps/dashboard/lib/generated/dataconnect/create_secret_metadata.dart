part of 'default.dart';

class CreateSecretMetadataVariablesBuilder {
  String id;
  String name;
  String teamId;
  String pathToSecret;

  final FirebaseDataConnect _dataConnect;
  CreateSecretMetadataVariablesBuilder(this._dataConnect, {required  this.id,required  this.name,required  this.teamId,required  this.pathToSecret,});
  Deserializer<CreateSecretMetadataData> dataDeserializer = (dynamic json)  => CreateSecretMetadataData.fromJson(jsonDecode(json));
  Serializer<CreateSecretMetadataVariables> varsSerializer = (CreateSecretMetadataVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateSecretMetadataData, CreateSecretMetadataVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateSecretMetadataData, CreateSecretMetadataVariables> ref() {
    CreateSecretMetadataVariables vars= CreateSecretMetadataVariables(id: id,name: name,teamId: teamId,pathToSecret: pathToSecret,);
    return _dataConnect.mutation("CreateSecretMetadata", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateSecretMetadataSecretInsert {
  final String id;
  CreateSecretMetadataSecretInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateSecretMetadataSecretInsert otherTyped = other as CreateSecretMetadataSecretInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateSecretMetadataSecretInsert({
    required this.id,
  });
}

@immutable
class CreateSecretMetadataData {
  final CreateSecretMetadataSecretInsert secret_insert;
  CreateSecretMetadataData.fromJson(dynamic json):
  
  secret_insert = CreateSecretMetadataSecretInsert.fromJson(json['secret_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateSecretMetadataData otherTyped = other as CreateSecretMetadataData;
    return secret_insert == otherTyped.secret_insert;
    
  }
  @override
  int get hashCode => secret_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['secret_insert'] = secret_insert.toJson();
    return json;
  }

  CreateSecretMetadataData({
    required this.secret_insert,
  });
}

@immutable
class CreateSecretMetadataVariables {
  final String id;
  final String name;
  final String teamId;
  final String pathToSecret;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateSecretMetadataVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  teamId = nativeFromJson<String>(json['teamId']),
  pathToSecret = nativeFromJson<String>(json['pathToSecret']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateSecretMetadataVariables otherTyped = other as CreateSecretMetadataVariables;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    teamId == otherTyped.teamId && 
    pathToSecret == otherTyped.pathToSecret;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, teamId.hashCode, pathToSecret.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['teamId'] = nativeToJson<String>(teamId);
    json['pathToSecret'] = nativeToJson<String>(pathToSecret);
    return json;
  }

  CreateSecretMetadataVariables({
    required this.id,
    required this.name,
    required this.teamId,
    required this.pathToSecret,
  });
}

