part of 'default.dart';

class UpdateUserFcmTokensVariablesBuilder {
  String id;
  List<String> fcmTokens;

  final FirebaseDataConnect _dataConnect;
  UpdateUserFcmTokensVariablesBuilder(this._dataConnect, {required  this.id,required  this.fcmTokens,});
  Deserializer<UpdateUserFcmTokensData> dataDeserializer = (dynamic json)  => UpdateUserFcmTokensData.fromJson(jsonDecode(json));
  Serializer<UpdateUserFcmTokensVariables> varsSerializer = (UpdateUserFcmTokensVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateUserFcmTokensData, UpdateUserFcmTokensVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateUserFcmTokensData, UpdateUserFcmTokensVariables> ref() {
    UpdateUserFcmTokensVariables vars= UpdateUserFcmTokensVariables(id: id,fcmTokens: fcmTokens,);
    return _dataConnect.mutation("UpdateUserFcmTokens", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateUserFcmTokensUserUpdate {
  final String id;
  UpdateUserFcmTokensUserUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateUserFcmTokensUserUpdate otherTyped = other as UpdateUserFcmTokensUserUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateUserFcmTokensUserUpdate({
    required this.id,
  });
}

@immutable
class UpdateUserFcmTokensData {
  final UpdateUserFcmTokensUserUpdate? user_update;
  UpdateUserFcmTokensData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdateUserFcmTokensUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateUserFcmTokensData otherTyped = other as UpdateUserFcmTokensData;
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

  UpdateUserFcmTokensData({
    this.user_update,
  });
}

@immutable
class UpdateUserFcmTokensVariables {
  final String id;
  final List<String> fcmTokens;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateUserFcmTokensVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  fcmTokens = (json['fcmTokens'] as List<dynamic>)
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

    final UpdateUserFcmTokensVariables otherTyped = other as UpdateUserFcmTokensVariables;
    return id == otherTyped.id && 
    fcmTokens == otherTyped.fcmTokens;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, fcmTokens.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['fcmTokens'] = fcmTokens.map((e) => nativeToJson<String>(e)).toList();
    return json;
  }

  UpdateUserFcmTokensVariables({
    required this.id,
    required this.fcmTokens,
  });
}

