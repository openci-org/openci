import 'dart:async';
import 'dart:convert';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/api/ws_uri_builder.dart';
import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'build_step_providers.g.dart';

@riverpod
Future<List<BuildStep>> buildStepSummaries(
  Ref ref, {
  required String buildJobId,
  required String runId,
}) async {
  final api = ref.watch(openciApiServiceProvider);
  if (runId.isEmpty) {
    return const [];
  }

  final response = await api.getBuildSteps(buildJobId, runId);
  if (!response.isSuccessful || response.body == null) {
    throw Exception('Failed to load build steps: ${response.error}');
  }
  return response.body!;
}

@riverpod
Future<List<String>> buildStepLogDetail(
  Ref ref, {
  required String buildJobId,
  required String runId,
  required String stepId,
}) async {
  final api = ref.watch(openciApiServiceProvider);
  final response = await api.getBuildStepLogs(buildJobId, runId, stepId);
  if (!response.isSuccessful || response.body == null) {
    throw Exception('Failed to load step logs: ${response.error}');
  }
  return response.body!;
}

@riverpod
Future<String> allBuildStepLogs(
  Ref ref, {
  required String buildJobId,
  required String runId,
}) async {
  if (runId.isEmpty) return '';
  final api = ref.watch(openciApiServiceProvider);
  final response = await api.getAllBuildRunLogs(buildJobId, runId);
  if (!response.isSuccessful || response.body == null) {
    throw Exception('Failed to load all logs: ${response.error}');
  }
  return response.body!.join('\n');
}

@riverpod
Stream<Map<String, dynamic>> realtimeRunLogsStream(
  Ref ref, {
  required String buildJobId,
  required String runId,
}) async* {
  if (runId.isEmpty) return;

  final wsUri = await buildWebSocketUri(
    ref,
    '/builds/$buildJobId/runs/$runId/stream',
  );

  WebSocketChannel? channel;

  try {
    channel = WebSocketChannel.connect(wsUri);
    await for (final rawMessage in channel.stream) {
      try {
        final messageStr = rawMessage.toString();
        final json = jsonDecode(messageStr) as Map<String, dynamic>;
        yield json;
      } catch (_) {}
    }
  } catch (e) {
    // WebSocket エラー時は静かにクローズ
  } finally {
    try {
      await channel?.sink.close();
    } catch (_) {}
  }
}
