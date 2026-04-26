part of 'default.dart';

class UpdateCurrentUserRepositorySelectionVariablesBuilder {
  String repository;
  String branch;

  final FirebaseDataConnect _dataConnect;
  UpdateCurrentUserRepositorySelectionVariablesBuilder(this._dataConnect, {required  this.repository,required  this.branch,});
  Deserializer<UpdateCurrentUserRepositorySelectionData> dataDeserializer = (dynamic json)  => UpdateCurrentUserRepositorySelectionData.fromJson(jsonDecode(json));
  Serializer<UpdateCurrentUserRepositorySelectionVariables> varsSerializer = (UpdateCurrentUserRepositorySelectionVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateCurrentUserRepositorySelectionData, UpdateCurrentUserRepositorySelectionVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateCurrentUserRepositorySelectionData, UpdateCurrentUserRepositorySelectionVariables> ref() {
    UpdateCurrentUserRepositorySelectionVariables vars= UpdateCurrentUserRepositorySelectionVariables(repository: repository,branch: branch,);
    return _dataConnect.mutation("UpdateCurrentUserRepositorySelection", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateCurrentUserRepositorySelectionUserUpdate {
  final String id;
  UpdateCurrentUserRepositorySelectionUserUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserRepositorySelectionUserUpdate otherTyped = other as UpdateCurrentUserRepositorySelectionUserUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateCurrentUserRepositorySelectionUserUpdate({
    required this.id,
  });
}

@immutable
class UpdateCurrentUserRepositorySelectionData {
  final UpdateCurrentUserRepositorySelectionUserUpdate? user_update;
  UpdateCurrentUserRepositorySelectionData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdateCurrentUserRepositorySelectionUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserRepositorySelectionData otherTyped = other as UpdateCurrentUserRepositorySelectionData;
    return user_update == otherTyped.user_update;
    
  }
  @override
  int get hashCode => user_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_update != null) {
      json['user_update'] = user_update!.toJson();
    }
    return json;
  }

  UpdateCurrentUserRepositorySelectionData({
    this.user_update,
  });
}

@immutable
class UpdateCurrentUserRepositorySelectionVariables {
  final String repository;
  final String branch;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateCurrentUserRepositorySelectionVariables.fromJson(Map<String, dynamic> json):
  
  repository = nativeFromJson<String>(json['repository']),
  branch = nativeFromJson<String>(json['branch']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserRepositorySelectionVariables otherTyped = other as UpdateCurrentUserRepositorySelectionVariables;
    return repository == otherTyped.repository && 
    branch == otherTyped.branch;
    
  }
  @override
  int get hashCode => Object.hashAll([repository.hashCode, branch.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['repository'] = nativeToJson<String>(repository);
    json['branch'] = nativeToJson<String>(branch);
    return json;
  }

  UpdateCurrentUserRepositorySelectionVariables({
    required this.repository,
    required this.branch,
  });
}

