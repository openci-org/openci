import 'dart:async';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/openci_server_url_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'build_job_logs_provider.freezed.dart';
part 'build_job_logs_provider.g.dart';

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

@riverpod
Future<List<BuildLog>> buildJobLogs(
  Ref ref,
  String buildJobId,
  String runId,
  BuildJobStatus buildStatus,
) async {
  final serverUrl = ref.watch(openciServerUrlProvider);

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

  final url = Uri.parse('$serverUrl/builds/$buildJobId/runs/$runId/logs');

  final token = await ref.watch(authedFirebaseIdTokenProvider.future);

  final response = await http
      .get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      )
      .timeout(const Duration(seconds: 10));

  if (response.statusCode != 200) {
    throw Exception('Failed to fetch logs: ${response.statusCode}');
  }

  if (response.body.isEmpty) {
    return const [];
  }

  final logs = <BuildLog>[];
  final logText = response.body;

  final lines = logText.split('\n');
  for (final line in lines) {
    if (line.isEmpty) continue;
    logs.add(
      BuildLog(
        message: line,
        level: 'info',
        timestamp: DateTime.now(),
      ),
    );
  }
  return logs;
}
