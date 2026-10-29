part of 'billing.dart';

class DeleteBillingTeamVariablesBuilder {
  String teamId;
  String userId;
  bool livemode;
  Optional<String> _expectedCustomerCreationKey = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<String> _expectedStripeCustomerId = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<BigInt> _expectedStripeRevision = Optional.optional(
    bigIntFromJson,
    bigIntToJson,
  );

  final FirebaseDataConnect _dataConnect;
  DeleteBillingTeamVariablesBuilder expectedCustomerCreationKey(String? t) {
    _expectedCustomerCreationKey.value = t;
    return this;
  }

  DeleteBillingTeamVariablesBuilder expectedStripeCustomerId(String? t) {
    _expectedStripeCustomerId.value = t;
    return this;
  }

  DeleteBillingTeamVariablesBuilder expectedStripeRevision(BigInt? t) {
    _expectedStripeRevision.value = t;
    return this;
  }

  DeleteBillingTeamVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.userId,
    required this.livemode,
  });
  Deserializer<DeleteBillingTeamData> dataDeserializer = (dynamic json) =>
      DeleteBillingTeamData.fromJson(jsonDecode(json));
  Serializer<DeleteBillingTeamVariables> varsSerializer =
      (DeleteBillingTeamVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteBillingTeamData, DeleteBillingTeamVariables>>
  execute() {
    return ref().execute();
  }

  MutationRef<DeleteBillingTeamData, DeleteBillingTeamVariables> ref() {
    DeleteBillingTeamVariables vars = DeleteBillingTeamVariables(
      teamId: teamId,
      userId: userId,
      livemode: livemode,
      expectedCustomerCreationKey: _expectedCustomerCreationKey,
      expectedStripeCustomerId: _expectedStripeCustomerId,
      expectedStripeRevision: _expectedStripeRevision,
    );
    return _dataConnect.mutation(
      "DeleteBillingTeam",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class DeleteBillingTeamBillingAccountUpsert {
  final String teamId;
  DeleteBillingTeamBillingAccountUpsert.fromJson(dynamic json)
    : teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteBillingTeamBillingAccountUpsert otherTyped =
        other as DeleteBillingTeamBillingAccountUpsert;
    return teamId == otherTyped.teamId;
  }

  @override
  int get hashCode => teamId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  DeleteBillingTeamBillingAccountUpsert({
    required this.teamId,
  });
}

@immutable
class DeleteBillingTeamCleanup {
  final List<DeleteBillingTeamCleanupSecrets> secrets;
  final List<DeleteBillingTeamCleanupRequests> requests;
  final List<DeleteBillingTeamCleanupSessions> sessions;
  DeleteBillingTeamCleanup.fromJson(dynamic json)
    : secrets = (json['secrets'] as List<dynamic>)
          .map((e) => DeleteBillingTeamCleanupSecrets.fromJson(e))
          .toList(),
      requests = (json['requests'] as List<dynamic>)
          .map((e) => DeleteBillingTeamCleanupRequests.fromJson(e))
          .toList(),
      sessions = (json['sessions'] as List<dynamic>)
          .map((e) => DeleteBillingTeamCleanupSessions.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteBillingTeamCleanup otherTyped =
        other as DeleteBillingTeamCleanup;
    return secrets == otherTyped.secrets &&
        requests == otherTyped.requests &&
        sessions == otherTyped.sessions;
  }

  @override
  int get hashCode =>
      Object.hashAll([secrets.hashCode, requests.hashCode, sessions.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['secrets'] = secrets.map((e) => e.toJson()).toList();
    json['requests'] = requests.map((e) => e.toJson()).toList();
    json['sessions'] = sessions.map((e) => e.toJson()).toList();
    return json;
  }

  DeleteBillingTeamCleanup({
    required this.secrets,
    required this.requests,
    required this.sessions,
  });
}

@immutable
class DeleteBillingTeamCleanupSecrets {
  final String secretVersionPath;
  DeleteBillingTeamCleanupSecrets.fromJson(dynamic json)
    : secretVersionPath = nativeFromJson<String>(json['secretVersionPath']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteBillingTeamCleanupSecrets otherTyped =
        other as DeleteBillingTeamCleanupSecrets;
    return secretVersionPath == otherTyped.secretVersionPath;
  }

  @override
  int get hashCode => secretVersionPath.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['secretVersionPath'] = nativeToJson<String>(secretVersionPath);
    return json;
  }

  DeleteBillingTeamCleanupSecrets({
    required this.secretVersionPath,
  });
}

@immutable
class DeleteBillingTeamCleanupRequests {
  final String codeVerifierSecretVersionPath;
  DeleteBillingTeamCleanupRequests.fromJson(dynamic json)
    : codeVerifierSecretVersionPath = nativeFromJson<String>(
        json['codeVerifierSecretVersionPath'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteBillingTeamCleanupRequests otherTyped =
        other as DeleteBillingTeamCleanupRequests;
    return codeVerifierSecretVersionPath ==
        otherTyped.codeVerifierSecretVersionPath;
  }

  @override
  int get hashCode => codeVerifierSecretVersionPath.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['codeVerifierSecretVersionPath'] = nativeToJson<String>(
      codeVerifierSecretVersionPath,
    );
    return json;
  }

  DeleteBillingTeamCleanupRequests({
    required this.codeVerifierSecretVersionPath,
  });
}

@immutable
class DeleteBillingTeamCleanupSessions {
  final String? accessTokenSecretVersionPath;
  DeleteBillingTeamCleanupSessions.fromJson(dynamic json)
    : accessTokenSecretVersionPath =
          json['accessTokenSecretVersionPath'] == null
          ? null
          : nativeFromJson<String>(json['accessTokenSecretVersionPath']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteBillingTeamCleanupSessions otherTyped =
        other as DeleteBillingTeamCleanupSessions;
    return accessTokenSecretVersionPath ==
        otherTyped.accessTokenSecretVersionPath;
  }

  @override
  int get hashCode => accessTokenSecretVersionPath.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (accessTokenSecretVersionPath != null) {
      json['accessTokenSecretVersionPath'] = nativeToJson<String?>(
        accessTokenSecretVersionPath,
      );
    }
    return json;
  }

  DeleteBillingTeamCleanupSessions({
    this.accessTokenSecretVersionPath,
  });
}

@immutable
class DeleteBillingTeamTeamDelete {
  final String id;
  DeleteBillingTeamTeamDelete.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteBillingTeamTeamDelete otherTyped =
        other as DeleteBillingTeamTeamDelete;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteBillingTeamTeamDelete({
    required this.id,
  });
}

@immutable
class DeleteBillingTeamData {
  final DeleteBillingTeamBillingAccountUpsert billingAccount_upsert;
  final DeleteBillingTeamCleanup? cleanup;
  final DeleteBillingTeamTeamDelete? team_delete;
  DeleteBillingTeamData.fromJson(dynamic json)
    : billingAccount_upsert = DeleteBillingTeamBillingAccountUpsert.fromJson(
        json['billingAccount_upsert'],
      ),
      cleanup = json['cleanup'] == null
          ? null
          : DeleteBillingTeamCleanup.fromJson(json['cleanup']),
      team_delete = json['team_delete'] == null
          ? null
          : DeleteBillingTeamTeamDelete.fromJson(json['team_delete']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteBillingTeamData otherTyped = other as DeleteBillingTeamData;
    return billingAccount_upsert == otherTyped.billingAccount_upsert &&
        cleanup == otherTyped.cleanup &&
        team_delete == otherTyped.team_delete;
  }

  @override
  int get hashCode => Object.hashAll([
    billingAccount_upsert.hashCode,
    cleanup.hashCode,
    team_delete.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['billingAccount_upsert'] = billingAccount_upsert.toJson();
    if (cleanup != null) {
      json['cleanup'] = cleanup!.toJson();
    }
    if (team_delete != null) {
      json['team_delete'] = team_delete!.toJson();
    }
    return json;
  }

  DeleteBillingTeamData({
    required this.billingAccount_upsert,
    this.cleanup,
    this.team_delete,
  });
}

@immutable
class DeleteBillingTeamVariables {
  final String teamId;
  final String userId;
  final bool livemode;
  late final Optional<String> expectedCustomerCreationKey;
  late final Optional<String> expectedStripeCustomerId;
  late final Optional<BigInt> expectedStripeRevision;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  DeleteBillingTeamVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      userId = nativeFromJson<String>(json['userId']),
      livemode = nativeFromJson<bool>(json['livemode']) {
    expectedCustomerCreationKey = Optional.optional(
      nativeFromJson,
      nativeToJson,
    );
    expectedCustomerCreationKey.value =
        json['expectedCustomerCreationKey'] == null
        ? null
        : nativeFromJson<String>(json['expectedCustomerCreationKey']);

    expectedStripeCustomerId = Optional.optional(nativeFromJson, nativeToJson);
    expectedStripeCustomerId.value = json['expectedStripeCustomerId'] == null
        ? null
        : nativeFromJson<String>(json['expectedStripeCustomerId']);

    expectedStripeRevision = Optional.optional(bigIntFromJson, bigIntToJson);
    expectedStripeRevision.value = json['expectedStripeRevision'] == null
        ? null
        : bigIntFromJson(json['expectedStripeRevision']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteBillingTeamVariables otherTyped =
        other as DeleteBillingTeamVariables;
    return teamId == otherTyped.teamId &&
        userId == otherTyped.userId &&
        livemode == otherTyped.livemode &&
        expectedCustomerCreationKey == otherTyped.expectedCustomerCreationKey &&
        expectedStripeCustomerId == otherTyped.expectedStripeCustomerId &&
        expectedStripeRevision == otherTyped.expectedStripeRevision;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    userId.hashCode,
    livemode.hashCode,
    expectedCustomerCreationKey.hashCode,
    expectedStripeCustomerId.hashCode,
    expectedStripeRevision.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['userId'] = nativeToJson<String>(userId);
    json['livemode'] = nativeToJson<bool>(livemode);
    if (expectedCustomerCreationKey.state == OptionalState.set) {
      json['expectedCustomerCreationKey'] = expectedCustomerCreationKey
          .toJson();
    }
    if (expectedStripeCustomerId.state == OptionalState.set) {
      json['expectedStripeCustomerId'] = expectedStripeCustomerId.toJson();
    }
    if (expectedStripeRevision.state == OptionalState.set) {
      json['expectedStripeRevision'] = expectedStripeRevision.toJson();
    }
    return json;
  }

  DeleteBillingTeamVariables({
    required this.teamId,
    required this.userId,
    required this.livemode,
    required this.expectedCustomerCreationKey,
    required this.expectedStripeCustomerId,
    required this.expectedStripeRevision,
  });
}
