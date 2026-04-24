part of 'default.dart';

class ExpireInvitationVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  ExpireInvitationVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<ExpireInvitationData> dataDeserializer = (dynamic json)  => ExpireInvitationData.fromJson(jsonDecode(json));
  Serializer<ExpireInvitationVariables> varsSerializer = (ExpireInvitationVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<ExpireInvitationData, ExpireInvitationVariables>> execute() {
    return ref().execute();
  }

  MutationRef<ExpireInvitationData, ExpireInvitationVariables> ref() {
    ExpireInvitationVariables vars= ExpireInvitationVariables(id: id,);
    return _dataConnect.mutation("ExpireInvitation", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ExpireInvitationInvitationUpdate {
  final String id;
  ExpireInvitationInvitationUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ExpireInvitationInvitationUpdate otherTyped = other as ExpireInvitationInvitationUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  ExpireInvitationInvitationUpdate({
    required this.id,
  });
}

@immutable
class ExpireInvitationData {
  final ExpireInvitationInvitationUpdate? invitation_update;
  ExpireInvitationData.fromJson(dynamic json):
  
  invitation_update = json['invitation_update'] == null ? null : ExpireInvitationInvitationUpdate.fromJson(json['invitation_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ExpireInvitationData otherTyped = other as ExpireInvitationData;
    return invitation_update == otherTyped.invitation_update;
    
  }
  @override
  int get hashCode => invitation_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (invitation_update != null) {
      json['invitation_update'] = invitation_update!.toJson();
    }
    return json;
  }

  ExpireInvitationData({
    this.invitation_update,
  });
}

@immutable
class ExpireInvitationVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ExpireInvitationVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ExpireInvitationVariables otherTyped = other as ExpireInvitationVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  ExpireInvitationVariables({
    required this.id,
  });
}

