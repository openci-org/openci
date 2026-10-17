class GitHubConnectionContext {
  const GitHubConnectionContext({
    required this.profileId,
    required this.apiUrl,
    required this.userId,
    required this.teamId,
  });

  final String profileId;
  final String apiUrl;
  final String userId;
  final String teamId;

  bool matches(GitHubConnectionContext? other) =>
      other != null &&
      profileId == other.profileId &&
      apiUrl == other.apiUrl &&
      userId == other.userId &&
      teamId == other.teamId;
}
