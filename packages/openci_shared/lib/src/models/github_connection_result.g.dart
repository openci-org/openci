// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_connection_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GitHubConnectionSessionResult _$GitHubConnectionSessionResultFromJson(
  Map<String, dynamic> json,
) => _GitHubConnectionSessionResult(
  success: json['success'] as bool,
  session: GitHubConnectionSession.fromJson(
    json['session'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$GitHubConnectionSessionResultToJson(
  _GitHubConnectionSessionResult instance,
) => <String, dynamic>{
  'success': instance.success,
  'session': instance.session.toJson(),
};

_GitHubConnectionSession _$GitHubConnectionSessionFromJson(
  Map<String, dynamic> json,
) => _GitHubConnectionSession(
  teamId: json['teamId'] as String,
  githubUserId: (json['githubUserId'] as num).toInt(),
  expiresAt: DateTime.parse(json['expiresAt'] as String),
);

Map<String, dynamic> _$GitHubConnectionSessionToJson(
  _GitHubConnectionSession instance,
) => <String, dynamic>{
  'teamId': instance.teamId,
  'githubUserId': instance.githubUserId,
  'expiresAt': instance.expiresAt.toIso8601String(),
};

_GitHubConnectionCandidatesResult _$GitHubConnectionCandidatesResultFromJson(
  Map<String, dynamic> json,
) => _GitHubConnectionCandidatesResult(
  success: json['success'] as bool,
  candidates: (json['candidates'] as List<dynamic>)
      .map((e) => GitHubConnectionCandidate.fromJson(e as Map<String, dynamic>))
      .toList(),
  installationUrl: json['installationUrl'] as String?,
);

Map<String, dynamic> _$GitHubConnectionCandidatesResultToJson(
  _GitHubConnectionCandidatesResult instance,
) => <String, dynamic>{
  'success': instance.success,
  'candidates': instance.candidates.map((e) => e.toJson()).toList(),
  'installationUrl': ?instance.installationUrl,
};

_GitHubConnectionCandidate _$GitHubConnectionCandidateFromJson(
  Map<String, dynamic> json,
) => _GitHubConnectionCandidate(
  installationId: (json['installationId'] as num).toInt(),
  accountLogin: json['accountLogin'] as String,
  accountType: json['accountType'] as String,
);

Map<String, dynamic> _$GitHubConnectionCandidateToJson(
  _GitHubConnectionCandidate instance,
) => <String, dynamic>{
  'installationId': instance.installationId,
  'accountLogin': instance.accountLogin,
  'accountType': instance.accountType,
};

_GitHubConnectionConfirmationResult
_$GitHubConnectionConfirmationResultFromJson(Map<String, dynamic> json) =>
    _GitHubConnectionConfirmationResult(success: json['success'] as bool);

Map<String, dynamic> _$GitHubConnectionConfirmationResultToJson(
  _GitHubConnectionConfirmationResult instance,
) => <String, dynamic>{'success': instance.success};
