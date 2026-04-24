part of 'default.dart';

class AcceptInvitationVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  AcceptInvitationVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<AcceptInvitationData> dataDeserializer = (dynamic json)  => AcceptInvitationData.fromJson(jsonDecode(json));
  Serializer<AcceptInvitationVariables> varsSerializer = (AcceptInvitationVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<AcceptInvitationData, AcceptInvitationVariables>> execute() {
    return ref().execute();
  }

  MutationRef<AcceptInvitationData, AcceptInvitationVariables> ref() {
    AcceptInvitationVariables vars= AcceptInvitationVariables(id: id,);
    return _dataConnect.mutation("AcceptInvitation", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class AcceptInvitationInvitationUpdate {
  final String id;
  AcceptInvitationInvitationUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AcceptInvitationInvitationUpdate otherTyped = other as AcceptInvitationInvitationUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  AcceptInvitationInvitationUpdate({
    required this.id,
  });
}

@immutable
class AcceptInvitationData {
  final AcceptInvitationInvitationUpdate? invitation_update;
  AcceptInvitationData.fromJson(dynamic json):
  
  invitation_update = json['invitation_update'] == null ? null : AcceptInvitationInvitationUpdate.fromJson(json['invitation_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AcceptInvitationData otherTyped = other as AcceptInvitationData;
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

  AcceptInvitationData({
    this.invitation_update,
  });
}

@immutable
class AcceptInvitationVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  AcceptInvitationVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AcceptInvitationVariables otherTyped = other as AcceptInvitationVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  AcceptInvitationVariables({
    required this.id,
  });
}

