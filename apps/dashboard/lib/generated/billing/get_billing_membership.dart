part of 'billing.dart';

class GetBillingMembershipVariablesBuilder {
  String teamId;
  String userId;

  final FirebaseDataConnect _dataConnect;
  GetBillingMembershipVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.userId,
  });
  Deserializer<GetBillingMembershipData> dataDeserializer = (dynamic json) =>
      GetBillingMembershipData.fromJson(jsonDecode(json));
  Serializer<GetBillingMembershipVariables> varsSerializer =
      (GetBillingMembershipVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetBillingMembershipData, GetBillingMembershipVariables>>
  execute() {
    return ref().execute();
  }

  QueryRef<GetBillingMembershipData, GetBillingMembershipVariables> ref() {
    GetBillingMembershipVariables vars = GetBillingMembershipVariables(
      teamId: teamId,
      userId: userId,
    );
    return _dataConnect.query(
      "GetBillingMembership",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBillingMembershipMember {
  final BigInt id;
  GetBillingMembershipMember.fromJson(dynamic json)
    : id = bigIntFromJson(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingMembershipMember otherTyped =
        other as GetBillingMembershipMember;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = bigIntToJson(id);
    return json;
  }

  GetBillingMembershipMember({
    required this.id,
  });
}

@immutable
class GetBillingMembershipData {
  final GetBillingMembershipMember? member;
  GetBillingMembershipData.fromJson(dynamic json)
    : member = json['member'] == null
          ? null
          : GetBillingMembershipMember.fromJson(json['member']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingMembershipData otherTyped =
        other as GetBillingMembershipData;
    return member == otherTyped.member;
  }

  @override
  int get hashCode => member.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (member != null) {
      json['member'] = member!.toJson();
    }
    return json;
  }

  GetBillingMembershipData({
    this.member,
  });
}

@immutable
class GetBillingMembershipVariables {
  final String teamId;
  final String userId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBillingMembershipVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingMembershipVariables otherTyped =
        other as GetBillingMembershipVariables;
    return teamId == otherTyped.teamId && userId == otherTyped.userId;
  }

  @override
  int get hashCode => Object.hashAll([teamId.hashCode, userId.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  GetBillingMembershipVariables({
    required this.teamId,
    required this.userId,
  });
}
