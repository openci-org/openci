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

  throw UnimplementedError(
    'TODO: Migrate to Firebase Data Connect',
  );
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
