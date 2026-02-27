import 'package:dashboard/workflow/mock_workflow_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'git_context_provider.freezed.dart';
part 'git_context_provider.g.dart';

@freezed
abstract class GitContextState with _$GitContextState {
  const factory GitContextState({
    required String repository,
    required String branch,
    String? commitSha,
    String? commitMessage,
  }) = _GitContextState;
}

@freezed
abstract class GitBranch with _$GitBranch {
  const factory GitBranch({
    required String name,
    @Default(false) bool isDefault,
  }) = _GitBranch;
}

@freezed
abstract class GitCommit with _$GitCommit {
  const factory GitCommit({
    required String sha,
    required String message,
    required String author,
    required DateTime date,
  }) = _GitCommit;
}

@riverpod
class GitContext extends _$GitContext {
  @override
  GitContextState build() {
    return const GitContextState(
      repository: 'open-ci-io/openci',
      branch: 'main',
      commitSha: 'a1b2c3d4e5f6',
      commitMessage: 'feat: add workflow editor',
    );
  }

  void switchBranch(String branch, {String? commitSha, String? commitMessage}) {
    state = state.copyWith(
      branch: branch,
      commitSha: commitSha,
      commitMessage: commitMessage,
    );
  }

  void switchCommit(String sha, String message) {
    state = state.copyWith(
      commitSha: sha,
      commitMessage: message,
    );
  }
}

@riverpod
Future<List<GitBranch>> gitBranches(Ref ref) async {
  if (useMockData) {
    return const [
      GitBranch(name: 'main', isDefault: true),
      GitBranch(name: 'develop'),
      GitBranch(name: 'feature/workflow-editor'),
      GitBranch(name: 'feature/action-search'),
      GitBranch(name: 'fix/build-timeout'),
      GitBranch(name: 'release/v1.0'),
    ];
  }
  return [];
}

@riverpod
Future<List<GitCommit>> gitCommits(Ref ref, String branch) async {
  if (useMockData) {
    final now = DateTime.now();
    final commits = <String, List<GitCommit>>{
      'main': [
        GitCommit(
          sha: 'a1b2c3d4e5f6',
          message: 'feat: add workflow editor',
          author: 'masahiro',
          date: now.subtract(const Duration(hours: 2)),
        ),
        GitCommit(
          sha: 'b2c3d4e5f6a1',
          message: 'fix: build status badge color',
          author: 'masahiro',
          date: now.subtract(const Duration(hours: 5)),
        ),
        GitCommit(
          sha: 'c3d4e5f6a1b2',
          message: 'chore: update dependencies',
          author: 'masahiro',
          date: now.subtract(const Duration(days: 1)),
        ),
        GitCommit(
          sha: 'd4e5f6a1b2c3',
          message: 'feat: add trigger configuration',
          author: 'masahiro',
          date: now.subtract(const Duration(days: 1, hours: 3)),
        ),
        GitCommit(
          sha: 'e5f6a1b2c3d4',
          message: 'refactor: extract yaml converter',
          author: 'masahiro',
          date: now.subtract(const Duration(days: 2)),
        ),
      ],
      'develop': [
        GitCommit(
          sha: 'f4e5d6c7b8a9',
          message: 'feat: action search sheet',
          author: 'masahiro',
          date: now.subtract(const Duration(minutes: 30)),
        ),
        GitCommit(
          sha: 'g5f6e7d8c9b0',
          message: 'feat: uses step support',
          author: 'masahiro',
          date: now.subtract(const Duration(hours: 1)),
        ),
        GitCommit(
          sha: 'h6g7f8e9d0c1',
          message: 'wip: save dialog options',
          author: 'masahiro',
          date: now.subtract(const Duration(hours: 3)),
        ),
      ],
      'feature/workflow-editor': [
        GitCommit(
          sha: '1a2b3c4d5e6f',
          message: 'feat: visual editor tab',
          author: 'masahiro',
          date: now.subtract(const Duration(hours: 6)),
        ),
        GitCommit(
          sha: '2b3c4d5e6f7a',
          message: 'feat: yaml editor tab',
          author: 'masahiro',
          date: now.subtract(const Duration(hours: 8)),
        ),
      ],
    };
    return commits[branch] ?? commits['main']!;
  }
  return [];
}
