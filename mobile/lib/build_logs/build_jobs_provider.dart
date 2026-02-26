import 'package:dashboard/supabase/supabase_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'build_jobs_provider.freezed.dart';
part 'build_jobs_provider.g.dart';

@riverpod
class BuildJobs extends _$BuildJobs {
  @override
  Stream<List<BuildJob>> build() {
    final supabase = ref.watch(supabaseClientProvider);

    return supabase
        .from('builds')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(20)
        .map((rows) {
          return rows
              .where((r) {
                final projectId = r['org_id'] as String?;
                return projectId != null;
              })
              .map((row) => BuildJob.fromSupabase(row))
              .toList();
        });
  }

  Future<void> retryBuildJob(String buildJobId) async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase.rpc('retry_build', params: {'p_build_id': buildJobId});
  }

  Future<void> cancelBuildJob(String buildJobId) async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase
        .from('builds')
        .update({'status': 'cancelled'})
        .eq('id', buildJobId);
  }
}

@riverpod
Future<String?> workflowName(Ref ref, String? workflowId) async {
  if (workflowId == null) return null;
  final supabase = ref.read(supabaseClientProvider);
  final rows = await supabase
      .from('workflows')
      .select('name')
      .eq('id', workflowId)
      .limit(1);
  if (rows.isEmpty) return null;
  return rows.first['name'] as String?;
}

@freezed
abstract class BuildJob with _$BuildJob {
  const factory BuildJob({
    required String id,
    required String status,
    required String owner,
    required String repo,
    String? teamId,
    String? workflowId,
    String? commitSha,
    int? pullRequestNumber,
    int? runCount,
    String? latestRunId,
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
      teamId: row['org_id'] as String?,
      workflowId: row['workflow_id'] as String?,
      commitSha: row['commit_sha'] as String?,
      pullRequestNumber: row['pull_request_number'] as int?,
      runCount: row['run_count'] as int?,
      latestRunId: row['latest_run_id'] as String?,
      tagName: row['tag_name'] as String?,
      branch: row['branch'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
