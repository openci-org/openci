import 'package:dashboard/supabase/supabase_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:dashboard/workflow/mock_workflow_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'build_logs_provider.freezed.dart';
part 'build_logs_provider.g.dart';

@riverpod
Stream<List<BuildLog>> buildLogs(Ref ref, String buildJobId) {
  if (useMockData) {
    if (buildJobId == 'mock-build-2') {
      return Stream.value(getMockFailureBuildLogs());
    }
    return Stream.value(getMockBuildLogs());
  }

  final supabase = ref.read(supabaseClientProvider);

  return supabase
      .from('build_logs')
      .stream(primaryKey: ['id'])
      .eq('build_id', buildJobId)
      .order('created_at', ascending: true)
      .map((rows) {
        return rows.map((row) {
          return BuildLog(
            message: row['message'] as String,
            level: row['level'] as String,
            timestamp: row['created_at'] != null
                ? DateTime.parse(row['created_at'] as String)
                : null,
          );
        }).toList();
      });
}

@freezed
abstract class BuildLog with _$BuildLog {
  const factory BuildLog({
    required String message,
    required String level,
    @DateTimeConverter() DateTime? timestamp,
  }) = _BuildLog;

  factory BuildLog.fromJson(Map<String, Object?> json) =>
      _$BuildLogFromJson(json);
}
