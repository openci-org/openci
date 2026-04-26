part of 'default.dart';

class UpsertInvitationFromFirestoreVariablesBuilder {
  String id;
  String email;
  String teamId;
  String teamNameSnapshot;
  String token;
  InvitationStatus status;
  Timestamp expiresAt;
  Optional<String> _invitedById = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _acceptedById = Optional.optional(nativeFromJson, nativeToJson);
  Optional<Timestamp> _acceptedAt = Optional.optional((json) => json['acceptedAt'] = Timestamp.fromJson(json['acceptedAt']), defaultSerializer);

  final FirebaseDataConnect _dataConnect;  UpsertInvitationFromFirestoreVariablesBuilder invitedById(String? t) {
   _invitedById.value = t;
   return this;
  }
  UpsertInvitationFromFirestoreVariablesBuilder acceptedById(String? t) {
   _acceptedById.value = t;
   return this;
  }
  UpsertInvitationFromFirestoreVariablesBuilder acceptedAt(Timestamp? t) {
   _acceptedAt.value = t;
   return this;
  }

  UpsertInvitationFromFirestoreVariablesBuilder(this._dataConnect, {required  this.id,required  this.email,required  this.teamId,required  this.teamNameSnapshot,required  this.token,required  this.status,required  this.expiresAt,});
  Deserializer<UpsertInvitationFromFirestoreData> dataDeserializer = (dynamic json)  => UpsertInvitationFromFirestoreData.fromJson(jsonDecode(json));
  Serializer<UpsertInvitationFromFirestoreVariables> varsSerializer = (UpsertInvitationFromFirestoreVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertInvitationFromFirestoreData, UpsertInvitationFromFirestoreVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertInvitationFromFirestoreData, UpsertInvitationFromFirestoreVariables> ref() {
    UpsertInvitationFromFirestoreVariables vars= UpsertInvitationFromFirestoreVariables(id: id,email: email,teamId: teamId,teamNameSnapshot: teamNameSnapshot,token: token,status: status,expiresAt: expiresAt,invitedById: _invitedById,acceptedById: _acceptedById,acceptedAt: _acceptedAt,);
    return _dataConnect.mutation("UpsertInvitationFromFirestore", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertInvitationFromFirestoreInvitationUpsert {
  final String id;
  UpsertInvitationFromFirestoreInvitationUpsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertInvitationFromFirestoreInvitationUpsert otherTyped = other as UpsertInvitationFromFirestoreInvitationUpsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpsertInvitationFromFirestoreInvitationUpsert({
    required this.id,
  });
}

@immutable
class UpsertInvitationFromFirestoreData {
  final UpsertInvitationFromFirestoreInvitationUpsert invitation_upsert;
  UpsertInvitationFromFirestoreData.fromJson(dynamic json):
  
  invitation_upsert = UpsertInvitationFromFirestoreInvitationUpsert.fromJson(json['invitation_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertInvitationFromFirestoreData otherTyped = other as UpsertInvitationFromFirestoreData;
    return invitation_upsert == otherTyped.invitation_upsert;
    
  }
  @override
  int get hashCode => invitation_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['invitation_upsert'] = invitation_upsert.toJson();
    return json;
  }

  UpsertInvitationFromFirestoreData({
    required this.invitation_upsert,
  });
}

@immutable
class UpsertInvitationFromFirestoreVariables {
  final String id;
  final String email;
  final String teamId;
  final String teamNameSnapshot;
  final String token;
  final InvitationStatus status;
  final Timestamp expiresAt;
  late final Optional<String>invitedById;
  late final Optional<String>acceptedById;
  late final Optional<Timestamp>acceptedAt;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertInvitationFromFirestoreVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  email = nativeFromJson<String>(json['email']),
  teamId = nativeFromJson<String>(json['teamId']),
  teamNameSnapshot = nativeFromJson<String>(json['teamNameSnapshot']),
  token = nativeFromJson<String>(json['token']),
  status = InvitationStatus.values.byName(json['status']),
  expiresAt = Timestamp.fromJson(json['expiresAt']) {
  
  
  
  
  
  
  
  
  
    invitedById = Optional.optional(nativeFromJson, nativeToJson);
    invitedById.value = json['invitedById'] == null ? null : nativeFromJson<String>(json['invitedById']);
  
  
    acceptedById = Optional.optional(nativeFromJson, nativeToJson);
    acceptedById.value = json['acceptedById'] == null ? null : nativeFromJson<String>(json['acceptedById']);
  
  
    acceptedAt = Optional.optional((json) => json['acceptedAt'] = Timestamp.fromJson(json['acceptedAt']), defaultSerializer);
    acceptedAt.value = json['acceptedAt'] == null ? null : Timestamp.fromJson(json['acceptedAt']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertInvitationFromFirestoreVariables otherTyped = other as UpsertInvitationFromFirestoreVariables;
    return id == otherTyped.id && 
    email == otherTyped.email && 
    teamId == otherTyped.teamId && 
    teamNameSnapshot == otherTyped.teamNameSnapshot && 
    token == otherTyped.token && 
    status == otherTyped.status && 
    expiresAt == otherTyped.expiresAt && 
    invitedById == otherTyped.invitedById && 
    acceptedById == otherTyped.acceptedById && 
    acceptedAt == otherTyped.acceptedAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, email.hashCode, teamId.hashCode, teamNameSnapshot.hashCode, token.hashCode, status.hashCode, expiresAt.hashCode, invitedById.hashCode, acceptedById.hashCode, acceptedAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['email'] = nativeToJson<String>(email);
    json['teamId'] = nativeToJson<String>(teamId);
    json['teamNameSnapshot'] = nativeToJson<String>(teamNameSnapshot);
    json['token'] = nativeToJson<String>(token);
    json['status'] = 
    status.name
    ;
    json['expiresAt'] = expiresAt.toJson();
    if(invitedById.state == OptionalState.set) {
      json['invitedById'] = invitedById.toJson();
    }
    if(acceptedById.state == OptionalState.set) {
      json['acceptedById'] = acceptedById.toJson();
    }
    if(acceptedAt.state == OptionalState.set) {
      json['acceptedAt'] = acceptedAt.toJson();
    }
    return json;
  }

  UpsertInvitationFromFirestoreVariables({
    required this.id,
    required this.email,
    required this.teamId,
    required this.teamNameSnapshot,
    required this.token,
    required this.status,
    required this.expiresAt,
    required this.invitedById,
    required this.acceptedById,
    required this.acceptedAt,
  });
}

