import 'package:freezed_annotation/freezed_annotation.dart';

part 'github_connection_context.freezed.dart';
part 'github_connection_context.g.dart';

@freezed
abstract class GitHubConnectionContext with _$GitHubConnectionContext {
  const factory GitHubConnectionContext({
    required String profileId,
    required String apiUrl,
    required String userId,
    required String teamId,
  }) = _GitHubConnectionContext;

  factory GitHubConnectionContext.fromJson(Map<String, dynamic> json) =>
      _$GitHubConnectionContextFromJson(json);
}
