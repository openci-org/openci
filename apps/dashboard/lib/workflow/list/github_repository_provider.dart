import 'package:dashboard/firebase/dart_function_urls.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'github_repository_provider.freezed.dart';
part 'github_repository_provider.g.dart';

@freezed
abstract class GitHubRepo with _$GitHubRepo {
  const factory GitHubRepo({
    required String fullName,
    required String name,
    required String owner,
    required bool private,
    required String defaultBranch,
  }) = _GitHubRepo;

  factory GitHubRepo.fromJson(Map<String, Object?> json) =>
      _$GitHubRepoFromJson(json);
}

@riverpod
Future<List<GitHubRepo>> gitHubRepositories(Ref ref) async {
  final team = ref.watch(teamStateProvider).value;
  if (team == null) return [];
  final functions = FirebaseFunctions.instance;

  final result = await functions
      .httpsCallableFromUrl(dartFunctionUrl('listrepositories'))
      .call({
    'teamId': team.id,
  });

  final data = result.data as Map<String, dynamic>;
  final repos = (data['repositories'] as List<dynamic>)
      .map(
        (e) => GitHubRepo.fromJson(Map<String, Object?>.from(e as Map)),
      )
      .toList();

  return repos;
}

@riverpod
Future<List<String>> gitHubBranches(Ref ref, String repoFullName) async {
  final team = ref.watch(teamStateProvider).value;
  if (team == null) return [];
  final functions = FirebaseFunctions.instance;

  final result = await functions
      .httpsCallableFromUrl(dartFunctionUrl('listbranches'))
      .call({
    'teamId': team.id,
    'repository': repoFullName,
  });

  final data = result.data as Map<String, dynamic>;
  final branches = (data['branches'] as List<dynamic>)
      .map((e) => e.toString())
      .toList();

  return branches;
}
