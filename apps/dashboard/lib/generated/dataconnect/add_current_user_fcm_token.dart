part of 'default.dart';

class AddCurrentUserFcmTokenVariablesBuilder {
  String token;

  final FirebaseDataConnect _dataConnect;
  AddCurrentUserFcmTokenVariablesBuilder(this._dataConnect, {required  this.token,});
  Deserializer<AddCurrentUserFcmTokenData> dataDeserializer = (dynamic json)  => AddCurrentUserFcmTokenData.fromJson(jsonDecode(json));
  Serializer<AddCurrentUserFcmTokenVariables> varsSerializer = (AddCurrentUserFcmTokenVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<AddCurrentUserFcmTokenData, AddCurrentUserFcmTokenVariables>> execute() {
    return ref().execute();
  }

  MutationRef<AddCurrentUserFcmTokenData, AddCurrentUserFcmTokenVariables> ref() {
    AddCurrentUserFcmTokenVariables vars= AddCurrentUserFcmTokenVariables(token: token,);
    return _dataConnect.mutation("AddCurrentUserFcmToken", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class AddCurrentUserFcmTokenUserUpdate {
  final String id;
  AddCurrentUserFcmTokenUserUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddCurrentUserFcmTokenUserUpdate otherTyped = other as AddCurrentUserFcmTokenUserUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  AddCurrentUserFcmTokenUserUpdate({
    required this.id,
  });
}

@immutable
class AddCurrentUserFcmTokenData {
  final AddCurrentUserFcmTokenUserUpdate? user_update;
  AddCurrentUserFcmTokenData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : AddCurrentUserFcmTokenUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddCurrentUserFcmTokenData otherTyped = other as AddCurrentUserFcmTokenData;
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

  AddCurrentUserFcmTokenData({
    this.user_update,
  });
}

@immutable
class AddCurrentUserFcmTokenVariables {
  final String token;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  AddCurrentUserFcmTokenVariables.fromJson(Map<String, dynamic> json):
  
  token = nativeFromJson<String>(json['token']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddCurrentUserFcmTokenVariables otherTyped = other as AddCurrentUserFcmTokenVariables;
    return token == otherTyped.token;
    
  }
  @override
  int get hashCode => token.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['token'] = nativeToJson<String>(token);
    return json;
  }

  AddCurrentUserFcmTokenVariables({
    required this.token,
  });
}

