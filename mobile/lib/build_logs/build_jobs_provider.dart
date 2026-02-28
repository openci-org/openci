import 'package:dashboard/supabase/supabase_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:dashboard/workflow/mock_workflow_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'build_jobs_provider.freezed.dart';
part 'build_jobs_provider.g.dart';

@riverpod
class BuildJobs extends _$BuildJobs {
  @override
  Stream<List<BuildJob>> build() {
    if (useMockData) {
      return Stream.value(getMockBuildJobs());
    }

    final supabase = ref.watch(supabaseClientProvider);

    return supabase
        .from('builds')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(20)
        .map((rows) {
          return rows
              .where((r) {
                final projectId = r['team_id'] as String?;
                return projectId != null;
              })
              .map((row) => BuildJob.fromSupabase(row))
              .toList();
        });
  }

  Future<void> retryBuildJob(String buildJobId) async {
    if (useMockData) return;
    throw UnimplementedError('retry_build RPC is not yet implemented');
  }

  Future<void> cancelBuildJob(String buildJobId) async {
    if (useMockData) return;
    final supabase = ref.read(supabaseClientProvider);
    await supabase
        .from('builds')
        .update({'status': 'cancelled'})
        .eq('id', buildJobId);
  }
}

@freezed
abstract class BuildJob with _$BuildJob {
  const factory BuildJob({
    required String id,
    required String status,
    required String owner,
    required String repo,
    String? teamId,
    String? commitSha,
    int? pullRequestNumber,
    String? tagName,
    String? branch,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
  }) = _BuildJob;

  factory BuildJob.fromJson(Map<String, Object?> json) =>
      _$BuildJobFromJson(json);

  factory BuildJob.fromSupabase(Map<String, dynamic> row) {
    return BuildJob(
      id: row['id'] as String,
      status: row['status'] as String,
      owner: row['github_owner'] as String? ?? '',
      repo: row['github_repo'] as String? ?? '',
      teamId: row['team_id'] as String?,
      commitSha: row['commit_sha'] as String?,
      pullRequestNumber: row['pull_request_number'] as int?,
      tagName: row['tag_name'] as String?,
      branch: row['branch'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
