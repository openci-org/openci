import 'package:json_annotation/json_annotation.dart';

part 'github_connection_result.g.dart';

@JsonSerializable(explicitToJson: true)
class GitHubConnectionSessionResult {
  const GitHubConnectionSessionResult({
    required this.success,
    required this.session,
  });

  factory GitHubConnectionSessionResult.fromJson(Map<String, dynamic> json) =>
      _$GitHubConnectionSessionResultFromJson(json);

  final bool success;
  final GitHubConnectionSession session;

  Map<String, dynamic> toJson() => _$GitHubConnectionSessionResultToJson(this);
}

@JsonSerializable()
class GitHubConnectionSession {
  const GitHubConnectionSession({
    required this.teamId,
    required this.githubUserId,
    required this.expiresAt,
  });

  factory GitHubConnectionSession.fromJson(Map<String, dynamic> json) =>
      _$GitHubConnectionSessionFromJson(json);

  final String teamId;
  final int githubUserId;
  final DateTime expiresAt;

  Map<String, dynamic> toJson() => _$GitHubConnectionSessionToJson(this);
}

@JsonSerializable(explicitToJson: true)
class GitHubConnectionCandidatesResult {
  const GitHubConnectionCandidatesResult({
    required this.success,
    required this.candidates,
  });

  factory GitHubConnectionCandidatesResult.fromJson(
    Map<String, dynamic> json,
  ) => _$GitHubConnectionCandidatesResultFromJson(json);

  final bool success;
  final List<GitHubConnectionCandidate> candidates;

  Map<String, dynamic> toJson() =>
      _$GitHubConnectionCandidatesResultToJson(this);
}

@JsonSerializable()
class GitHubConnectionCandidate {
  const GitHubConnectionCandidate({
    required this.installationId,
    required this.accountLogin,
    required this.accountType,
  });

  factory GitHubConnectionCandidate.fromJson(Map<String, dynamic> json) =>
      _$GitHubConnectionCandidateFromJson(json);

  final int installationId;
  final String accountLogin;
  final String accountType;

  Map<String, dynamic> toJson() => _$GitHubConnectionCandidateToJson(this);
}
