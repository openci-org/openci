import 'dart:async';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
