part of 'default.dart';

class UpdateSecretMetadataVariablesBuilder {
  String id;
  String name;

  final FirebaseDataConnect _dataConnect;
  UpdateSecretMetadataVariablesBuilder(this._dataConnect, {required  this.id,required  this.name,});
  Deserializer<UpdateSecretMetadataData> dataDeserializer = (dynamic json)  => UpdateSecretMetadataData.fromJson(jsonDecode(json));
  Serializer<UpdateSecretMetadataVariables> varsSerializer = (UpdateSecretMetadataVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateSecretMetadataData, UpdateSecretMetadataVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateSecretMetadataData, UpdateSecretMetadataVariables> ref() {
    UpdateSecretMetadataVariables vars= UpdateSecretMetadataVariables(id: id,name: name,);
    return _dataConnect.mutation("UpdateSecretMetadata", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateSecretMetadataSecretUpdate {
  final String id;
  UpdateSecretMetadataSecretUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateSecretMetadataSecretUpdate otherTyped = other as UpdateSecretMetadataSecretUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateSecretMetadataSecretUpdate({
    required this.id,
  });
}

@immutable
class UpdateSecretMetadataData {
  final UpdateSecretMetadataSecretUpdate? secret_update;
  UpdateSecretMetadataData.fromJson(dynamic json):
  
  secret_update = json['secret_update'] == null ? null : UpdateSecretMetadataSecretUpdate.fromJson(json['secret_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateSecretMetadataData otherTyped = other as UpdateSecretMetadataData;
    return secret_update == otherTyped.secret_update;
    
  }
  @override
  int get hashCode => secret_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (secret_update != null) {
      json['secret_update'] = secret_update!.toJson();
    }
    return json;
  }

  UpdateSecretMetadataData({
    this.secret_update,
  });
}

@immutable
class UpdateSecretMetadataVariables {
  final String id;
  final String name;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateSecretMetadataVariables.fromJson(Map<String, dynamic> json):
  
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

    final UpdateSecretMetadataVariables otherTyped = other as UpdateSecretMetadataVariables;
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

  UpdateSecretMetadataVariables({
    required this.id,
    required this.name,
  });
}

