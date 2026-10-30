library teams;

import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'get_team_members.dart';

part 'add_team_member.dart';

part 'remove_team_member.dart';

part 'create_team.dart';

part 'rename_team.dart';

part 'get_my_teams.dart';

String? bigIntToJson(BigInt? value) {
  return value?.toString();
}

BigInt bigIntFromJson(dynamic value) {
  return BigInt.parse(value);
}

class TeamsConnector {
  GetTeamMembersVariablesBuilder getTeamMembers({
    required String teamId,
  }) {
    return GetTeamMembersVariablesBuilder(
      dataConnect,
      teamId: teamId,
    );
  }

  AddTeamMemberVariablesBuilder addTeamMember({
    required String teamId,
    required String actorUid,
    required String userId,
  }) {
    return AddTeamMemberVariablesBuilder(
      dataConnect,
      teamId: teamId,
      actorUid: actorUid,
      userId: userId,
    );
  }

  RemoveTeamMemberVariablesBuilder removeTeamMember({
    required String teamId,
    required String userId,
  }) {
    return RemoveTeamMemberVariablesBuilder(
      dataConnect,
      teamId: teamId,
      userId: userId,
    );
  }

  CreateTeamVariablesBuilder createTeam({
    required String id,
    required String name,
  }) {
    return CreateTeamVariablesBuilder(
      dataConnect,
      id: id,
      name: name,
    );
  }

  RenameTeamVariablesBuilder renameTeam({
    required String teamId,
    required String name,
  }) {
    return RenameTeamVariablesBuilder(
      dataConnect,
      teamId: teamId,
      name: name,
    );
  }

  GetMyTeamsVariablesBuilder getMyTeams() {
    return GetMyTeamsVariablesBuilder(
      dataConnect,
    );
  }

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'asia-northeast1',
    'teams',
    'openci-b1b91-service',
  );

  TeamsConnector({required this.dataConnect});
  static TeamsConnector get instance {
    return TeamsConnector(
      dataConnect: FirebaseDataConnect.instanceFor(
        connectorConfig: connectorConfig,

        sdkType: CallerSDKType.generated,
      ),
    );
  }

  FirebaseDataConnect dataConnect;
}
