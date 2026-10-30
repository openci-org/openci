part of 'billing.dart';

class GetDueBillingTeamDeletionsVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  GetDueBillingTeamDeletionsVariablesBuilder(
    this._dataConnect,
  );
  Deserializer<GetDueBillingTeamDeletionsData> dataDeserializer =
      (dynamic json) =>
          GetDueBillingTeamDeletionsData.fromJson(jsonDecode(json));

  Future<QueryResult<GetDueBillingTeamDeletionsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetDueBillingTeamDeletionsData, void> ref() {
    return _dataConnect.query(
      "GetDueBillingTeamDeletions",
      dataDeserializer,
      emptySerializer,
      null,
    );
  }
}

@immutable
class GetDueBillingTeamDeletionsDeletions {
  final String teamId;
  final AnyValue secretPaths;
  final AnyValue githubPaths;
  GetDueBillingTeamDeletionsDeletions.fromJson(dynamic json)
    : teamId = nativeFromJson<String>(json['teamId']),
      secretPaths = AnyValue.fromJson(json['secretPaths']),
      githubPaths = AnyValue.fromJson(json['githubPaths']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetDueBillingTeamDeletionsDeletions otherTyped =
        other as GetDueBillingTeamDeletionsDeletions;
    return teamId == otherTyped.teamId &&
        secretPaths == otherTyped.secretPaths &&
        githubPaths == otherTyped.githubPaths;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    secretPaths.hashCode,
    githubPaths.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['secretPaths'] = secretPaths.toJson();
    json['githubPaths'] = githubPaths.toJson();
    return json;
  }

  GetDueBillingTeamDeletionsDeletions({
    required this.teamId,
    required this.secretPaths,
    required this.githubPaths,
  });
}

@immutable
class GetDueBillingTeamDeletionsData {
  final List<GetDueBillingTeamDeletionsDeletions> deletions;
  GetDueBillingTeamDeletionsData.fromJson(dynamic json)
    : deletions = (json['deletions'] as List<dynamic>)
          .map((e) => GetDueBillingTeamDeletionsDeletions.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetDueBillingTeamDeletionsData otherTyped =
        other as GetDueBillingTeamDeletionsData;
    return deletions == otherTyped.deletions;
  }

  @override
  int get hashCode => deletions.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['deletions'] = deletions.map((e) => e.toJson()).toList();
    return json;
  }

  GetDueBillingTeamDeletionsData({
    required this.deletions,
  });
}
