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
  ref.watch(teamStateProvider).requireValue;

  throw UnimplementedError(
    'TODO: Migrate to Firebase Data Connect',
  );
}
