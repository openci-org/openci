import 'package:firebase_functions/firebase_functions.dart';

class TeamRequest {
  const TeamRequest({required this.teamId});

  factory TeamRequest.fromJson(Map<String, dynamic> json) {
    final teamId = json['teamId'] as String?;
    if (teamId == null || teamId.isEmpty) {
      throw InvalidArgumentError('Missing teamId');
    }
    return TeamRequest(teamId: teamId);
  }

  final String teamId;
}

class ListBuildsRequest {
  const ListBuildsRequest({required this.teamId, required this.appId});

  factory ListBuildsRequest.fromJson(Map<String, dynamic> json) {
    final teamId = json['teamId'] as String?;
    final appId = json['appId'] as String?;
    if (teamId == null || teamId.isEmpty || appId == null || appId.isEmpty) {
      throw InvalidArgumentError('Missing required fields');
    }
    return ListBuildsRequest(teamId: teamId, appId: appId);
  }

  final String teamId;
  final String appId;
}

class SubmitToTestFlightRequest {
  const SubmitToTestFlightRequest({
    required this.teamId,
    required this.buildId,
  });

  factory SubmitToTestFlightRequest.fromJson(Map<String, dynamic> json) {
    final teamId = json['teamId'] as String?;
    final buildId = json['buildId'] as String?;
    if (teamId == null ||
        teamId.isEmpty ||
        buildId == null ||
        buildId.isEmpty) {
      throw InvalidArgumentError('Missing required fields');
    }
    return SubmitToTestFlightRequest(teamId: teamId, buildId: buildId);
  }

  final String teamId;
  final String buildId;
}

class SubmitForReviewRequest {
  const SubmitForReviewRequest({
    required this.teamId,
    required this.appId,
    required this.buildId,
    required this.versionString,
    required this.whatsNew,
    this.platform = 'IOS',
  });

  factory SubmitForReviewRequest.fromJson(Map<String, dynamic> json) {
    final teamId = json['teamId'] as String?;
    final appId = json['appId'] as String?;
    final buildId = json['buildId'] as String?;
    final versionString = json['versionString'] as String?;
    final whatsNew = json['whatsNew'] as String?;
    final platform = (json['platform'] as String?) ?? 'IOS';

    if (teamId == null ||
        teamId.isEmpty ||
        appId == null ||
        appId.isEmpty ||
        buildId == null ||
        buildId.isEmpty ||
        versionString == null ||
        versionString.isEmpty ||
        whatsNew == null ||
        whatsNew.isEmpty) {
      throw InvalidArgumentError('Missing required fields');
    }

    return SubmitForReviewRequest(
      teamId: teamId,
      appId: appId,
      buildId: buildId,
      versionString: versionString,
      whatsNew: whatsNew,
      platform: platform,
    );
  }

  final String teamId;
  final String appId;
  final String buildId;
  final String versionString;
  final String whatsNew;
  final String platform;
}
