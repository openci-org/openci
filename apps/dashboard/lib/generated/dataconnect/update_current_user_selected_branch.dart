part of 'default.dart';

class UpdateCurrentUserSelectedBranchVariablesBuilder {
  String branch;

  final FirebaseDataConnect _dataConnect;
  UpdateCurrentUserSelectedBranchVariablesBuilder(this._dataConnect, {required  this.branch,});
  Deserializer<UpdateCurrentUserSelectedBranchData> dataDeserializer = (dynamic json)  => UpdateCurrentUserSelectedBranchData.fromJson(jsonDecode(json));
  Serializer<UpdateCurrentUserSelectedBranchVariables> varsSerializer = (UpdateCurrentUserSelectedBranchVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateCurrentUserSelectedBranchData, UpdateCurrentUserSelectedBranchVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateCurrentUserSelectedBranchData, UpdateCurrentUserSelectedBranchVariables> ref() {
    UpdateCurrentUserSelectedBranchVariables vars= UpdateCurrentUserSelectedBranchVariables(branch: branch,);
    return _dataConnect.mutation("UpdateCurrentUserSelectedBranch", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateCurrentUserSelectedBranchUserUpdate {
  final String id;
  UpdateCurrentUserSelectedBranchUserUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserSelectedBranchUserUpdate otherTyped = other as UpdateCurrentUserSelectedBranchUserUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateCurrentUserSelectedBranchUserUpdate({
    required this.id,
  });
}

@immutable
class UpdateCurrentUserSelectedBranchData {
  final UpdateCurrentUserSelectedBranchUserUpdate? user_update;
  UpdateCurrentUserSelectedBranchData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdateCurrentUserSelectedBranchUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserSelectedBranchData otherTyped = other as UpdateCurrentUserSelectedBranchData;
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

  UpdateCurrentUserSelectedBranchData({
    this.user_update,
  });
}

@immutable
class UpdateCurrentUserSelectedBranchVariables {
  final String branch;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateCurrentUserSelectedBranchVariables.fromJson(Map<String, dynamic> json):
  
  branch = nativeFromJson<String>(json['branch']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserSelectedBranchVariables otherTyped = other as UpdateCurrentUserSelectedBranchVariables;
    return branch == otherTyped.branch;
    
  }
  @override
  int get hashCode => branch.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['branch'] = nativeToJson<String>(branch);
    return json;
  }

  UpdateCurrentUserSelectedBranchVariables({
    required this.branch,
  });
}

