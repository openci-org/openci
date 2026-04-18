import 'package:dashboard/firebase/dart_function_urls.dart';
import 'package:dashboard/firebase/functions_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repositories_provider.freezed.dart';
part 'repositories_provider.g.dart';

@freezed
abstract class GitHubRepository with _$GitHubRepository {
  const factory GitHubRepository({
    required String fullName,
    required String name,
    required String owner,
    required bool private,
    required String defaultBranch,
  }) = _GitHubRepository;

  factory GitHubRepository.fromJson(Map<String, Object?> json) =>
      _$GitHubRepositoryFromJson(json);
}

@riverpod
Future<List<GitHubRepository>> repositories(Ref ref) async {
  final team = ref.watch(teamStateProvider).value;
  if (team == null) return [];
  final functions = ref.watch(functionsProvider);

  final result = await functions
      .httpsCallableFromUrl(dartFunctionUrl('list-repositories'))
      .call({
    'teamId': team.id,
  });

  final data = result.data as Map<String, dynamic>;
  final repos = (data['repositories'] as List<dynamic>)
      .map(
        (e) => GitHubRepository.fromJson(Map<String, Object?>.from(e as Map)),
      )
      .toList();

  return repos;
}
