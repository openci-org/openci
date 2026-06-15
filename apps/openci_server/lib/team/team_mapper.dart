import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';

extension DriftTeamMapper on DriftTeam {
  Team toShared({required List<String> members}) {
    return Team(
      id: id,
      name: name,
      members: members,
      createdAt: createdAt,
      updatedAt: updatedAt,
      githubBaseUrl: githubBaseUrl,
      githubApiBaseUrl: githubApiBaseUrl,
      installationIds: installationIds,
      aiEnabled: aiEnabled,
      runNumber: runNumber,
    );
  }
}

extension TeamMapper on Team {
  DriftTeam toDrift() {
    return DriftTeam(
      id: id,
      name: name,
      githubBaseUrl: githubBaseUrl,
      githubApiBaseUrl: githubApiBaseUrl,
      installationIds: installationIds,
      aiEnabled: aiEnabled,
      runNumber: runNumber,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
