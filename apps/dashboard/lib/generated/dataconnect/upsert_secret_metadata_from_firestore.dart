part of 'default.dart';

class UpsertSecretMetadataFromFirestoreVariablesBuilder {
  String id;
  String name;
  String teamId;
  Optional<String> _pathToSecret = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpsertSecretMetadataFromFirestoreVariablesBuilder pathToSecret(String? t) {
   _pathToSecret.value = t;
   return this;
  }

  UpsertSecretMetadataFromFirestoreVariablesBuilder(this._dataConnect, {required  this.id,required  this.name,required  this.teamId,});
  Deserializer<UpsertSecretMetadataFromFirestoreData> dataDeserializer = (dynamic json)  => UpsertSecretMetadataFromFirestoreData.fromJson(jsonDecode(json));
  Serializer<UpsertSecretMetadataFromFirestoreVariables> varsSerializer = (UpsertSecretMetadataFromFirestoreVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertSecretMetadataFromFirestoreData, UpsertSecretMetadataFromFirestoreVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertSecretMetadataFromFirestoreData, UpsertSecretMetadataFromFirestoreVariables> ref() {
    UpsertSecretMetadataFromFirestoreVariables vars= UpsertSecretMetadataFromFirestoreVariables(id: id,name: name,teamId: teamId,pathToSecret: _pathToSecret,);
    return _dataConnect.mutation("UpsertSecretMetadataFromFirestore", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertSecretMetadataFromFirestoreSecretUpsert {
  final String id;
  UpsertSecretMetadataFromFirestoreSecretUpsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertSecretMetadataFromFirestoreSecretUpsert otherTyped = other as UpsertSecretMetadataFromFirestoreSecretUpsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpsertSecretMetadataFromFirestoreSecretUpsert({
    required this.id,
  });
}

@immutable
class UpsertSecretMetadataFromFirestoreData {
  final UpsertSecretMetadataFromFirestoreSecretUpsert secret_upsert;
  UpsertSecretMetadataFromFirestoreData.fromJson(dynamic json):
  
  secret_upsert = UpsertSecretMetadataFromFirestoreSecretUpsert.fromJson(json['secret_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertSecretMetadataFromFirestoreData otherTyped = other as UpsertSecretMetadataFromFirestoreData;
    return secret_upsert == otherTyped.secret_upsert;
    
  }
  @override
  int get hashCode => secret_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['secret_upsert'] = secret_upsert.toJson();
    return json;
  }

  UpsertSecretMetadataFromFirestoreData({
    required this.secret_upsert,
  });
}

@immutable
class UpsertSecretMetadataFromFirestoreVariables {
  final String id;
  final String name;
  final String teamId;
  late final Optional<String>pathToSecret;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertSecretMetadataFromFirestoreVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  teamId = nativeFromJson<String>(json['teamId']) {
  
  
  
  
  
    pathToSecret = Optional.optional(nativeFromJson, nativeToJson);
    pathToSecret.value = json['pathToSecret'] == null ? null : nativeFromJson<String>(json['pathToSecret']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertSecretMetadataFromFirestoreVariables otherTyped = other as UpsertSecretMetadataFromFirestoreVariables;
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
    if(pathToSecret.state == OptionalState.set) {
      json['pathToSecret'] = pathToSecret.toJson();
    }
    return json;
  }

  UpsertSecretMetadataFromFirestoreVariables({
    required this.id,
    required this.name,
    required this.teamId,
    required this.pathToSecret,
  });
}

