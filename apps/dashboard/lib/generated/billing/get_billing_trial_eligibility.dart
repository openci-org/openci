part of 'billing.dart';

class GetBillingTrialEligibilityVariablesBuilder {
  String teamId;
  String userId;

  final FirebaseDataConnect _dataConnect;
  GetBillingTrialEligibilityVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.userId,
  });
  Deserializer<GetBillingTrialEligibilityData> dataDeserializer =
      (dynamic json) =>
          GetBillingTrialEligibilityData.fromJson(jsonDecode(json));
  Serializer<GetBillingTrialEligibilityVariables> varsSerializer =
      (GetBillingTrialEligibilityVariables vars) => jsonEncode(vars.toJson());
  Future<
    QueryResult<
      GetBillingTrialEligibilityData,
      GetBillingTrialEligibilityVariables
    >
  >
  execute() {
    return ref().execute();
  }

  QueryRef<GetBillingTrialEligibilityData, GetBillingTrialEligibilityVariables>
  ref() {
    GetBillingTrialEligibilityVariables vars =
        GetBillingTrialEligibilityVariables(
          teamId: teamId,
          userId: userId,
        );
    return _dataConnect.query(
      "GetBillingTrialEligibility",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBillingTrialEligibilityUserClaim {
  final String teamId;
  final BigInt claimedAt;
  GetBillingTrialEligibilityUserClaim.fromJson(dynamic json)
    : teamId = nativeFromJson<String>(json['teamId']),
      claimedAt = bigIntFromJson(json['claimedAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingTrialEligibilityUserClaim otherTyped =
        other as GetBillingTrialEligibilityUserClaim;
    return teamId == otherTyped.teamId && claimedAt == otherTyped.claimedAt;
  }

  @override
  int get hashCode => Object.hashAll([teamId.hashCode, claimedAt.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['claimedAt'] = bigIntToJson(claimedAt);
    return json;
  }

  GetBillingTrialEligibilityUserClaim({
    required this.teamId,
    required this.claimedAt,
  });
}

@immutable
class GetBillingTrialEligibilityTeamClaim {
  final String userId;
  final BigInt claimedAt;
  GetBillingTrialEligibilityTeamClaim.fromJson(dynamic json)
    : userId = nativeFromJson<String>(json['userId']),
      claimedAt = bigIntFromJson(json['claimedAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingTrialEligibilityTeamClaim otherTyped =
        other as GetBillingTrialEligibilityTeamClaim;
    return userId == otherTyped.userId && claimedAt == otherTyped.claimedAt;
  }

  @override
  int get hashCode => Object.hashAll([userId.hashCode, claimedAt.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    json['claimedAt'] = bigIntToJson(claimedAt);
    return json;
  }

  GetBillingTrialEligibilityTeamClaim({
    required this.userId,
    required this.claimedAt,
  });
}

@immutable
class GetBillingTrialEligibilityActivePaidPeriod {
  final String id;
  GetBillingTrialEligibilityActivePaidPeriod.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingTrialEligibilityActivePaidPeriod otherTyped =
        other as GetBillingTrialEligibilityActivePaidPeriod;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetBillingTrialEligibilityActivePaidPeriod({
    required this.id,
  });
}

@immutable
class GetBillingTrialEligibilityData {
  final GetBillingTrialEligibilityUserClaim? userClaim;
  final GetBillingTrialEligibilityTeamClaim? teamClaim;
  final GetBillingTrialEligibilityActivePaidPeriod? activePaidPeriod;
  GetBillingTrialEligibilityData.fromJson(dynamic json)
    : userClaim = json['userClaim'] == null
          ? null
          : GetBillingTrialEligibilityUserClaim.fromJson(json['userClaim']),
      teamClaim = json['teamClaim'] == null
          ? null
          : GetBillingTrialEligibilityTeamClaim.fromJson(json['teamClaim']),
      activePaidPeriod = json['activePaidPeriod'] == null
          ? null
          : GetBillingTrialEligibilityActivePaidPeriod.fromJson(
              json['activePaidPeriod'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingTrialEligibilityData otherTyped =
        other as GetBillingTrialEligibilityData;
    return userClaim == otherTyped.userClaim &&
        teamClaim == otherTyped.teamClaim &&
        activePaidPeriod == otherTyped.activePaidPeriod;
  }

  @override
  int get hashCode => Object.hashAll([
    userClaim.hashCode,
    teamClaim.hashCode,
    activePaidPeriod.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (userClaim != null) {
      json['userClaim'] = userClaim!.toJson();
    }
    if (teamClaim != null) {
      json['teamClaim'] = teamClaim!.toJson();
    }
    if (activePaidPeriod != null) {
      json['activePaidPeriod'] = activePaidPeriod!.toJson();
    }
    return json;
  }

  GetBillingTrialEligibilityData({
    this.userClaim,
    this.teamClaim,
    this.activePaidPeriod,
  });
}

@immutable
class GetBillingTrialEligibilityVariables {
  final String teamId;
  final String userId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBillingTrialEligibilityVariables.fromJson(Map<String, dynamic> json)
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

    final GetBillingTrialEligibilityVariables otherTyped =
        other as GetBillingTrialEligibilityVariables;
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

  GetBillingTrialEligibilityVariables({
    required this.teamId,
    required this.userId,
  });
}
