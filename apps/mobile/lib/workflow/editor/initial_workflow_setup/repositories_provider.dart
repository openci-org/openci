import 'package:dashboard/supabase/supabase_provider.dart';
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
  final team = ref.watch(teamStateProvider).requireValue;
  final supabase = ref.read(supabaseClientProvider);

  final result = await supabase.rpc(
    'list_repositories',
    params: {
      'p_org_id': team.id,
    },
  );

  final repos = (result as List<dynamic>)
      .map(
        (e) => GitHubRepository.fromJson(Map<String, Object?>.from(e as Map)),
      )
      .toList();

  return repos;
}
