// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_connection_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GitHubConnectionSessionResult _$GitHubConnectionSessionResultFromJson(
  Map<String, dynamic> json,
) => GitHubConnectionSessionResult(
  success: json['success'] as bool,
  session: GitHubConnectionSession.fromJson(
    json['session'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$GitHubConnectionSessionResultToJson(
  GitHubConnectionSessionResult instance,
) => <String, dynamic>{
  'success': instance.success,
  'session': instance.session.toJson(),
};

GitHubConnectionSession _$GitHubConnectionSessionFromJson(
  Map<String, dynamic> json,
) => GitHubConnectionSession(
  teamId: json['teamId'] as String,
  githubUserId: (json['githubUserId'] as num).toInt(),
  expiresAt: DateTime.parse(json['expiresAt'] as String),
);

Map<String, dynamic> _$GitHubConnectionSessionToJson(
  GitHubConnectionSession instance,
) => <String, dynamic>{
  'teamId': instance.teamId,
  'githubUserId': instance.githubUserId,
  'expiresAt': instance.expiresAt.toIso8601String(),
};

GitHubConnectionCandidatesResult _$GitHubConnectionCandidatesResultFromJson(
  Map<String, dynamic> json,
) => GitHubConnectionCandidatesResult(
  success: json['success'] as bool,
  candidates: (json['candidates'] as List<dynamic>)
      .map((e) => GitHubConnectionCandidate.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GitHubConnectionCandidatesResultToJson(
  GitHubConnectionCandidatesResult instance,
) => <String, dynamic>{
  'success': instance.success,
  'candidates': instance.candidates.map((e) => e.toJson()).toList(),
};

GitHubConnectionCandidate _$GitHubConnectionCandidateFromJson(
  Map<String, dynamic> json,
) => GitHubConnectionCandidate(
  installationId: (json['installationId'] as num).toInt(),
  accountLogin: json['accountLogin'] as String,
  accountType: json['accountType'] as String,
);

Map<String, dynamic> _$GitHubConnectionCandidateToJson(
  GitHubConnectionCandidate instance,
) => <String, dynamic>{
  'installationId': instance.installationId,
  'accountLogin': instance.accountLogin,
  'accountType': instance.accountType,
};

GitHubConnectionConfirmationResult _$GitHubConnectionConfirmationResultFromJson(
  Map<String, dynamic> json,
) => GitHubConnectionConfirmationResult(success: json['success'] as bool);

Map<String, dynamic> _$GitHubConnectionConfirmationResultToJson(
  GitHubConnectionConfirmationResult instance,
) => <String, dynamic>{'success': instance.success};
