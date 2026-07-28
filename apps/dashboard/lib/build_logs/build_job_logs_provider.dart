import 'dart:async';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'build_job_logs_provider.freezed.dart';
part 'build_job_logs_provider.g.dart';

@freezed
abstract class BuildJobLog with _$BuildJobLog {
  const factory BuildJobLog({
    required String message,
    required String level,
    @DateTimeConverter() DateTime? timestamp,
  }) = _BuildJobLog;

  factory BuildJobLog.fromJson(Map<String, Object?> json) =>
      _$BuildJobLogFromJson(json);
}

@riverpod
Future<List<BuildJobLog>> buildJobLogs(
  Ref ref,
  String buildJobId,
  String runId,
  BuildJobStatus buildStatus,
) async {
  final isRunning =
      buildStatus == BuildJobStatus.IN_PROGRESS ||
      buildStatus == BuildJobStatus.QUEUED ||
      buildStatus == BuildJobStatus.WAITING;

  if (isRunning) {
    final timer = Timer(const Duration(seconds: 2), () {
      ref.invalidateSelf();
    });
    ref.onDispose(() {
      timer.cancel();
    });
  }

  final apiService = ref.watch(openciApiServiceProvider);
  final response = await apiService.getAllBuildRunLogs(buildJobId, runId);

  if (!response.isSuccessful) {
    throw Exception('Failed to fetch logs: ${response.statusCode}');
  }

  final logLines = response.body;
  if (logLines == null || logLines.isEmpty) {
    return const [];
  }

  final logs = <BuildJobLog>[];

  for (final line in logLines) {
    if (line.isEmpty) continue;
    logs.add(
      BuildJobLog(
        message: line,
        level: 'info',
        timestamp: DateTime.now(),
      ),
    );
  }
  return logs;
}
