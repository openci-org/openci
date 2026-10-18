import 'package:freezed_annotation/freezed_annotation.dart';

part 'github_connection_result.freezed.dart';
part 'github_connection_result.g.dart';

@freezed
abstract class GitHubConnectionSessionResult
    with _$GitHubConnectionSessionResult {
  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true)
  const factory GitHubConnectionSessionResult({
    required bool success,
    required GitHubConnectionSession session,
  }) = _GitHubConnectionSessionResult;

  factory GitHubConnectionSessionResult.fromJson(Map<String, dynamic> json) =>
      _$GitHubConnectionSessionResultFromJson(json);
}

@freezed
abstract class GitHubConnectionSession with _$GitHubConnectionSession {
  const factory GitHubConnectionSession({
    required String teamId,
    required int githubUserId,
    required DateTime expiresAt,
  }) = _GitHubConnectionSession;

  factory GitHubConnectionSession.fromJson(Map<String, dynamic> json) =>
      _$GitHubConnectionSessionFromJson(json);
}

@freezed
abstract class GitHubConnectionCandidatesResult
    with _$GitHubConnectionCandidatesResult {
  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory GitHubConnectionCandidatesResult({
    required bool success,
    required List<GitHubConnectionCandidate> candidates,
    String? installationUrl,
  }) = _GitHubConnectionCandidatesResult;

  factory GitHubConnectionCandidatesResult.fromJson(
    Map<String, dynamic> json,
  ) => _$GitHubConnectionCandidatesResultFromJson(json);
}

@freezed
abstract class GitHubConnectionCandidate with _$GitHubConnectionCandidate {
  const factory GitHubConnectionCandidate({
    required int installationId,
    required String accountLogin,
    required String accountType,
  }) = _GitHubConnectionCandidate;

  factory GitHubConnectionCandidate.fromJson(Map<String, dynamic> json) =>
      _$GitHubConnectionCandidateFromJson(json);
}

@freezed
abstract class GitHubConnectionConfirmationResult
    with _$GitHubConnectionConfirmationResult {
  const factory GitHubConnectionConfirmationResult({required bool success}) =
      _GitHubConnectionConfirmationResult;

  factory GitHubConnectionConfirmationResult.fromJson(
    Map<String, dynamic> json,
  ) => _$GitHubConnectionConfirmationResultFromJson(json);
}
