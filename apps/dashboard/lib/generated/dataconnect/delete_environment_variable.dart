part of 'default.dart';

class DeleteEnvironmentVariableVariablesBuilder {
  String id;
  String teamId;

  final FirebaseDataConnect _dataConnect;
  DeleteEnvironmentVariableVariablesBuilder(this._dataConnect, {required  this.id,required  this.teamId,});
  Deserializer<DeleteEnvironmentVariableData> dataDeserializer = (dynamic json)  => DeleteEnvironmentVariableData.fromJson(jsonDecode(json));
  Serializer<DeleteEnvironmentVariableVariables> varsSerializer = (DeleteEnvironmentVariableVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteEnvironmentVariableData, DeleteEnvironmentVariableVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteEnvironmentVariableData, DeleteEnvironmentVariableVariables> ref() {
    DeleteEnvironmentVariableVariables vars= DeleteEnvironmentVariableVariables(id: id,teamId: teamId,);
    return _dataConnect.mutation("DeleteEnvironmentVariable", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteEnvironmentVariableEnvironmentVariableDelete {
  final String id;
  DeleteEnvironmentVariableEnvironmentVariableDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteEnvironmentVariableEnvironmentVariableDelete otherTyped = other as DeleteEnvironmentVariableEnvironmentVariableDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteEnvironmentVariableEnvironmentVariableDelete({
    required this.id,
  });
}

@immutable
class DeleteEnvironmentVariableData {
  final DeleteEnvironmentVariableEnvironmentVariableDelete? environmentVariable_delete;
  DeleteEnvironmentVariableData.fromJson(dynamic json):
  
  environmentVariable_delete = json['environmentVariable_delete'] == null ? null : DeleteEnvironmentVariableEnvironmentVariableDelete.fromJson(json['environmentVariable_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteEnvironmentVariableData otherTyped = other as DeleteEnvironmentVariableData;
    return environmentVariable_delete == otherTyped.environmentVariable_delete;
    
  }
  @override
  int get hashCode => environmentVariable_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (environmentVariable_delete != null) {
      json['environmentVariable_delete'] = environmentVariable_delete!.toJson();
    }
    return json;
  }

  DeleteEnvironmentVariableData({
    this.environmentVariable_delete,
  });
}

@immutable
class DeleteEnvironmentVariableVariables {
  final String id;
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteEnvironmentVariableVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteEnvironmentVariableVariables otherTyped = other as DeleteEnvironmentVariableVariables;
    return id == otherTyped.id && 
    teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, teamId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  DeleteEnvironmentVariableVariables({
    required this.id,
    required this.teamId,
  });
}

