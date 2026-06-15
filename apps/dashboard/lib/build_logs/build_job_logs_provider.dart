import 'dart:async';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/build_logs/build_logs_provider.dart';
import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'build_job_logs_provider.g.dart';

@riverpod
Future<List<BuildLog>> buildJobLogs(
  Ref ref,
  String buildJobId,
  String runId,
  BuildJobStatus buildStatus,
) async {
  const serverUrl = String.fromEnvironment('OPENCI_SERVER_URL');
  if (serverUrl.isEmpty) {
    throw UnimplementedError('OPENCI_SERVER_URL is not set');
  }

  final url = Uri.parse('$serverUrl/builds/$buildJobId/runs/$runId/logs');

  final token = await ref.watch(firebaseIdTokenProvider.future);
  if (token == null) {
    throw Exception('Unauthorized: No user is currently signed in');
  }

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
    throw Exception('No logs found for build job $buildJobId and run $runId');
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
