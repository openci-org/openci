part of 'default.dart';

class UpsertBuildRunFromFirestoreVariablesBuilder {
  String buildJobId;
  String id;

  final FirebaseDataConnect _dataConnect;
  UpsertBuildRunFromFirestoreVariablesBuilder(this._dataConnect, {required  this.buildJobId,required  this.id,});
  Deserializer<UpsertBuildRunFromFirestoreData> dataDeserializer = (dynamic json)  => UpsertBuildRunFromFirestoreData.fromJson(jsonDecode(json));
  Serializer<UpsertBuildRunFromFirestoreVariables> varsSerializer = (UpsertBuildRunFromFirestoreVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertBuildRunFromFirestoreData, UpsertBuildRunFromFirestoreVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertBuildRunFromFirestoreData, UpsertBuildRunFromFirestoreVariables> ref() {
    UpsertBuildRunFromFirestoreVariables vars= UpsertBuildRunFromFirestoreVariables(buildJobId: buildJobId,id: id,);
    return _dataConnect.mutation("UpsertBuildRunFromFirestore", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertBuildRunFromFirestoreBuildRunUpsert {
  final String buildJobId;
  final String id;
  UpsertBuildRunFromFirestoreBuildRunUpsert.fromJson(dynamic json):
  
  buildJobId = nativeFromJson<String>(json['buildJobId']),
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertBuildRunFromFirestoreBuildRunUpsert otherTyped = other as UpsertBuildRunFromFirestoreBuildRunUpsert;
    return buildJobId == otherTyped.buildJobId && 
    id == otherTyped.id;
    
  }
  @override
  int get hashCode => Object.hashAll([buildJobId.hashCode, id.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildJobId'] = nativeToJson<String>(buildJobId);
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpsertBuildRunFromFirestoreBuildRunUpsert({
    required this.buildJobId,
    required this.id,
  });
}

@immutable
class UpsertBuildRunFromFirestoreData {
  final UpsertBuildRunFromFirestoreBuildRunUpsert buildRun_upsert;
  UpsertBuildRunFromFirestoreData.fromJson(dynamic json):
  
  buildRun_upsert = UpsertBuildRunFromFirestoreBuildRunUpsert.fromJson(json['buildRun_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertBuildRunFromFirestoreData otherTyped = other as UpsertBuildRunFromFirestoreData;
    return buildRun_upsert == otherTyped.buildRun_upsert;
    
  }
  @override
  int get hashCode => buildRun_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildRun_upsert'] = buildRun_upsert.toJson();
    return json;
  }

  UpsertBuildRunFromFirestoreData({
    required this.buildRun_upsert,
  });
}

@immutable
class UpsertBuildRunFromFirestoreVariables {
  final String buildJobId;
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertBuildRunFromFirestoreVariables.fromJson(Map<String, dynamic> json):
  
  buildJobId = nativeFromJson<String>(json['buildJobId']),
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertBuildRunFromFirestoreVariables otherTyped = other as UpsertBuildRunFromFirestoreVariables;
    return buildJobId == otherTyped.buildJobId && 
    id == otherTyped.id;
    
  }
  @override
  int get hashCode => Object.hashAll([buildJobId.hashCode, id.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildJobId'] = nativeToJson<String>(buildJobId);
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpsertBuildRunFromFirestoreVariables({
    required this.buildJobId,
    required this.id,
  });
}

