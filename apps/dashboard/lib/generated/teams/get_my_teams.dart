part of 'teams.dart';

class GetMyTeamsVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  GetMyTeamsVariablesBuilder(
    this._dataConnect,
  );
  Deserializer<GetMyTeamsData> dataDeserializer = (dynamic json) =>
      GetMyTeamsData.fromJson(jsonDecode(json));

  Future<QueryResult<GetMyTeamsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetMyTeamsData, void> ref() {
    return _dataConnect.query(
      "GetMyTeams",
      dataDeserializer,
      emptySerializer,
      null,
    );
  }
}

@immutable
class GetMyTeamsTeams {
  final String id;
  final String name;
  final BigInt runNumber;
  final BigInt createdAt;
  final BigInt updatedAt;
  final List<GetMyTeamsTeamsMembers> members;
  GetMyTeamsTeams.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      name = nativeFromJson<String>(json['name']),
      runNumber = bigIntFromJson(json['runNumber']),
      createdAt = bigIntFromJson(json['createdAt']),
      updatedAt = bigIntFromJson(json['updatedAt']),
      members = (json['members'] as List<dynamic>)
          .map((e) => GetMyTeamsTeamsMembers.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyTeamsTeams otherTyped = other as GetMyTeamsTeams;
    return id == otherTyped.id &&
        name == otherTyped.name &&
        runNumber == otherTyped.runNumber &&
        createdAt == otherTyped.createdAt &&
        updatedAt == otherTyped.updatedAt &&
        members == otherTyped.members;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    name.hashCode,
    runNumber.hashCode,
    createdAt.hashCode,
    updatedAt.hashCode,
    members.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['runNumber'] = bigIntToJson(runNumber);
    json['createdAt'] = bigIntToJson(createdAt);
    json['updatedAt'] = bigIntToJson(updatedAt);
    json['members'] = members.map((e) => e.toJson()).toList();
    return json;
  }

  GetMyTeamsTeams({
    required this.id,
    required this.name,
    required this.runNumber,
    required this.createdAt,
    required this.updatedAt,
    required this.members,
  });
}

@immutable
class GetMyTeamsTeamsMembers {
  final String userId;
  GetMyTeamsTeamsMembers.fromJson(dynamic json)
    : userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyTeamsTeamsMembers otherTyped = other as GetMyTeamsTeamsMembers;
    return userId == otherTyped.userId;
  }

  @override
  int get hashCode => userId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  GetMyTeamsTeamsMembers({
    required this.userId,
  });
}

@immutable
class GetMyTeamsData {
  final List<GetMyTeamsTeams> teams;
  GetMyTeamsData.fromJson(dynamic json)
    : teams = (json['teams'] as List<dynamic>)
          .map((e) => GetMyTeamsTeams.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyTeamsData otherTyped = other as GetMyTeamsData;
    return teams == otherTyped.teams;
  }

  @override
  int get hashCode => teams.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teams'] = teams.map((e) => e.toJson()).toList();
    return json;
  }

  GetMyTeamsData({
    required this.teams,
  });
}
